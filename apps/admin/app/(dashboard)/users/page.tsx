'use client';

import React, { useEffect, useState } from 'react';
import {
  Users,
  Search,
  UserX,
  UserCheck,
  Trash2,
  ShieldAlert,
  Download,
  RefreshCw,
  AlertCircle,
  CheckCircle2,
} from 'lucide-react';
import { Card } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Badge } from '@/components/ui/badge';
import {
  TableWrapper,
  TableHeader,
  TableBody,
  TableRow,
  TableHead,
  TableCell,
} from '@/components/ui/table';
import { ConfirmModal } from '@/components/ui/modal';

interface UserRecord {
  id: string;
  email: string;
  displayName: string;
  createdAt: string;
  lastSignIn: string;
  status: 'active' | 'suspended';
  provider: string;
}

export default function UsersManagementPage() {
  const [users, setUsers] = useState<UserRecord[]>([]);
  const [total, setTotal] = useState(0);
  const [isLoading, setIsLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');
  const [statusFilter, setStatusFilter] = useState<'all' | 'active' | 'suspended'>('all');
  const [page, setPage] = useState(1);
  const [notification, setNotification] = useState<{ type: 'success' | 'error'; message: string } | null>(null);

  // Modals
  const [selectedUser, setSelectedUser] = useState<UserRecord | null>(null);
  const [isSuspendModalOpen, setIsSuspendModalOpen] = useState(false);
  const [isDeleteModalOpen, setIsDeleteModalOpen] = useState(false);
  const [isActionLoading, setIsActionLoading] = useState(false);

  const fetchUsers = async () => {
    setIsLoading(true);
    try {
      const params = new URLSearchParams({
        q: searchQuery,
        status: statusFilter,
        page: String(page),
        perPage: '20',
      });
      const res = await fetch(`/api/users?${params.toString()}`, { cache: 'no-store' });
      const json = await res.json();
      if (res.ok && json.users) {
        setUsers(json.users);
        setTotal(json.total || 0);
      } else {
        setUsers([]);
        setTotal(0);
      }
    } catch (e) {
      setUsers([]);
      setTotal(0);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchUsers();
  }, [searchQuery, statusFilter, page]);

  const showNotification = (type: 'success' | 'error', message: string) => {
    setNotification({ type, message });
    setTimeout(() => setNotification(null), 4000);
  };

  const handleStatusChange = async (action: 'suspend' | 'reactivate') => {
    if (!selectedUser) return;
    setIsActionLoading(true);
    try {
      const res = await fetch(`/api/users/${selectedUser.id}/status`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          action,
          reason: action === 'suspend' ? 'Administrative security policy' : undefined,
        }),
      });
      const json = await res.json();
      if (res.ok && json.success) {
        showNotification(
          'success',
          `User ${selectedUser.email} is now ${json.status}.`
        );
        fetchUsers();
      } else {
        showNotification('error', json.error || 'Failed to update user status.');
      }
    } catch (e: any) {
      showNotification('error', e?.message || 'Network error updating user.');
    } finally {
      setIsActionLoading(false);
      setIsSuspendModalOpen(false);
    }
  };

  const handleDeleteUser = async () => {
    if (!selectedUser) return;
    setIsActionLoading(true);
    try {
      const res = await fetch(`/api/users/${selectedUser.id}/status`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ action: 'delete' }),
      });
      const json = await res.json();
      if (res.ok && json.success) {
        showNotification('success', `User ${selectedUser.email} decommissioned successfully.`);
        fetchUsers();
      } else {
        showNotification('error', json.error || 'Failed to delete user.');
      }
    } catch (e: any) {
      showNotification('error', e?.message || 'Network error deleting user.');
    } finally {
      setIsActionLoading(false);
      setIsDeleteModalOpen(false);
    }
  };

  const handleExportCsv = () => {
    if (users.length === 0) return;
    const header = 'ID,Email,DisplayName,CreatedAt,LastSignIn,Status,Provider\n';
    const rows = users
      .map(
        (u) =>
          `"${u.id}","${u.email}","${u.displayName}","${u.createdAt}","${u.lastSignIn}","${u.status}","${u.provider}"`
      )
      .join('\n');
    const blob = new Blob([header + rows], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `myday_users_${new Date().toISOString().split('T')[0]}.csv`;
    a.click();
    URL.revokeObjectURL(url);
  };

  return (
    <div className="space-y-6">
      {/* Page Title & Action Controls */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl sm:text-3xl font-bold text-slate-800 tracking-tight">
            User Management
          </h1>
          <p className="text-xs sm:text-sm text-slate-500 mt-1">
            Console Staff & Cloud Accounts ({total} registered). The mobile app operates offline without accounts.
          </p>
        </div>

        <div className="flex flex-wrap sm:flex-nowrap items-center gap-2 sm:gap-2.5">
          <Button
            variant="outline"
            size="sm"
            onClick={fetchUsers}
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
            disabled={users.length === 0}
            className="rounded-xl"
          >
            <Download className="w-4 h-4 text-slate-500" />
            <span>Export CSV</span>
          </Button>
        </div>
      </div>

      {/* Notification Banner */}
      {notification && (
        <div
          className={`p-3.5 rounded-xl border text-xs flex items-center gap-2.5 transition-all ${
            notification.type === 'success'
              ? 'bg-emerald-50 border-emerald-200 text-emerald-800'
              : 'bg-rose-50 border-rose-200 text-rose-800'
          }`}
        >
          {notification.type === 'success' ? (
            <CheckCircle2 className="w-4 h-4 text-emerald-600 shrink-0" />
          ) : (
            <AlertCircle className="w-4 h-4 text-rose-600 shrink-0" />
          )}
          <span>{notification.message}</span>
        </div>
      )}

      {/* Strict Privacy Guarantee Box */}
      <div className="bg-blue-50/70 border border-blue-200/80 rounded-2xl p-4 flex items-start gap-3">
        <ShieldAlert className="w-5 h-5 text-blue-600 shrink-0 mt-0.5" />
        <div className="text-xs text-blue-900 leading-relaxed">
          <strong className="font-semibold text-blue-950">Zero-Content Privacy Guarantee:</strong>{' '}
          Super Admins manage authentication status exclusively. In accordance with MyDay architecture, personal notes, tasks, finances, and group split expenses are encrypted and inaccessible from this console.
        </div>
      </div>

      {/* Main Table Card */}
      <Card>
        {/* Filter Bar */}
        <div className="flex flex-col sm:flex-row items-stretch sm:items-center justify-between gap-3 mb-6">
          <div className="w-full sm:w-72">
            <Input
              placeholder="Search by email, name or ID..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              icon={<Search className="w-4 h-4" />}
            />
          </div>

          <div className="flex flex-wrap items-center gap-2">
            <Button
              variant={statusFilter === 'all' ? 'primary' : 'outline'}
              size="sm"
              onClick={() => setStatusFilter('all')}
              className="rounded-lg"
            >
              All Users
            </Button>
            <Button
              variant={statusFilter === 'active' ? 'primary' : 'outline'}
              size="sm"
              onClick={() => setStatusFilter('active')}
              className="rounded-lg"
            >
              Active
            </Button>
            <Button
              variant={statusFilter === 'suspended' ? 'primary' : 'outline'}
              size="sm"
              onClick={() => setStatusFilter('suspended')}
              className="rounded-lg"
            >
              Suspended
            </Button>
          </div>
        </div>

        {/* User Directory Table */}
        <TableWrapper>
          <TableHeader>
            <TableRow>
              <TableHead>User Account</TableHead>
              <TableHead>Provider</TableHead>
              <TableHead>Registration Date</TableHead>
              <TableHead>Last Sign In</TableHead>
              <TableHead>Status</TableHead>
              <TableHead className="text-right">Actions</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {isLoading ? (
              <TableRow>
                <TableCell colSpan={6} className="text-center py-10 text-xs text-slate-400">
                  <RefreshCw className="w-5 h-5 animate-spin mx-auto mb-2 text-blue-600" />
                  Loading accounts from database...
                </TableCell>
              </TableRow>
            ) : users.length > 0 ? (
              users.map((u) => (
                <TableRow key={u.id}>
                  <TableCell>
                    <div>
                      <div className="font-semibold text-slate-800 text-xs">
                        {u.displayName}
                      </div>
                      <div className="text-[11px] text-slate-400 font-mono">
                        {u.email}
                      </div>
                    </div>
                  </TableCell>
                  <TableCell>
                    <Badge variant="neutral" size="sm">
                      {u.provider}
                    </Badge>
                  </TableCell>
                  <TableCell className="text-xs text-slate-500">
                    {new Date(u.createdAt).toLocaleDateString()}
                  </TableCell>
                  <TableCell className="text-xs text-slate-500">
                    {u.lastSignIn && u.lastSignIn !== 'Never signed in'
                      ? new Date(u.lastSignIn).toLocaleDateString()
                      : 'Never'}
                  </TableCell>
                  <TableCell>
                    <Badge
                      variant={u.status === 'active' ? 'success' : 'error'}
                      size="sm"
                    >
                      {u.status}
                    </Badge>
                  </TableCell>
                  <TableCell className="text-right">
                    <div className="flex items-center justify-end gap-1.5">
                      <Button
                        variant="ghost"
                        size="sm"
                        onClick={() => {
                          setSelectedUser(u);
                          setIsSuspendModalOpen(true);
                        }}
                        className={`rounded-lg ${
                          u.status === 'active'
                            ? 'text-amber-600 hover:text-amber-700 hover:bg-amber-50'
                            : 'text-emerald-600 hover:text-emerald-700 hover:bg-emerald-50'
                        }`}
                        title={u.status === 'active' ? 'Suspend User' : 'Restore User'}
                      >
                        {u.status === 'active' ? (
                          <UserX className="w-3.5 h-3.5" />
                        ) : (
                          <UserCheck className="w-3.5 h-3.5" />
                        )}
                      </Button>

                      <Button
                        variant="ghost"
                        size="sm"
                        onClick={() => {
                          setSelectedUser(u);
                          setIsDeleteModalOpen(true);
                        }}
                        className="text-rose-600 hover:text-rose-700 hover:bg-rose-50 rounded-lg"
                        title="Decommission Account"
                      >
                        <Trash2 className="w-3.5 h-3.5" />
                      </Button>
                    </div>
                  </TableCell>
                </TableRow>
              ))
            ) : (
              <TableRow>
                <TableCell colSpan={6} className="text-center py-12 text-xs text-slate-400">
                  <Users className="w-8 h-8 text-slate-300 mx-auto mb-2" />
                  No registered accounts matching query.
                </TableCell>
              </TableRow>
            )}
          </TableBody>
        </TableWrapper>
      </Card>

      {/* Suspend / Reactivate Confirmation Dialog */}
      <ConfirmModal
        isOpen={isSuspendModalOpen}
        onClose={() => setIsSuspendModalOpen(false)}
        onConfirm={() =>
          handleStatusChange(selectedUser?.status === 'active' ? 'suspend' : 'reactivate')
        }
        title={
          selectedUser?.status === 'active'
            ? 'Suspend User Account'
            : 'Reactivate User Account'
        }
        message={
          selectedUser?.status === 'active'
            ? `Are you sure you want to suspend "${selectedUser?.email}"? The user will immediately be blocked from logging into MyDay until reactivated.`
            : `Are you sure you want to restore access for "${selectedUser?.email}"?`
        }
        confirmText={
          isActionLoading
            ? 'Updating...'
            : selectedUser?.status === 'active'
            ? 'Suspend Account'
            : 'Reactivate'
        }
        isDanger={selectedUser?.status === 'active'}
      />

      {/* Deletion Request Confirmation Dialog */}
      <ConfirmModal
        isOpen={isDeleteModalOpen}
        onClose={() => setIsDeleteModalOpen(false)}
        onConfirm={handleDeleteUser}
        title="Initiate Controlled Account Deletion"
        message={`Are you sure you want to initiate account deletion for "${selectedUser?.email}"? This action will schedule cryptographic account decommissioning and record an audit log event.`}
        confirmText={isActionLoading ? 'Decommissioning...' : 'Decommission Account'}
        isDanger={true}
      />
    </div>
  );
}
