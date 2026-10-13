import React from 'react';
import { cn } from '@/lib/utils';

export interface InputProps extends React.InputHTMLAttributes<HTMLInputElement> {
  icon?: React.ReactNode;
}

export const Input = React.forwardRef<HTMLInputElement, InputProps>(
  ({ className, type = 'text', icon, disabled, ...props }, ref) => {
    return (
      <div className="relative flex items-center w-full">
        {icon && (
          <div className="absolute left-3.5 flex items-center pointer-events-none text-slate-400">
            {icon}
          </div>
        )}
        <input
          type={type}
          ref={ref}
          disabled={disabled}
          className={cn(
            'w-full bg-white text-slate-800 text-sm rounded-xl border border-slate-200 py-2.5 transition-all duration-150',
            'placeholder:text-slate-400 placeholder:text-sm',
            'focus:outline-none focus:border-blue-500 focus:ring-4 focus:ring-blue-500/10',
            'disabled:bg-slate-50 disabled:text-slate-400 disabled:cursor-not-allowed',
            icon ? 'pl-10 pr-3.5' : 'px-3.5',
            className
          )}
          {...props}
        />
      </div>
    );
  }
);

Input.displayName = 'Input';
