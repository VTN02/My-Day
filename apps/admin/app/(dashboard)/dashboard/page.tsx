'use client';

import React, { useEffect, useState } from 'react';
import Link from 'next/link';
import {
  Users,
  Package,
  Activity,
  Calendar,
  Download,
  ArrowUpRight,
  ShieldCheck,
  CheckCircle2,
  Clock,
  Sparkles,
  ExternalLink,
  RefreshCw,
  AlertTriangle,
} from 'lucide-react';
import { KpiCard } from '@/components/ui/kpi-card';
import { Card, CardHeader, CardTitle, CardDescription } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { SegmentedTabs } from '@/components/ui/tabs';
import { UserGrowthChart } from '@/components/charts/user-growth-chart';
import {
  TableWrapper,
  TableHeader,
  TableBody,
  TableRow,
  TableHead,
  TableCell,
} from '@/components/ui/table';

interface DashboardStats {
  totalUsers: number;
  activeToday: number;
  latestRelease: {
    versionName: string;
    versionCode: number;
    publishedAt: string;
  } | null;
  systemStatus: string;
  releaseDistribution: Array<{
    name: string;
    code: string;
    percent: number;
    count: number;
  }>;
  recentActivity: Array<{
    id: string;
    actor: string;
    action: string;
    target: string;
    time: string;
    result: string;
  }>;
  growthData: Array<{ date: string; users: number }>;
  lastUpdated?: string;
}

export default function DashboardOverviewPage() {
  const [chartTimeframe, setChartTimeframe] = useState('monthly');
  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [errorStatus, setErrorStatus] = useState<string | null>(null);

  const fetchStats = async () => {
    setIsLoading(true);
    try {
      const res = await fetch('/api/dashboard/stats', { cache: 'no-store' });
      const json = await res.json();
      if (res.ok && json.data) {
        setStats(json.data);
        setErrorStatus(null);
      } else if (json.status === 'not_configured') {
        setErrorStatus('not_configured');
        setStats(json.data);
      } else {
        setErrorStatus('unavailable');
      }
    } catch (e: any) {
      setErrorStatus('unavailable');
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchStats();
  }, []);

  return (
    <div className="space-y-6">
      {/* 1. Page Title & Action Controls Row */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl sm:text-3xl font-bold text-slate-800 tracking-tight">
            Dashboard
          </h1>
          <p className="text-xs sm:text-sm text-slate-500 mt-1">
            Real platform metrics and live backend diagnostics.
            {stats?.lastUpdated && (
              <span className="ml-1 text-slate-400">
                (Last updated {new Date(stats.lastUpdated).toLocaleTimeString()})
              </span>
            )}
          </p>
        </div>

        <div className="flex flex-wrap sm:flex-nowrap items-center gap-2 sm:gap-2.5">
          <Button
            variant="outline"
            size="sm"
            onClick={fetchStats}
            isLoading={isLoading}
            className="rounded-xl"
          >
            <RefreshCw className="w-4 h-4 text-slate-500" />
            <span>Refresh</span>
          </Button>

          <Link href="/analytics/overview">
            <Button variant="primary" size="sm" className="rounded-xl shadow-xs">
              <Activity className="w-4 h-4" />
              <span>Full Analytics</span>
            </Button>
          </Link>
        </div>
      </div>

      {/* Unconfigured Backend Notification Banner if applicable */}
      {errorStatus === 'not_configured' && (
        <div className="bg-amber-50 border border-amber-200/80 rounded-2xl p-4 flex items-start gap-3">
          <AlertTriangle className="w-5 h-5 text-amber-600 shrink-0 mt-0.5" />
          <div className="text-xs text-amber-900 leading-relaxed">
            <strong className="font-semibold text-amber-950">Backend Not Configured:</strong>{' '}
            Supabase environment variables are pending configuration. Metrics reflect clean zero states rather than synthetic data.
          </div>
        </div>
      )}

      {/* 2. Top 4 KPI Cards Grid with Real Backend Counts */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 sm:gap-5">
        <KpiCard
          title="Total Registered Users"
          value={isLoading ? '...' : stats ? String(stats.totalUsers) : '0'}
          icon={<Users className="w-5 h-5" />}
          iconColorVariant="purple"
          subtitle="Verified Supabase Auth accounts"
        />

        <KpiCard
          title="Active Today"
          value={isLoading ? '...' : stats ? String(stats.activeToday) : '0'}
          icon={<Activity className="w-5 h-5" />}
          iconColorVariant="emerald"
          subtitle="Telemetry active installations"
        />

        <KpiCard
          title="Latest Published APK"
          value={
            isLoading
              ? '...'
              : stats?.latestRelease
              ? `v${stats.latestRelease.versionName}`
              : 'No releases'
          }
          icon={<Package className="w-5 h-5" />}
          iconColorVariant="amber"
          subtitle={
            stats?.latestRelease
              ? `Build code ${stats.latestRelease.versionCode}`
              : 'None published'
          }
        />

        <KpiCard
          title="System Diagnostic State"
          value={isLoading ? '...' : stats?.systemStatus || 'Not monitored'}
          icon={<ShieldCheck className="w-5 h-5" />}
          iconColorVariant="blue"
          subtitle="Live cluster probes"
        />
      </div>

      {/* 3. Middle Grid: Real Growth Chart & Actual Distribution */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Real User Growth Chart (2 cols) */}
        <Card className="lg:col-span-2">
          <CardHeader>
            <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
              <div>
                <CardTitle>Account Registrations</CardTitle>
                <CardDescription>
                  Verified user registration volume from database
                </CardDescription>
              </div>

              <SegmentedTabs
                items={[
                  { id: 'monthly', label: 'Monthly' },
                  { id: 'all_time', label: 'All Time' },
                ]}
                activeTab={chartTimeframe}
                onChange={(id) => setChartTimeframe(id)}
              />
            </div>
          </CardHeader>

          <UserGrowthChart data={stats?.growthData || []} />
        </Card>

        {/* Real APK Downloads Distribution (1 col) */}
        <Card>
          <CardHeader>
            <div className="flex items-center justify-between">
              <div>
                <CardTitle>Release Distribution</CardTitle>
                <CardDescription>Confirmed downloads by version</CardDescription>
              </div>
              <Badge variant="primary">Real Telemetry</Badge>
            </div>
          </CardHeader>

          <div className="space-y-4">
            {stats && stats.releaseDistribution.length > 0 ? (
              stats.releaseDistribution.map((item, index) => (
                <div key={index} className="space-y-1.5">
                  <div className="flex items-center justify-between text-xs font-semibold">
                    <span className="text-slate-700">{item.name}</span>
                    <span className="text-slate-400 font-normal">
                      {item.count} downloads ({item.percent}%)
                    </span>
                  </div>
                  <div className="w-full h-2 bg-slate-100 rounded-full overflow-hidden">
                    <div
                      className="h-full bg-blue-600 rounded-full transition-all duration-500"
                      style={{ width: `${item.percent}%` }}
                    />
                  </div>
                </div>
              ))
            ) : (
              <div className="py-12 text-center text-xs text-slate-400">
                <Package className="w-8 h-8 text-slate-300 mx-auto mb-2" />
                No release download records yet.
              </div>
            )}
          </div>
        </Card>
      </div>

      {/* 4. Bottom Grid: Real Activity Trail & Quick Actions */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Real Recent Administrative Activity (2 cols) */}
        <Card className="lg:col-span-2">
          <CardHeader>
            <div className="flex items-center justify-between">
              <div>
                <CardTitle>Recent Administrative Actions</CardTitle>
                <CardDescription>
                  Verified immutable audit records from database
                </CardDescription>
              </div>
              <Link
                href="/audit-logs"
                className="text-xs font-semibold text-blue-600 hover:text-blue-700 flex items-center gap-1"
              >
                <span>View Full Trail</span>
                <ExternalLink className="w-3.5 h-3.5" />
              </Link>
            </div>
          </CardHeader>

          <TableWrapper>
            <TableHeader>
              <TableRow>
                <TableHead>Actor</TableHead>
                <TableHead>Action</TableHead>
                <TableHead>Target</TableHead>
                <TableHead>Time</TableHead>
                <TableHead>Outcome</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {stats && stats.recentActivity.length > 0 ? (
                stats.recentActivity.map((activity, index) => (
                  <TableRow key={activity.id || index}>
                    <TableCell className="font-medium text-slate-800 text-xs">
                      {activity.actor}
                    </TableCell>
                    <TableCell className="text-xs text-slate-600">
                      {activity.action}
                    </TableCell>
                    <TableCell className="text-xs text-slate-500">
                      {activity.target}
                    </TableCell>
                    <TableCell className="text-xs text-slate-400">
                      <div className="flex items-center gap-1.5">
                        <Clock className="w-3.5 h-3.5 text-slate-400" />
                        <span>{activity.time}</span>
                      </div>
                    </TableCell>
                    <TableCell>
                      <Badge
                        variant={activity.result === 'success' ? 'success' : 'error'}
                        size="sm"
                      >
                        {activity.result}
                      </Badge>
                    </TableCell>
                  </TableRow>
                ))
              ) : (
                <TableRow>
                  <TableCell colSpan={5} className="text-center py-8 text-xs text-slate-400">
                    No administrative events recorded yet.
                  </TableCell>
                </TableRow>
              )}
            </TableBody>
          </TableWrapper>
        </Card>

        {/* Quick Administrative Navigation (1 col) */}
        <Card>
          <CardHeader>
            <CardTitle>Management Shortcuts</CardTitle>
            <CardDescription>Quick administrative navigation</CardDescription>
          </CardHeader>

          <div className="space-y-2.5">
            <Link
              href="/releases"
              className="group flex items-center justify-between p-3 rounded-xl border border-slate-100 hover:border-blue-200 hover:bg-blue-50/40 transition-all text-xs font-semibold text-slate-700 hover:text-blue-700"
            >
              <div className="flex items-center gap-2.5">
                <div className="p-2 rounded-lg bg-blue-50 text-blue-600 group-hover:bg-blue-600 group-hover:text-white transition-colors">
                  <Package className="w-4 h-4" />
                </div>
                <span>Manage APK Releases</span>
              </div>
              <ArrowUpRight className="w-4 h-4 text-slate-400 group-hover:text-blue-600" />
            </Link>

            <Link
              href="/users"
              className="group flex items-center justify-between p-3 rounded-xl border border-slate-100 hover:border-blue-200 hover:bg-blue-50/40 transition-all text-xs font-semibold text-slate-700 hover:text-blue-700"
            >
              <div className="flex items-center gap-2.5">
                <div className="p-2 rounded-lg bg-pink-50 text-pink-600 group-hover:bg-pink-600 group-hover:text-white transition-colors">
                  <Users className="w-4 h-4" />
                </div>
                <span>Registered User Directory</span>
              </div>
              <ArrowUpRight className="w-4 h-4 text-slate-400 group-hover:text-blue-600" />
            </Link>

            <Link
              href="/system-health"
              className="group flex items-center justify-between p-3 rounded-xl border border-slate-100 hover:border-blue-200 hover:bg-blue-50/40 transition-all text-xs font-semibold text-slate-700 hover:text-blue-700"
            >
              <div className="flex items-center gap-2.5">
                <div className="p-2 rounded-lg bg-emerald-50 text-emerald-600 group-hover:bg-emerald-600 group-hover:text-white transition-colors">
                  <Activity className="w-4 h-4" />
                </div>
                <span>Inspect System Telemetry</span>
              </div>
              <ArrowUpRight className="w-4 h-4 text-slate-400 group-hover:text-blue-600" />
            </Link>

            <Link
              href="/settings"
              className="group flex items-center justify-between p-3 rounded-xl border border-slate-100 hover:border-blue-200 hover:bg-blue-50/40 transition-all text-xs font-semibold text-slate-700 hover:text-blue-700"
            >
              <div className="flex items-center gap-2.5">
                <div className="p-2 rounded-lg bg-amber-50 text-amber-600 group-hover:bg-amber-600 group-hover:text-white transition-colors">
                  <Sparkles className="w-4 h-4" />
                </div>
                <span>Platform Settings & Policies</span>
              </div>
              <ArrowUpRight className="w-4 h-4 text-slate-400 group-hover:text-blue-600" />
            </Link>
          </div>
        </Card>
      </div>
    </div>
  );
}
