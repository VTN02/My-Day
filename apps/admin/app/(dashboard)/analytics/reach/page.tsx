'use client';

import React, { useState, useEffect } from 'react';
import {
  Globe,
  Share2,
  Smartphone,
  Laptop,
  Tablet,
  MousePointerClick,
  Download,
  CheckCircle2,
  ExternalLink,
  ShieldCheck,
} from 'lucide-react';
import { Card, CardHeader, CardTitle, CardDescription } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import {
  TableWrapper,
  TableHeader,
  TableBody,
  TableRow,
  TableHead,
  TableCell,
} from '@/components/ui/table';

export default function WebsiteReachPage() {
  const [data, setData] = useState<any>(null);
  const [overviewData, setOverviewData] = useState<any>(null);
  const [days, setDays] = useState(30);

  useEffect(() => {
    Promise.all([
      fetch(`/api/analytics/reach?days=${days}`).then((r) => r.json()),
      fetch(`/api/analytics/overview?days=${days}`).then((r) => r.json()),
    ]).then(([reach, overview]) => {
      setData(reach);
      setOverviewData(overview);
    });
  }, [days]);

  const sources = data?.sources || [];
  const devices = data?.devices || [];
  const kpis = overviewData?.kpis || {
    pageViews: { value: 0 },
    uniqueVisitors: { value: 0 },
    downloadClicks: { value: 0 },
    confirmedDownloads: { value: 0 },
    clickConversion: '0%',
    downloadCompletion: '0%',
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl sm:text-3xl font-bold text-slate-800 tracking-tight">
            Website & Public Reach
          </h1>
          <p className="text-xs sm:text-sm text-slate-500 mt-1">
            Analyze visitor discovery channels, device categories, and APK download completion rates.
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

      {/* Attribution & Distinction Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <Card className="p-5">
          <div className="flex items-center justify-between mb-3">
            <span className="text-xs font-semibold text-slate-500">Page Views</span>
            <Globe className="w-4 h-4 text-blue-600" />
          </div>
          <h3 className="text-2xl font-bold text-slate-800">{kpis.pageViews.value.toLocaleString()}</h3>
          <p className="text-[11px] text-slate-400 mt-1">Raw landing impressions</p>
        </Card>

        <Card className="p-5">
          <div className="flex items-center justify-between mb-3">
            <span className="text-xs font-semibold text-slate-500">Unique Visitors</span>
            <ShieldCheck className="w-4 h-4 text-purple-600" />
          </div>
          <h3 className="text-2xl font-bold text-slate-800">{kpis.uniqueVisitors.value.toLocaleString()}</h3>
          <p className="text-[11px] text-slate-400 mt-1">Daily cookieless salted hashes</p>
        </Card>

        <Card className="p-5">
          <div className="flex items-center justify-between mb-3">
            <span className="text-xs font-semibold text-slate-500">Download Clicks</span>
            <MousePointerClick className="w-4 h-4 text-amber-600" />
          </div>
          <h3 className="text-2xl font-bold text-slate-800">{kpis.downloadClicks.value.toLocaleString()}</h3>
          <p className="text-[11px] text-slate-400 mt-1">
            {kpis.clickConversion} of unique visitors
          </p>
        </Card>

        <Card className="p-5">
          <div className="flex items-center justify-between mb-3">
            <span className="text-xs font-semibold text-slate-500">Confirmed Downloads</span>
            <Download className="w-4 h-4 text-emerald-600" />
          </div>
          <h3 className="text-2xl font-bold text-slate-800">{kpis.confirmedDownloads.value.toLocaleString()}</h3>
          <p className="text-[11px] text-slate-400 mt-1">
            {kpis.downloadCompletion} initiated artifact streams
          </p>
        </Card>
      </div>

      {/* Traffic Sources & Device Categories Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Referral Traffic Sources */}
        <Card>
          <CardHeader>
            <div>
              <CardTitle>Discovery Traffic Sources</CardTitle>
              <CardDescription>Attribution sources measured via URL parameters</CardDescription>
            </div>
            <Share2 className="w-4 h-4 text-slate-400" />
          </CardHeader>

          <TableWrapper>
            <TableHeader>
              <TableRow>
                <TableHead>Source Channel</TableHead>
                <TableHead className="text-right">Visitors</TableHead>
                <TableHead className="text-right">Share</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {sources.map((src: any, idx: number) => {
                const total = sources.reduce((a: number, b: any) => a + b.count, 0) || 1;
                const share = ((src.count / total) * 100).toFixed(1);
                return (
                  <TableRow key={idx}>
                    <TableCell className="font-semibold text-slate-800">{src.name}</TableCell>
                    <TableCell className="text-right font-mono text-xs">{src.count.toLocaleString()}</TableCell>
                    <TableCell className="text-right">
                      <Badge variant="primary" size="sm">
                        {share}%
                      </Badge>
                    </TableCell>
                  </TableRow>
                );
              })}
            </TableBody>
          </TableWrapper>
        </Card>

        {/* Device Categories */}
        <Card>
          <CardHeader>
            <div>
              <CardTitle>Visitor Device Categories</CardTitle>
              <CardDescription>Breakdown between Mobile, Desktop, and Tablet visitors</CardDescription>
            </div>
            <Laptop className="w-4 h-4 text-slate-400" />
          </CardHeader>

          <div className="space-y-4 pt-2">
            {devices.map((dev: any, idx: number) => {
              const total = devices.reduce((a: number, b: any) => a + b.count, 0) || 1;
              const percent = Math.round((dev.count / total) * 100);
              return (
                <div key={idx} className="space-y-1.5">
                  <div className="flex items-center justify-between text-xs">
                    <span className="font-semibold text-slate-700">{dev.name}</span>
                    <span className="font-mono text-slate-500">
                      {dev.count.toLocaleString()} ({percent}%)
                    </span>
                  </div>
                  <div className="w-full h-2.5 rounded-full bg-slate-100 overflow-hidden">
                    <div
                      className="h-full rounded-full bg-blue-600 transition-all duration-300"
                      style={{ width: `${percent}%` }}
                    />
                  </div>
                </div>
              );
            })}
          </div>
        </Card>
      </div>
    </div>
  );
}
