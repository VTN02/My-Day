'use client';

import React, { useEffect, useState } from 'react';
import {
  FileText,
  Search,
  Eye,
  Shield,
  Download,
  Calendar,
  Lock,
  RefreshCw,
} from 'lucide-react';
import { Card, CardHeader, CardTitle, CardDescription } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Badge } from '@/components/ui/badge';
import { Modal } from '@/components/ui/modal';
import {
  TableWrapper,
  TableHeader,
  TableBody,
  TableRow,
  TableHead,
  TableCell,
} from '@/components/ui/table';

interface AuditLogRecord {
  id: string;
  actorEmail: string;
  action: string;
  targetType: string;
  targetId: string;
  timestamp: string;
  result: 'success' | 'failure';
  ipAddress: string;
  metadata: Record<string, any>;
}

export default function AuditLogsPage() {
  const [logs, setLogs] = useState<AuditLogRecord[]>([]);
  const [total, setTotal] = useState(0);
  const [isLoading, setIsLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedLog, setSelectedLog] = useState<AuditLogRecord | null>(null);

  const fetchLogs = async () => {
    setIsLoading(true);
    try {
      const params = new URLSearchParams({
        q: searchQuery,
        limit: '100',
      });
      const res = await fetch(`/api/audit-logs?${params.toString()}`, { cache: 'no-store' });
      const json = await res.json();
      if (res.ok && json.logs) {
        setLogs(json.logs);
        setTotal(json.total || 0);
      } else {
        setLogs([]);
        setTotal(0);
      }
    } catch (e) {
      setLogs([]);
      setTotal(0);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchLogs();
  }, [searchQuery]);

  const handleExportCsv = () => {
    window.open('/api/audit-logs?format=csv', '_blank');
  };

  return (
    <div className="space-y-6">
      {/* Header & Controls */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl sm:text-3xl font-bold text-slate-800 tracking-tight">
            Audit Logs
          </h1>
          <p className="text-xs sm:text-sm text-slate-500 mt-1">
            Immutable administrative event trail recorded in PostgreSQL ({total} events logged).
          </p>
        </div>

        <div className="flex items-center gap-2.5">
          <Button
            variant="outline"
            size="sm"
            onClick={fetchLogs}
            isLoading={isLoading}
            className="rounded-xl"
          >
            <RefreshCw className="w-4 h-4 text-slate-500" />
            <span>Refresh</span>
          </Button>

          <Button
            variant="outline"
            size="sm"
            onClick={handleExportCsv}
            disabled={logs.length === 0}
            className="rounded-xl"
          >
            <Download className="w-4 h-4 text-slate-500" />
            <span>Export Audit Log (CSV)</span>
          </Button>
        </div>
      </div>

      {/* Immutability Banner */}
      <div className="bg-slate-100/80 border border-slate-200 rounded-2xl p-4 flex items-start gap-3">
        <Lock className="w-5 h-5 text-slate-600 shrink-0 mt-0.5" />
        <div className="text-xs text-slate-700 leading-relaxed">
          <strong className="font-semibold text-slate-900">Cryptographic Append-Only Guarantee:</strong>{' '}
          Audit records are permanently preserved in PostgreSQL. Database triggers prevent update or delete operations by any user or administrator.
        </div>
      </div>

      {/* Main Table Card */}
      <Card>
        <div className="mb-6 flex flex-col sm:flex-row items-stretch sm:items-center justify-between gap-3">
          <div className="w-full sm:w-80">
            <Input
              placeholder="Search by action, actor, or ID..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              icon={<Search className="w-4 h-4" />}
            />
          </div>
        </div>

        <TableWrapper>
          <TableHeader>
            <TableRow>
              <TableHead>Event ID</TableHead>
              <TableHead>Actor</TableHead>
              <TableHead>Action</TableHead>
              <TableHead>Target</TableHead>
              <TableHead>Timestamp</TableHead>
              <TableHead>Outcome</TableHead>
              <TableHead className="text-right">Details</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {isLoading ? (
              <TableRow>
                <TableCell colSpan={7} className="text-center py-10 text-xs text-slate-400">
                  <RefreshCw className="w-5 h-5 animate-spin mx-auto mb-2 text-blue-600" />
                  Loading audit logs from database...
                </TableCell>
              </TableRow>
            ) : logs.length > 0 ? (
              logs.map((log) => (
                <TableRow key={log.id}>
                  <TableCell className="font-mono text-[11px] text-slate-400">
                    {log.id.slice(0, 12)}...
                  </TableCell>
                  <TableCell className="text-xs font-semibold text-slate-800">
                    {log.actorEmail}
                  </TableCell>
                  <TableCell>
                    <span className="font-mono text-xs font-medium text-blue-700 bg-blue-50 px-2 py-0.5 rounded-md">
                      {log.action}
                    </span>
                  </TableCell>
                  <TableCell className="text-xs text-slate-600">
                    <span className="text-slate-400 mr-1">{log.targetType}:</span>
                    <span className="font-medium text-slate-700">{log.targetId}</span>
                  </TableCell>
                  <TableCell className="text-xs text-slate-500">
                    {log.timestamp}
                  </TableCell>
                  <TableCell>
                    <Badge variant={log.result === 'success' ? 'success' : 'error'} size="sm">
                      {log.result}
                    </Badge>
                  </TableCell>
                  <TableCell className="text-right">
                    <Button
                      variant="ghost"
                      size="sm"
                      onClick={() => setSelectedLog(log)}
                      className="rounded-lg text-slate-500 hover:text-blue-600"
                    >
                      <Eye className="w-3.5 h-3.5" />
                    </Button>
                  </TableCell>
                </TableRow>
              ))
            ) : (
              <TableRow>
                <TableCell colSpan={7} className="text-center py-12 text-xs text-slate-400">
                  <FileText className="w-8 h-8 text-slate-300 mx-auto mb-2" />
                  No administrative audit records found.
                </TableCell>
              </TableRow>
            )}
          </TableBody>
        </TableWrapper>
      </Card>

      {/* Audit Log Detail Modal */}
      {selectedLog && (
        <Modal
          isOpen={Boolean(selectedLog)}
          onClose={() => setSelectedLog(null)}
          title="Administrative Audit Event Inspection"
        >
          <div className="space-y-4">
            <div className="grid grid-cols-2 gap-3 text-xs">
              <div>
                <span className="text-slate-400 block mb-0.5">Event ID</span>
                <span className="font-mono text-slate-800 font-semibold break-all">
                  {selectedLog.id}
                </span>
              </div>
              <div>
                <span className="text-slate-400 block mb-0.5">Recorded At</span>
                <span className="text-slate-800 font-medium">
                  {selectedLog.timestamp}
                </span>
              </div>
              <div>
                <span className="text-slate-400 block mb-0.5">Actor Identity</span>
                <span className="text-slate-800 font-medium">
                  {selectedLog.actorEmail}
                </span>
              </div>
              <div>
                <span className="text-slate-400 block mb-0.5">Origin IP Address</span>
                <span className="font-mono text-slate-800 font-medium">
                  {selectedLog.ipAddress}
                </span>
              </div>
            </div>

            <div>
              <span className="text-xs text-slate-400 block mb-1">
                Contextual Event Payload (JSON)
              </span>
              <pre className="p-3 rounded-xl bg-slate-900 text-slate-100 text-[11px] font-mono overflow-x-auto max-h-48">
                {JSON.stringify(selectedLog.metadata, null, 2)}
              </pre>
            </div>
          </div>
        </Modal>
      )}
    </div>
  );
}
