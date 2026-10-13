import React from 'react';
import { MoreHorizontal, TrendingUp, TrendingDown } from 'lucide-react';
import { cn } from '@/lib/utils';

export interface KpiCardProps {
  title: string;
  value: string | number;
  icon: React.ReactNode;
  iconColorVariant?: 'purple' | 'emerald' | 'amber' | 'cyan' | 'blue';
  trend?: {
    value: string;
    isPositive?: boolean;
    label?: string;
  };
  subtitle?: string;
  onActionClick?: () => void;
  className?: string;
}

export function KpiCard({
  title,
  value,
  icon,
  iconColorVariant = 'blue',
  trend,
  subtitle,
  onActionClick,
  className,
}: KpiCardProps) {
  const iconVariants = {
    purple: 'bg-pink-50 text-pink-600 border-pink-100',
    emerald: 'bg-emerald-50 text-emerald-600 border-emerald-100',
    amber: 'bg-amber-50 text-amber-600 border-amber-100',
    cyan: 'bg-cyan-50 text-cyan-600 border-cyan-100',
    blue: 'bg-blue-50 text-blue-600 border-blue-100',
  };

  return (
    <div
      className={cn(
        'bg-white rounded-2xl border border-slate-200/80 p-4 sm:p-5 shadow-xs hover:border-slate-300 transition-all duration-150',
        className
      )}
    >
      {/* Top row: Tinted Squircle Icon + More Actions */}
      <div className="flex items-center justify-between mb-4">
        <div
          className={cn(
            'w-11 h-11 rounded-xl flex items-center justify-center border',
            iconVariants[iconColorVariant]
          )}
        >
          {icon}
        </div>
        <button
          type="button"
          onClick={onActionClick}
          className="p-1 rounded-lg text-slate-300 hover:text-slate-600 hover:bg-slate-100 transition-colors"
          title="Card options"
        >
          <MoreHorizontal className="w-5 h-5" />
        </button>
      </div>

      {/* Middle row: Label */}
      <p className="text-xs font-medium text-slate-500 mb-1">{title}</p>

      {/* Bottom row: Value & Trend */}
      <div className="flex items-baseline justify-between gap-2">
        <h4 className="text-2xl font-bold text-slate-800 tracking-tight">{value}</h4>

        {trend && (
          <div
            className={cn(
              'inline-flex items-center gap-1 text-xs font-semibold px-2 py-0.5 rounded-full border',
              trend.isPositive !== false
                ? 'bg-emerald-50 text-emerald-700 border-emerald-200/80'
                : 'bg-rose-50 text-rose-700 border-rose-200/80'
            )}
          >
            {trend.isPositive !== false ? (
              <TrendingUp className="w-3 h-3 text-emerald-600" />
            ) : (
              <TrendingDown className="w-3 h-3 text-rose-600" />
            )}
            <span>{trend.value}</span>
          </div>
        )}
      </div>

      {subtitle && (
        <p className="text-[11px] text-slate-400 mt-2">{subtitle}</p>
      )}
    </div>
  );
}
