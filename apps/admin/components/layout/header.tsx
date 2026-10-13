'use client';

import React, { useState } from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import {
  Menu,
  ChevronLeft,
  Search,
  Bell,
  Plus,
  ShieldAlert,
  User,
  LogOut,
  ExternalLink,
} from 'lucide-react';
import { Button } from '@/components/ui/button';
import { cn } from '@/lib/utils';

export interface HeaderProps {
  isCollapsed: boolean;
  onToggleCollapse: () => void;
  onMobileMenuToggle: () => void;
  adminEmail?: string;
  onLogoutClick?: () => void;
  onQuickActionClick?: () => void;
}

export function Header({
  isCollapsed,
  onToggleCollapse,
  onMobileMenuToggle,
  adminEmail = 'admin@myday.app',
  onLogoutClick,
  onQuickActionClick,
}: HeaderProps) {
  const pathname = usePathname();
  const [isProfileMenuOpen, setIsProfileMenuOpen] = useState(false);
  const [isAlertsOpen, setIsAlertsOpen] = useState(false);

  // Map route to breadcrumb title
  const getPageTitle = (path: string) => {
    if (path.startsWith('/analytics/reach')) return 'Website & Reach';
    if (path.startsWith('/analytics/app-usage')) return 'App Usage';
    if (path.startsWith('/analytics/features')) return 'Feature Analytics';
    if (path.startsWith('/analytics/engagement')) return 'Engagement & Retention';
    if (path.startsWith('/analytics')) return 'Analytics Overview';
    if (path.startsWith('/users')) return 'Users';
    if (path.startsWith('/releases')) return 'App Releases';
    if (path.startsWith('/system-health')) return 'System Health';
    if (path.startsWith('/audit-logs')) return 'Audit Logs';
    if (path.startsWith('/settings')) return 'App Configuration';
    if (path.startsWith('/profile')) return 'Admin Profile';
    return 'Dashboard';
  };

  const pageTitle = getPageTitle(pathname);

  return (
    <header className="sticky top-0 z-20 h-16 bg-white border-b border-slate-200/80 px-4 md:px-6 flex items-center justify-between gap-4">
      {/* Left: Sidebar Collapse Toggle + Breadcrumb / Navigation Pills */}
      <div className="flex items-center gap-3">
        {/* Mobile menu toggle */}
        <button
          type="button"
          onClick={onMobileMenuToggle}
          className="md:hidden p-2 rounded-xl text-slate-500 hover:text-slate-800 hover:bg-slate-100 transition-colors"
          title="Toggle Mobile Menu"
        >
          <Menu className="w-5 h-5" />
        </button>

        {/* Desktop collapse toggle */}
        <button
          type="button"
          onClick={onToggleCollapse}
          className="hidden md:flex p-1.5 rounded-lg border border-slate-200 text-slate-400 hover:text-slate-700 hover:bg-slate-50 transition-colors"
          title={isCollapsed ? 'Expand sidebar' : 'Collapse sidebar'}
        >
          <ChevronLeft
            className={cn('w-4 h-4 transition-transform duration-200', isCollapsed && 'rotate-180')}
          />
        </button>

        {/* Mobile page title */}
        <div className="flex sm:hidden items-center pl-1">
          <span className="text-sm font-bold text-slate-800 truncate max-w-[160px]">
            {pageTitle}
          </span>
        </div>

        {/* Desktop SaaS Tabs / Breadcrumb in Header */}
        <div className="hidden sm:flex items-center gap-2 pl-2">
          <span className="text-xs font-semibold px-3 py-1.5 rounded-lg bg-blue-50 text-blue-700 border border-blue-200/60">
            {pageTitle}
          </span>
          <span className="text-slate-300">/</span>
          <span className="text-xs font-medium text-slate-500">Overview</span>
        </div>
      </div>

      {/* Right: Search, Quick Action, Alerts, User Profile */}
      <div className="flex items-center gap-2 sm:gap-3">
        {/* Search input with keyboard hint */}
        <div className="relative hidden lg:flex items-center w-64">
          <Search className="w-4 h-4 text-slate-400 absolute left-3 pointer-events-none" />
          <input
            type="text"
            placeholder="Search records, users, releases..."
            className="w-full bg-slate-50 text-xs text-slate-800 pl-9 pr-8 py-2 rounded-xl border border-slate-200 focus:outline-none focus:bg-white focus:border-blue-500 focus:ring-4 focus:ring-blue-500/10 transition-all placeholder:text-slate-400"
          />
          <kbd className="absolute right-2.5 text-[10px] font-semibold text-slate-400 bg-white border border-slate-200 rounded px-1.5 py-0.5 pointer-events-none shadow-2xs">
            ⌘K
          </kbd>
        </div>

        {/* Quick Action Button (+ Create / Release) */}
        <Button
          variant="primary"
          size="sm"
          onClick={onQuickActionClick}
          className="rounded-lg shadow-xs px-2.5 sm:px-3 text-xs"
        >
          <Plus className="w-4 h-4" />
          <span className="hidden sm:inline">New Action</span>
        </Button>

        {/* Operational Alerts Bell */}
        <div className="relative">
          <button
            type="button"
            onClick={() => {
              setIsAlertsOpen(!isAlertsOpen);
              setIsProfileMenuOpen(false);
            }}
            className="relative p-2 rounded-xl text-slate-500 hover:text-slate-800 hover:bg-slate-100 transition-colors"
            title="Operational Alerts"
          >
            <Bell className="w-5 h-5" />
            <span className="absolute top-1.5 right-1.5 w-2 h-2 rounded-full bg-emerald-500 ring-2 ring-white" />
          </button>

          {isAlertsOpen && (
            <>
              {/* Invisible overlay for tap outside */}
              <div
                className="fixed inset-0 z-40"
                onClick={() => setIsAlertsOpen(false)}
              />
              <div className="absolute right-0 mt-2 w-[calc(100vw-32px)] sm:w-80 max-w-sm bg-white rounded-2xl shadow-xl border border-slate-200 p-4 z-50 animate-in fade-in zoom-in-95">
                <div className="flex items-center justify-between pb-3 border-b border-slate-100 mb-3">
                  <span className="text-xs font-semibold text-slate-800">Operational Alerts</span>
                  <span className="text-[10px] font-bold px-2 py-0.5 rounded-full bg-emerald-50 text-emerald-600 border border-emerald-200/60">
                    All Systems Operational
                  </span>
                </div>
                <p className="text-xs text-slate-500 leading-relaxed">
                  Zero active critical incidents. Database connectivity, Supabase Auth, and Release distribution checks are healthy.
                </p>
                <div className="mt-3 pt-3 border-t border-slate-100 flex justify-end">
                  <Link
                    href="/system-health"
                    onClick={() => setIsAlertsOpen(false)}
                    className="text-xs font-medium text-blue-600 hover:text-blue-700 flex items-center gap-1"
                  >
                    View Telemetry <ExternalLink className="w-3 h-3" />
                  </Link>
                </div>
              </div>
            </>
          )}
        </div>

        {/* Admin Profile Chip */}
        <div className="relative">
          <button
            type="button"
            onClick={() => {
              setIsProfileMenuOpen(!isProfileMenuOpen);
              setIsAlertsOpen(false);
            }}
            className="flex items-center gap-2 p-1 sm:p-1.5 sm:pr-2.5 rounded-xl hover:bg-slate-100 transition-colors text-left"
          >
            <div className="w-8 h-8 rounded-full bg-blue-600 text-white font-bold text-xs flex items-center justify-center shadow-xs">
              SA
            </div>
            <div className="hidden sm:flex flex-col">
              <span className="text-xs font-semibold text-slate-800 leading-tight">
                Super Admin
              </span>
              <span className="text-[10px] text-slate-400 font-medium leading-none">
                {adminEmail}
              </span>
            </div>
          </button>

          {isProfileMenuOpen && (
            <>
              {/* Invisible overlay for tap outside */}
              <div
                className="fixed inset-0 z-40"
                onClick={() => setIsProfileMenuOpen(false)}
              />
              <div className="absolute right-0 mt-2 w-56 max-w-[calc(100vw-32px)] bg-white rounded-2xl shadow-xl border border-slate-200 py-1.5 z-50 animate-in fade-in zoom-in-95">
                <div className="px-3.5 py-2 border-b border-slate-100 mb-1">
                  <p className="text-xs font-semibold text-slate-800">Super Admin Account</p>
                  <p className="text-[11px] text-slate-400 truncate">{adminEmail}</p>
                </div>

                <Link
                  href="/profile"
                  onClick={() => setIsProfileMenuOpen(false)}
                  className="flex items-center gap-2 px-3.5 py-2 text-xs font-medium text-slate-700 hover:bg-slate-50 transition-colors"
                >
                  <User className="w-4 h-4 text-slate-400" />
                  Admin Profile
                </Link>

                <button
                  type="button"
                  onClick={() => {
                    setIsProfileMenuOpen(false);
                    onLogoutClick?.();
                  }}
                  className="w-full flex items-center gap-2 px-3.5 py-2 text-xs font-medium text-rose-600 hover:bg-rose-50 transition-colors text-left"
                >
                  <LogOut className="w-4 h-4" />
                  Logout
                </button>
              </div>
            </>
          )}
        </div>
      </div>
    </header>
  );
}
