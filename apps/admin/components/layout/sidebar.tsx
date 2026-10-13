'use client';

import React from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import {
  LayoutDashboard,
  Users,
  Package,
  Activity,
  FileText,
  Sliders,
  UserCheck,
  LogOut,
  Sparkles,
  ChevronRight,
  Shield,
  BarChart3,
  Globe,
  Smartphone,
  TrendingUp,
  Zap,
  X,
  Music,
} from 'lucide-react';
import { cn } from '@/lib/utils';

export interface SidebarProps {
  isCollapsed: boolean;
  onToggleCollapse?: () => void;
  onLogoutClick?: () => void;
  onNavigate?: () => void;
  onCloseMobile?: () => void;
}

interface NavItem {
  name: string;
  href: string;
  icon: React.ElementType;
  badge?: string;
  badgeColor?: 'blue' | 'emerald' | 'amber';
}

interface NavSection {
  title: string;
  items: NavItem[];
}

export function Sidebar({ isCollapsed, onLogoutClick, onNavigate, onCloseMobile }: SidebarProps) {
  const pathname = usePathname();

  const sections: NavSection[] = [
    {
      title: 'DASHBOARDS',
      items: [
        {
          name: 'Overview',
          href: '/dashboard',
          icon: LayoutDashboard,
        },
      ],
    },
    {
      title: 'ANALYTICS & REACH',
      items: [
        {
          name: 'Analytics Overview',
          href: '/analytics/overview',
          icon: BarChart3,
        },
        {
          name: 'Website & Reach',
          href: '/analytics/reach',
          icon: Globe,
        },
        {
          name: 'App Usage',
          href: '/analytics/app-usage',
          icon: Smartphone,
        },
        {
          name: 'Feature Analytics',
          href: '/analytics/features',
          icon: Zap,
        },
        {
          name: 'Engagement & Retention',
          href: '/analytics/engagement',
          icon: TrendingUp,
        },
      ],
    },
    {
      title: 'PLATFORM MANAGEMENT',
      items: [
        {
          name: 'Users',
          href: '/users',
          icon: Users,
        },
        {
          name: 'App Releases',
          href: '/releases',
          icon: Package,
          badge: 'v1.1.1',
          badgeColor: 'blue',
        },
        {
          name: 'System Health',
          href: '/system-health',
          icon: Activity,
          badge: 'Live',
          badgeColor: 'emerald',
        },
        {
          name: 'Audit Logs',
          href: '/audit-logs',
          icon: FileText,
        },
        {
          name: 'Reminder Tunes',
          href: '/reminder-tunes',
          icon: Music,
          badge: 'Audio',
          badgeColor: 'blue',
        },
        {
          name: 'App Configuration',
          href: '/settings',
          icon: Sliders,
        },
      ],
    },
    {
      title: 'ACCOUNT',
      items: [
        {
          name: 'Admin Profile',
          href: '/profile',
          icon: UserCheck,
        },
      ],
    },
  ];

  return (
    <aside
      className={cn(
        'fixed top-0 bottom-0 left-0 z-30 flex flex-col bg-white border-r border-slate-200/80 transition-all duration-200 ease-in-out',
        isCollapsed ? 'w-[72px]' : 'w-64'
      )}
    >
      {/* Brand Header */}
      <div className="h-16 flex items-center justify-between px-5 border-b border-slate-100">
        <div className="flex items-center gap-3">
          <div className="w-9 h-9 flex items-center justify-center shrink-0">
            <img
              src="/logo.png"
              alt="MyDay Logo"
              className="w-full h-full object-contain"
            />
          </div>
          {!isCollapsed && (
            <div className="flex flex-col overflow-hidden">
              <div className="flex items-center gap-1.5">
                <span className="font-bold text-slate-800 text-base tracking-tight leading-none">
                  MyDay
                </span>
                <span className="text-[10px] font-bold uppercase tracking-wider px-1.5 py-0.5 rounded-sm bg-blue-50 text-blue-600 border border-blue-200/60 leading-none">
                  Admin
                </span>
              </div>
              <span className="text-[11px] text-slate-400 truncate mt-0.5 font-medium">
                Enterprise Console
              </span>
            </div>
          )}
        </div>

        {onCloseMobile && (
          <button
            type="button"
            onClick={onCloseMobile}
            className="md:hidden p-1.5 rounded-lg text-slate-400 hover:text-slate-700 hover:bg-slate-100 transition-colors"
            title="Close navigation"
          >
            <X className="w-5 h-5" />
          </button>
        )}
      </div>

      {/* Navigation Sections */}
      <div className="flex-1 overflow-y-auto px-3 py-4 space-y-6">
        {sections.map((section, idx) => (
          <div key={idx} className="space-y-1">
            {!isCollapsed && (
              <h4 className="px-3 text-[10px] font-bold text-slate-400 uppercase tracking-wider mb-2">
                {section.title}
              </h4>
            )}
            {section.items.map((item) => {
              const Icon = item.icon;
              const isActive =
                item.href === '/dashboard'
                  ? pathname === '/dashboard' || pathname === '/'
                  : pathname.startsWith(item.href);

              return (
                <Link
                  key={item.href}
                  href={item.href}
                  onClick={onNavigate}
                  title={isCollapsed ? item.name : undefined}
                  className={cn(
                    'group flex items-center gap-3 px-3.5 py-2.5 rounded-xl text-sm font-medium transition-all duration-150 relative select-none',
                    isActive
                      ? 'bg-blue-600 text-white shadow-sm shadow-blue-600/20'
                      : 'text-slate-600 hover:text-slate-900 hover:bg-slate-100/70'
                  )}
                >
                  <Icon
                    className={cn(
                      'w-5 h-5 shrink-0 transition-colors',
                      isActive ? 'text-white' : 'text-slate-400 group-hover:text-slate-600'
                    )}
                  />

                  {!isCollapsed && (
                    <>
                      <span className="flex-1 truncate">{item.name}</span>

                      {item.badge && (
                        <span
                          className={cn(
                            'text-[10px] font-bold px-2 py-0.5 rounded-full uppercase tracking-wider',
                            isActive
                              ? 'bg-white/20 text-white'
                              : item.badgeColor === 'emerald'
                              ? 'bg-emerald-50 text-emerald-600 border border-emerald-200/60'
                              : 'bg-blue-50 text-blue-600 border border-blue-200/60'
                          )}
                        >
                          {item.badge}
                        </span>
                      )}
                    </>
                  )}
                </Link>
              );
            })}
          </div>
        ))}
      </div>

      {/* Logout Action at Bottom */}
      <div className="p-3 border-t border-slate-100">
        <button
          type="button"
          onClick={onLogoutClick}
          title={isCollapsed ? 'Logout' : undefined}
          className={cn(
            'w-full flex items-center gap-3 px-3.5 py-2.5 rounded-xl text-sm font-medium text-slate-500 hover:text-rose-600 hover:bg-rose-50 transition-colors group select-none',
            isCollapsed && 'justify-center px-0'
          )}
        >
          <LogOut className="w-5 h-5 shrink-0 text-slate-400 group-hover:text-rose-600 transition-colors" />
          {!isCollapsed && <span>Logout</span>}
        </button>
      </div>
    </aside>
  );
}
