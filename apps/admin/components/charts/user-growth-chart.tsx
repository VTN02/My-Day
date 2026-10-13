'use client';

import React from 'react';
import {
  AreaChart,
  Area,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
} from 'recharts';
import { Users } from 'lucide-react';

export interface ChartDataPoint {
  date: string;
  users: number;
}

interface UserGrowthChartProps {
  data: ChartDataPoint[];
}

export function UserGrowthChart({ data }: UserGrowthChartProps) {
  if (!data || data.length === 0) {
    return (
      <div className="w-full h-72 flex flex-col items-center justify-center border border-dashed border-slate-200 rounded-2xl bg-slate-50/50 p-6 text-center">
        <div className="w-10 h-10 rounded-full bg-slate-100 flex items-center justify-center text-slate-400 mb-2.5">
          <Users className="w-5 h-5" />
        </div>
        <p className="text-xs font-semibold text-slate-700">No registration history yet</p>
        <p className="text-[11px] text-slate-400 max-w-xs mt-0.5">
          User registration trends will plot here in real-time as authenticated accounts register.
        </p>
      </div>
    );
  }

  return (
    <div className="w-full h-72">
      <ResponsiveContainer width="100%" height="100%">
        <AreaChart
          data={data}
          margin={{ top: 10, right: 10, left: -20, bottom: 0 }}
        >
          <defs>
            <linearGradient id="userGrowthGradient" x1="0" y1="0" x2="0" y2="1">
              <stop offset="5%" stopColor="#2563EB" stopOpacity={0.22} />
              <stop offset="95%" stopColor="#2563EB" stopOpacity={0.0} />
            </linearGradient>
          </defs>
          <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#F1F5F9" />
          <XAxis
            dataKey="date"
            axisLine={false}
            tickLine={false}
            tick={{ fontSize: 11, fill: '#94A3B8' }}
            dy={8}
          />
          <YAxis
            axisLine={false}
            tickLine={false}
            tick={{ fontSize: 11, fill: '#94A3B8' }}
            allowDecimals={false}
          />
          <Tooltip
            contentStyle={{
              backgroundColor: '#0F172A',
              borderRadius: '12px',
              border: 'none',
              color: '#FFFFFF',
              fontSize: '12px',
              boxShadow: '0 8px 24px rgba(0, 0, 0, 0.15)',
            }}
            formatter={(value: any) => [`${value} Accounts`, 'Registered']}
          />
          <Area
            type="monotone"
            dataKey="users"
            stroke="#2563EB"
            strokeWidth={2.5}
            fillOpacity={1}
            fill="url(#userGrowthGradient)"
          />
        </AreaChart>
      </ResponsiveContainer>
    </div>
  );
}
