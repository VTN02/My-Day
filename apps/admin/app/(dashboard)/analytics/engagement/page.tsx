'use client';

import React, { useState, useEffect } from 'react';
import {
  TrendingUp,
  Users,
  Repeat,
  Package,
  Layers,
  Calendar,
  CheckCircle2,
} from 'lucide-react';
import { Card, CardHeader, CardTitle, CardDescription } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import {
  TableWrapper,
  TableHeader,
  TableBody,
  TableRow,
  TableHead,
  TableCell,
} from '@/components/ui/table';

export default function EngagementRetentionPage() {
  const [data, setData] = useState<any>(null);

  useEffect(() => {
    fetch('/api/analytics/engagement')
      .then((r) => r.json())
      .then((res) => setData(res));
  }, []);

  const cohorts = data?.cohorts || [];
  const versionDistribution = data?.versionDistribution || [];

  return (
    <div className="space-y-6">
      {/* Header */}
      <div>
        <h1 className="text-2xl sm:text-3xl font-bold text-slate-800 tracking-tight">
          Engagement & Retention Cohorts
        </h1>
        <p className="text-xs sm:text-sm text-slate-500 mt-1">
          Measure user persistence across Day 1, Day 7, Day 14, and Day 30 retention windows.
        </p>
      </div>

      {/* Cohort Heatmap Table */}
      <Card>
        <CardHeader>
          <div>
            <CardTitle>Installation Retention Cohorts</CardTitle>
            <CardDescription>
              Percentage of installations returning to use MyDay after initial installation
            </CardDescription>
          </div>
          <Badge variant="primary" size="sm">
            Rolling Weekly Cohorts
          </Badge>
        </CardHeader>

        <TableWrapper>
          <TableHeader>
            <TableRow>
              <TableHead>Installation Cohort</TableHead>
              <TableHead>Cohort Size</TableHead>
              <TableHead className="text-center">Day 1</TableHead>
              <TableHead className="text-center">Day 7</TableHead>
              <TableHead className="text-center">Day 14</TableHead>
              <TableHead className="text-center">Day 30</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {cohorts.map((c: any, idx: number) => (
              <TableRow key={idx}>
                <TableCell className="font-semibold text-slate-800">{c.cohort}</TableCell>
                <TableCell className="font-mono text-xs text-slate-600">
                  {c.size} installs
                </TableCell>
                <TableCell className="text-center">
                  <span className="inline-block px-2.5 py-1 rounded-lg bg-blue-100 text-blue-800 font-bold text-xs">
                    {c.d1}
                  </span>
                </TableCell>
                <TableCell className="text-center">
                  <span className="inline-block px-2.5 py-1 rounded-lg bg-blue-50 text-blue-700 font-semibold text-xs border border-blue-200/60">
                    {c.d7}
                  </span>
                </TableCell>
                <TableCell className="text-center">
                  <span className="inline-block px-2.5 py-1 rounded-lg bg-slate-100 text-slate-700 font-medium text-xs">
                    {c.d14}
                  </span>
                </TableCell>
                <TableCell className="text-center">
                  <span className="inline-block px-2.5 py-1 rounded-lg bg-slate-50 text-slate-600 text-xs">
                    {c.d30}
                  </span>
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </TableWrapper>
      </Card>

      {/* Version Distribution Breakdown */}
      <Card>
        <CardHeader>
          <div>
            <CardTitle>App Version Distribution</CardTitle>
            <CardDescription>Active installation volume across published releases</CardDescription>
          </div>
          <Package className="w-4 h-4 text-slate-400" />
        </CardHeader>

        <div className="space-y-4 pt-2">
          {versionDistribution.map((v: any, idx: number) => {
            const pct = parseInt(v.share, 10);
            return (
              <div key={idx} className="space-y-1.5">
                <div className="flex items-center justify-between text-xs">
                  <span className="font-semibold text-slate-800">{v.version}</span>
                  <span className="font-mono text-slate-500">
                    {v.count} installs ({v.share})
                  </span>
                </div>
                <div className="w-full h-2.5 rounded-full bg-slate-100 overflow-hidden">
                  <div
                    className="h-full rounded-full bg-blue-600 transition-all duration-300"
                    style={{ width: `${pct}%` }}
                  />
                </div>
              </div>
            );
          })}
        </div>
      </Card>
    </div>
  );
}
