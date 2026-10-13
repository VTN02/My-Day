'use client';

import React, { useState, useEffect } from 'react';
import {
  Globe,
  Download,
  Smartphone,
  Users,
  Activity,
  ArrowRight,
  TrendingUp,
  Calendar,
  Layers,
  Filter,
  CheckCircle2,
} from 'lucide-react';
import { Card, CardHeader, CardTitle, CardDescription } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { KpiCard } from '@/components/ui/kpi-card';
import { Badge } from '@/components/ui/badge';
import {
  AreaChart,
  Area,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
} from 'recharts';

export default function AnalyticsOverviewPage() {
  const [selectedRange, setSelectedRange] = useState<7 | 30 | 90>(30);
  const [data, setData] = useState<any>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    setIsLoading(true);
    fetch(`/api/analytics/overview?days=${selectedRange}`)
      .then((res) => res.json())
      .then((res) => {
        setData(res);
        setIsLoading(false);
      })
      .catch(() => setIsLoading(false));
  }, [selectedRange]);

  const kpis = data?.kpis || {
    pageViews: { value: 0, change: '+0%' },
    uniqueVisitors: { value: 0, change: '+0%' },
    downloadClicks: { value: 0, change: '+0%' },
    confirmedDownloads: { value: 0, change: '+0%' },
    appFirstOpens: { value: 0, change: '+0%' },
    activeInstallations: { value: 0, change: '+0%' },
    totalSessions: { value: 0, change: '+0%' },
    clickConversion: '0%',
    downloadCompletion: '0%',
  };

  const funnel = data?.funnel || [];
  const trend = data?.trend || [];

  return (
    <div className="space-y-6">
      {/* 1. Header & Range Selectors */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl sm:text-3xl font-bold text-slate-800 tracking-tight">
            Analytics Overview
          </h1>
          <p className="text-xs sm:text-sm text-slate-500 mt-1">
            End-to-end platform reach, discovery conversion, and active Android installations.
          </p>
        </div>

        {/* Date Filter Controls */}
        <div className="flex items-center gap-1.5 p-1 bg-white border border-slate-200 rounded-xl shadow-xs">
          {[7, 30, 90].map((days) => (
            <button
              key={days}
              type="button"
              onClick={() => setSelectedRange(days as any)}
              className={`px-3 py-1.5 text-xs font-semibold rounded-lg transition-all ${
                selectedRange === days
                  ? 'bg-blue-600 text-white shadow-xs'
                  : 'text-slate-600 hover:text-slate-900 hover:bg-slate-50'
              }`}
            >
              Last {days} days
            </button>
          ))}
        </div>
      </div>

      {/* 2. Top KPI Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 sm:gap-5">
        <KpiCard
          title="Website Page Views"
          value={kpis.pageViews.value.toLocaleString()}
          icon={<Globe className="w-5 h-5" />}
          iconColorVariant="purple"
          trend={{ value: kpis.pageViews.change, isPositive: !kpis.pageViews.change.startsWith('-') }}
          subtitle="Landing page impressions"
        />

        <KpiCard
          title="Unique Visitors"
          value={kpis.uniqueVisitors.value.toLocaleString()}
          icon={<Users className="w-5 h-5" />}
          iconColorVariant="blue"
          trend={{ value: kpis.uniqueVisitors.change, isPositive: !kpis.uniqueVisitors.change.startsWith('-') }}
          subtitle="Non-PII ephemeral visitor hashes"
        />

        <KpiCard
          title="Confirmed APK Downloads"
          value={kpis.confirmedDownloads.value.toLocaleString()}
          icon={<Download className="w-5 h-5" />}
          iconColorVariant="emerald"
          trend={{ value: kpis.confirmedDownloads.change, isPositive: !kpis.confirmedDownloads.change.startsWith('-') }}
          subtitle={`${kpis.downloadCompletion} completion rate`}
        />

        <KpiCard
          title="Active App Installations"
          value={kpis.activeInstallations.value.toLocaleString()}
          icon={<Smartphone className="w-5 h-5" />}
          iconColorVariant="cyan"
          trend={{ value: kpis.activeInstallations.change, isPositive: !kpis.activeInstallations.change.startsWith('-') }}
          subtitle={`${kpis.totalSessions.value} total sessions logged`}
        />
      </div>

      {/* 3. Discovery to App Usage Conversion Funnel */}
      <Card>
        <CardHeader>
          <div>
            <CardTitle>Discovery-to-App Conversion Funnel</CardTitle>
            <CardDescription>
              How visitors progress from website discovery to confirmed download and daily app usage
            </CardDescription>
          </div>
          <Badge variant="primary" size="sm">
            Conversion Tracking Active
          </Badge>
        </CardHeader>

        <div className="space-y-4">
          {funnel.map((step: any, idx: number) => {
            const isFirst = idx === 0;
            const prevCount = idx > 0 ? funnel[idx - 1].count : step.count;
            const dropoffPercent = prevCount > 0 ? ((step.count / prevCount) * 100).toFixed(1) : '100';

            return (
              <div key={idx} className="space-y-1.5">
                <div className="flex items-center justify-between text-xs">
                  <div className="flex items-center gap-2">
                    <span className="font-semibold text-slate-800">{step.step}</span>
                    {!isFirst && (
                      <span className="text-[11px] text-slate-400">
                        ({dropoffPercent}% step conversion)
                      </span>
                    )}
                  </div>
                  <div className="flex items-center gap-3">
                    <span className="font-bold text-slate-800 text-sm">
                      {step.count.toLocaleString()}
                    </span>
                    <span className="font-mono text-[11px] text-slate-500 w-12 text-right">
                      {step.conversion}%
                    </span>
                  </div>
                </div>

                <div className="w-full h-3 rounded-full bg-slate-100 overflow-hidden flex">
                  <div
                    className="h-full rounded-full bg-blue-600 transition-all duration-500"
                    style={{ width: `${Math.max(step.conversion, 4)}%` }}
                  />
                </div>
              </div>
            );
          })}
        </div>
      </Card>

      {/* 4. Multi-metric Activity Trend Area Chart */}
      <Card>
        <CardHeader>
          <div>
            <CardTitle>Traffic & App Activity Trajectory</CardTitle>
            <CardDescription>
              Daily volume of web visitors vs confirmed APK downloads vs mobile app sessions
            </CardDescription>
          </div>
          <div className="flex items-center gap-4 text-xs font-medium">
            <span className="flex items-center gap-1.5 text-blue-600">
              <span className="w-2.5 h-2.5 rounded-full bg-blue-600 inline-block" /> Web Visitors
            </span>
            <span className="flex items-center gap-1.5 text-emerald-600">
              <span className="w-2.5 h-2.5 rounded-full bg-emerald-600 inline-block" /> Downloads
            </span>
            <span className="flex items-center gap-1.5 text-purple-600">
              <span className="w-2.5 h-2.5 rounded-full bg-purple-600 inline-block" /> Active Sessions
            </span>
          </div>
        </CardHeader>

        <div className="w-full h-72">
          <ResponsiveContainer width="100%" height="100%">
            <AreaChart data={trend} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
              <defs>
                <linearGradient id="visGrad" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#2563EB" stopOpacity={0.25} />
                  <stop offset="95%" stopColor="#2563EB" stopOpacity={0.0} />
                </linearGradient>
                <linearGradient id="downGrad" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#10B981" stopOpacity={0.25} />
                  <stop offset="95%" stopColor="#10B981" stopOpacity={0.0} />
                </linearGradient>
              </defs>
              <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#F1F5F9" />
              <XAxis dataKey="date" axisLine={false} tickLine={false} tick={{ fontSize: 11, fill: '#94A3B8' }} />
              <YAxis axisLine={false} tickLine={false} tick={{ fontSize: 11, fill: '#94A3B8' }} />
              <Tooltip
                contentStyle={{
                  backgroundColor: '#FFFFFF',
                  borderRadius: '12px',
                  border: '1px solid #E2E8F0',
                  boxShadow: '0 4px 12px rgba(0, 0, 0, 0.05)',
                  fontSize: '12px',
                }}
              />
              <Area type="monotone" dataKey="visitors" stroke="#2563EB" strokeWidth={2} fill="url(#visGrad)" />
              <Area type="monotone" dataKey="downloads" stroke="#10B981" strokeWidth={2} fill="url(#downGrad)" />
              <Area type="monotone" dataKey="active" stroke="#8B5CF6" strokeWidth={2} fillOpacity={0} />
            </AreaChart>
          </ResponsiveContainer>
        </div>
      </Card>
    </div>
  );
}
