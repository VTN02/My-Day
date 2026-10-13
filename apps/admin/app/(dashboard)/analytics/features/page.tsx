'use client';

import React, { useState, useEffect } from 'react';
import {
  Zap,
  BarChart2,
  CheckCircle2,
  Lock,
  ArrowUpDown,
  TrendingUp,
} from 'lucide-react';
import { Card, CardHeader, CardTitle, CardDescription } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { SegmentedTabs } from '@/components/ui/tabs';
import {
  TableWrapper,
  TableHeader,
  TableBody,
  TableRow,
  TableHead,
  TableCell,
} from '@/components/ui/table';

export default function FeatureAnalyticsPage() {
  const [metricMode, setMetricMode] = useState<'opens' | 'installations'>('opens');
  const [features, setFeatures] = useState<any[]>([]);
  const [days, setDays] = useState(30);

  useEffect(() => {
    fetch(`/api/analytics/features?days=${days}`)
      .then((r) => r.json())
      .then((res) => {
        const list = Array.isArray(res?.features) ? res.features : Array.isArray(res) ? res : [];
        setFeatures(list);
      })
      .catch(() => setFeatures([]));
  }, [days]);

  // Sort by selected metric safely
  const sortedFeatures = (Array.isArray(features) ? [...features] : []).sort((a, b) => {
    const valA = metricMode === 'opens' ? (a.totalOpens || 0) : (a.distinctInstallations || a.distinctActiveInstalls || 0);
    const valB = metricMode === 'opens' ? (b.totalOpens || 0) : (b.distinctInstallations || b.distinctActiveInstalls || 0);
    return valB - valA;
  });

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl sm:text-3xl font-bold text-slate-800 tracking-tight">
            Feature Popularity & Adoption
          </h1>
          <p className="text-xs sm:text-sm text-slate-500 mt-1">
            Compare usage across Today, Tasks, Finance, MyDay Split, Notes, and Calendar.
          </p>
        </div>

        <div className="flex flex-wrap sm:flex-nowrap items-center gap-2.5 sm:gap-3">
          {/* Mode Switcher: Total Opens vs Distinct Active Installations */}
          <SegmentedTabs
            items={[
              { id: 'opens', label: 'By Total Opens' },
              { id: 'installations', label: 'By Distinct Installs' },
            ]}
            activeTab={metricMode}
            onChange={(m: any) => setMetricMode(m)}
          />

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
                Last {d}d
              </button>
            ))}
          </div>
        </div>
      </div>

      {/* Content Exclusion Guarantee Banner */}
      <div className="bg-emerald-50/70 border border-emerald-200/80 rounded-2xl p-4 flex items-start gap-3">
        <Lock className="w-5 h-5 text-emerald-600 shrink-0 mt-0.5" />
        <div className="text-xs text-emerald-950 leading-relaxed">
          <strong className="font-semibold text-emerald-950">Aggregated Counts Only:</strong>{' '}
          Feature tracking records only feature navigation and high-level action completions (e.g. task created, expense created). Task titles, notes bodies, transaction amounts, and contacts are strictly prohibited and never transmitted.
        </div>
      </div>

      {/* Ranked Bar Progress Cards */}
      <Card>
        <CardHeader>
          <div>
            <CardTitle>
              Feature Popularity Ranking ({metricMode === 'opens' ? 'Total Opens' : 'Distinct Installations'})
            </CardTitle>
            <CardDescription>
              {metricMode === 'opens'
                ? 'Ranked by total navigation views logged across all sessions'
                : 'Ranked by distinct installations that engaged with the feature'}
            </CardDescription>
          </div>
        </CardHeader>

        <div className="space-y-5 pt-2">
          {sortedFeatures.map((feat, idx) => {
            const maxVal = sortedFeatures[0]
              ? metricMode === 'opens'
                ? sortedFeatures[0].totalOpens
                : sortedFeatures[0].distinctInstallations
              : 1;
            const currentVal = metricMode === 'opens' ? feat.totalOpens : feat.distinctInstallations;
            const barWidth = maxVal > 0 ? Math.round((currentVal / maxVal) * 100) : 0;

            return (
              <div key={feat.key} className="space-y-1.5">
                <div className="flex items-center justify-between text-xs">
                  <div className="flex items-center gap-2">
                    <span className="w-5 font-mono text-slate-400 font-bold">#{idx + 1}</span>
                    <span className="font-semibold text-slate-800">{feat.name}</span>
                  </div>
                  <div className="flex items-center gap-3">
                    <span className="font-bold text-slate-800">
                      {currentVal.toLocaleString()}{' '}
                      <span className="font-normal text-slate-500 text-[11px]">
                        {metricMode === 'opens' ? 'opens' : 'installs'}
                      </span>
                    </span>
                    <Badge variant="primary" size="sm">
                      {feat.reachPercentage}% reach
                    </Badge>
                  </div>
                </div>

                <div className="w-full h-3 rounded-full bg-slate-100 overflow-hidden">
                  <div
                    className="h-full rounded-full bg-blue-600 transition-all duration-500"
                    style={{ width: `${Math.max(barWidth, 3)}%` }}
                  />
                </div>
              </div>
            );
          })}
        </div>
      </Card>

      {/* Complete Feature Action & Engagement Matrix Table */}
      <Card>
        <CardHeader>
          <div>
            <CardTitle>Feature Metrics Matrix</CardTitle>
            <CardDescription>Detailed tallies for opens, install reach, and aggregate actions</CardDescription>
          </div>
        </CardHeader>

        <TableWrapper>
          <TableHeader>
            <TableRow>
              <TableHead>Feature Name</TableHead>
              <TableHead className="text-right">Total Opens</TableHead>
              <TableHead className="text-right">Distinct Active Installs</TableHead>
              <TableHead className="text-right">Active Reach Share</TableHead>
              <TableHead className="text-right">Aggregate Actions Logged</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {sortedFeatures.map((feat) => (
              <TableRow key={feat.key}>
                <TableCell className="font-semibold text-slate-800">{feat.name}</TableCell>
                <TableCell className="text-right font-mono text-xs">{feat.totalOpens.toLocaleString()}</TableCell>
                <TableCell className="text-right font-mono text-xs">{feat.distinctInstallations.toLocaleString()}</TableCell>
                <TableCell className="text-right">
                  <Badge variant="primary" size="sm">
                    {feat.reachPercentage}%
                  </Badge>
                </TableCell>
                <TableCell className="text-right font-mono text-xs text-slate-600">
                  {feat.totalActions.toLocaleString()}
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </TableWrapper>
      </Card>
    </div>
  );
}
