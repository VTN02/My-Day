import React from 'react';
import { cn } from '@/lib/utils';

export interface CardProps extends React.HTMLAttributes<HTMLDivElement> {
  padding?: 'none' | 'sm' | 'md' | 'lg';
}

export function Card({
  className,
  padding = 'md',
  children,
  ...props
}: CardProps) {
  const paddings = {
    none: '',
    sm: 'p-3.5 sm:p-4',
    md: 'p-4 sm:p-6',
    lg: 'p-5 sm:p-8',
  };

  return (
    <div
      className={cn(
        'bg-white rounded-2xl border border-slate-200/80 shadow-xs hover:border-slate-300/80 transition-all duration-150',
        paddings[padding],
        className
      )}
      {...props}
    >
      {children}
    </div>
  );
}

export function CardHeader({
  className,
  children,
  ...props
}: React.HTMLAttributes<HTMLDivElement>) {
  return (
    <div className={cn('flex flex-col sm:flex-row sm:items-center justify-between gap-3 pb-4 border-b border-slate-100 mb-5', className)} {...props}>
      {children}
    </div>
  );
}

export function CardTitle({
  className,
  children,
  ...props
}: React.HTMLAttributes<HTMLHeadingElement>) {
  return (
    <h3 className={cn('text-base font-semibold text-slate-800 tracking-tight', className)} {...props}>
      {children}
    </h3>
  );
}

export function CardDescription({
  className,
  children,
  ...props
}: React.HTMLAttributes<HTMLParagraphElement>) {
  return (
    <p className={cn('text-xs text-slate-500 mt-0.5', className)} {...props}>
      {children}
    </p>
  );
}
