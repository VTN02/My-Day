'use client';

import React, { useEffect, useState } from 'react';
import {
  Activity,
  CheckCircle2,
  AlertTriangle,
  XCircle,
  RefreshCw,
  Server,
  Database,
  Lock,
  HardDrive,
  Globe,
  Clock,
  ShieldCheck,
  HelpCircle,
} from 'lucide-react';
import { Card, CardHeader, CardTitle, CardDescription } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';

interface HealthCheckItem {
  name: string;
  category: string;
  status: 'healthy' | 'degraded' | 'unavailable' | 'not_monitored';
  latencyMs: number;
  lastChecked: string;
  details: string;
}

export default function SystemHealthPage() {
  const [probes, setProbes] = useState<HealthCheckItem[]>([]);
  const [isRefreshing, setIsRefreshing] = useState(true);
  const [lastProbedTime, setLastProbedTime] = useState<string | null>(null);

  const runProbes = async () => {
    setIsRefreshing(true);
    try {
      const res = await fetch('/api/system-health/probe', { cache: 'no-store' });
      const json = await res.json();
      if (res.ok && json.probes) {
        setProbes(json.probes);
        setLastProbedTime(new Date().toLocaleTimeString());
      }
    } catch (e) {
      // Retain previous or mark unavailable
    } finally {
      setIsRefreshing(false);
    }
  };

  useEffect(() => {
    runProbes();
  }, []);

  const getStatusBadge = (status: HealthCheckItem['status']) => {
    switch (status) {
      case 'healthy':
        return (
          <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold bg-emerald-50 text-emerald-700 border border-emerald-200">
            <CheckCircle2 className="w-3.5 h-3.5" />
            <span>Operational</span>
          </span>
        );
      case 'degraded':
        return (
          <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold bg-amber-50 text-amber-700 border border-amber-200">
            <AlertTriangle className="w-3.5 h-3.5" />
            <span>Degraded</span>
          </span>
        );
      case 'unavailable':
        return (
          <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold bg-rose-50 text-rose-700 border border-rose-200">
            <XCircle className="w-3.5 h-3.5" />
            <span>Unavailable</span>
          </span>
        );
      case 'not_monitored':
        return (
          <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold bg-slate-100 text-slate-600 border border-slate-200">
            <HelpCircle className="w-3.5 h-3.5 text-slate-400" />
            <span>Not Monitored</span>
          </span>
        );
    }
  };

  const getServiceIcon = (name: string) => {
    if (name.includes('Auth')) return Lock;
    if (name.includes('Database') || name.includes('Postgre')) return Database;
    if (name.includes('Storage')) return HardDrive;
    if (name.includes('Website')) return Globe;
    if (name.includes('API') || name.includes('Console')) return Server;
    return Activity;
  };

  return (
    <div className="space-y-6">
      {/* Page Title & Controls */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl sm:text-3xl font-bold text-slate-800 tracking-tight">
            System Health & Telemetry
          </h1>
          <p className="text-xs sm:text-sm text-slate-500 mt-1">
            Live diagnostic probes executed against backend services, database clusters, and web endpoints.
            {lastProbedTime && ` (Last run: ${lastProbedTime})`}
          </p>
        </div>

        <Button
          variant="primary"
          size="sm"
          onClick={runProbes}
          isLoading={isRefreshing}
          className="rounded-xl shadow-xs"
        >
          <RefreshCw className="w-4 h-4" />
          <span>Run Live Probes</span>
        </Button>
      </div>

      {/* Grid of Probed Services */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
        {probes.map((item, index) => {
          const IconComp = getServiceIcon(item.name);
          return (
            <Card key={index} className="flex flex-col justify-between">
              <div>
                <div className="flex items-start justify-between gap-3 mb-3">
                  <div className="flex items-center gap-2.5">
                    <div className="w-9 h-9 rounded-xl bg-blue-50 text-blue-600 flex items-center justify-center shrink-0">
                      <IconComp className="w-4 h-4" />
                    </div>
                    <div>
                      <h3 className="text-xs font-bold text-slate-800 leading-tight">
                        {item.name}
                      </h3>
                      <span className="text-[10px] text-slate-400 font-medium">
                        {item.category}
                      </span>
                    </div>
                  </div>
                  {getStatusBadge(item.status)}
                </div>

                <p className="text-xs text-slate-600 leading-relaxed mb-4">
                  {item.details}
                </p>
              </div>

              <div className="pt-3 border-t border-slate-100 flex items-center justify-between text-[11px] text-slate-400">
                <div className="flex items-center gap-1 font-mono">
                  <span>Latency:</span>
                  <span
                    className={
                      item.latencyMs > 500
                        ? 'text-amber-600 font-semibold'
                        : item.latencyMs > 0
                        ? 'text-emerald-600 font-semibold'
                        : 'text-slate-400'
                    }
                  >
                    {item.latencyMs > 0 ? `${item.latencyMs}ms` : 'N/A'}
                  </span>
                </div>
                <div className="flex items-center gap-1">
                  <Clock className="w-3 h-3 text-slate-400" />
                  <span>{item.lastChecked}</span>
                </div>
              </div>
            </Card>
          );
        })}
      </div>
    </div>
  );
}
