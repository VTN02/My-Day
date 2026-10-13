'use client';

import React, { useState, useEffect } from 'react';
import {
  Smartphone,
  Activity,
  Layers,
  Clock,
  ShieldCheck,
  Cpu,
  CheckCircle2,
} from 'lucide-react';
import { Card, CardHeader, CardTitle, CardDescription } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { KpiCard } from '@/components/ui/kpi-card';

export default function AppUsageAnalyticsPage() {
  const [days, setDays] = useState(30);
  const [data, setData] = useState<any>(null);

  useEffect(() => {
    fetch(`/api/analytics/app-usage?days=${days}`)
      .then((r) => r.json())
      .then((res) => setData(res))
      .catch(() => setData(null));
  }, [days]);

  const active = data?.activeInstallations || {
    dau: 0,
    wau: 0,
    mau: 0,
    stickiness: '0.0%',
  };

  const acquisition = data?.acquisition || {
    firstOpens: 0,
    totalSessions: 0,
    returningInstalls: 0,
  };

  const osDistribution: Array<{ os: string; percent: number; count: string }> = data?.osDistribution || [];

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl sm:text-3xl font-bold text-slate-800 tracking-tight">
            App Usage & Installations
          </h1>
          <p className="text-xs sm:text-sm text-slate-500 mt-1">
            Active client installations, foreground session volume, and Android runtime environments.
          </p>
        </div>

        <div className="flex items-center gap-1.5 p-1 bg-white border border-slate-200 rounded-xl shadow-xs">
          {[7, 30, 90].map((d) => (
            <button
              key={d}
              onClick={() => setDays(d)}
              className={`px-3 py-1.5 text-xs font-semibold rounded-lg transition-all ${
                days === d
                  ? 'bg-blue-600 text-white shadow-xs'
                  : 'text-slate-600 hover:text-slate-900 hover:bg-slate-50'
              }`}
            >
              Last {d} days
            </button>
          ))}
        </div>
      </div>

      {/* Methodology Notice */}
      <div className="bg-slate-100/80 border border-slate-200 rounded-2xl p-4 flex items-start gap-3">
        <ShieldCheck className="w-5 h-5 text-slate-600 shrink-0 mt-0.5" />
        <div className="text-xs text-slate-700 leading-relaxed">
          <strong className="font-semibold text-slate-900">Installation Metric Transparency:</strong>{' '}
          In accordance with MyDay privacy tenets, telemetry tracks anonymous client installations (<code className="bg-slate-200 px-1 rounded text-slate-800 font-mono">install_id</code>), not natural persons. No user account is required to use the mobile application.
        </div>
      </div>

      {/* Active Installations Metric Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <KpiCard
          title="Daily Active Installs (DAI)"
          value={active.dau.toLocaleString()}
          icon={<Activity className="w-5 h-5" />}
          iconColorVariant="emerald"
          trend={{ value: `${active.stickiness} stickiness`, isPositive: true }}
          subtitle="Distinct installations active today"
        />

        <KpiCard
          title="Weekly Active Installs (WAI)"
          value={active.wau.toLocaleString()}
          icon={<Smartphone className="w-5 h-5" />}
          iconColorVariant="blue"
          trend={{ value: '7-day active window', isPositive: true }}
          subtitle="Rolling 7-day active installations"
        />

        <KpiCard
          title="Monthly Active Installs (MAI)"
          value={active.mau.toLocaleString()}
          icon={<Layers className="w-5 h-5" />}
          iconColorVariant="purple"
          trend={{ value: `${acquisition.returningInstalls} returning`, isPositive: true }}
          subtitle={`Rolling ${days}-day active installations`}
        />

        <KpiCard
          title="Total Foreground Sessions"
          value={acquisition.totalSessions.toLocaleString()}
          icon={<Clock className="w-5 h-5" />}
          iconColorVariant="amber"
          trend={{ value: `${active.mau > 0 ? (acquisition.totalSessions / active.mau).toFixed(1) : '0'} / install`, isPositive: true }}
          subtitle="Foreground sessions logged"
        />
      </div>

      {/* OS Environment & Architecture Breakdown */}
      <Card>
        <CardHeader>
          <div>
            <CardTitle>Android Operating System Distribution</CardTitle>
            <CardDescription>Verified OS versions running on active installations</CardDescription>
          </div>
          <Cpu className="w-4 h-4 text-slate-400" />
        </CardHeader>

        <div className="space-y-4 pt-2">
          {osDistribution.length === 0 ? (
            <div className="py-6 text-center text-xs text-slate-500">
              No mobile OS telemetry events recorded in the selected period. Client session telemetry will display here in real time.
            </div>
          ) : (
            osDistribution.map((item, idx) => (
              <div key={idx} className="space-y-1.5">
                <div className="flex items-center justify-between text-xs">
                  <span className="font-semibold text-slate-700">{item.os}</span>
                  <span className="font-mono text-slate-500">
                    {item.count} ({item.percent}%)
                  </span>
                </div>
                <div className="w-full h-2.5 rounded-full bg-slate-100 overflow-hidden">
                  <div
                    className="h-full rounded-full bg-blue-600 transition-all duration-300"
                    style={{ width: `${Math.max(item.percent, 3)}%` }}
                  />
                </div>
              </div>
            ))
          )}
        </div>
      </Card>
    </div>
  );
}
