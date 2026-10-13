'use client';

import React, { useState } from 'react';
import { useRouter } from 'next/navigation';
import { Sidebar } from './sidebar';
import { Header } from './header';
import { ConfirmModal } from '@/components/ui/modal';
import { cn } from '@/lib/utils';

export interface AdminShellProps {
  children: React.ReactNode;
}

export function AdminShell({ children }: AdminShellProps) {
  const router = useRouter();
  const [isCollapsed, setIsCollapsed] = useState(false);
  const [isMobileOpen, setIsMobileOpen] = useState(false);
  const [isLogoutModalOpen, setIsLogoutModalOpen] = useState(false);
  const [isLoggingOut, setIsLoggingOut] = useState(false);

  const handleLogout = async () => {
    setIsLoggingOut(true);
    try {
      // Future Supabase auth logout
      await fetch('/api/auth/logout', { method: 'POST' }).catch(() => {});
    } finally {
      setIsLoggingOut(false);
      setIsLogoutModalOpen(false);
      router.push('/login');
    }
  };

  return (
    <div className="min-h-screen bg-[#F6F8FC] text-slate-800 overflow-x-hidden">
      {/* Desktop Sidebar */}
      <div className="hidden md:block">
        <Sidebar
          isCollapsed={isCollapsed}
          onToggleCollapse={() => setIsCollapsed(!isCollapsed)}
          onLogoutClick={() => setIsLogoutModalOpen(true)}
        />
      </div>

      {/* Mobile Drawer Backdrop & Sidebar */}
      {isMobileOpen && (
        <div className="fixed inset-0 z-50 md:hidden flex animate-in fade-in duration-200">
          <div
            className="fixed inset-0 bg-slate-900/40 backdrop-blur-xs transition-opacity"
            onClick={() => setIsMobileOpen(false)}
          />
          <div className="relative z-10 w-72 max-w-[82vw] h-full bg-white shadow-2xl flex flex-col animate-in slide-in-from-left duration-200">
            <Sidebar
              isCollapsed={false}
              onNavigate={() => setIsMobileOpen(false)}
              onCloseMobile={() => setIsMobileOpen(false)}
              onLogoutClick={() => {
                setIsMobileOpen(false);
                setIsLogoutModalOpen(true);
              }}
            />
          </div>
        </div>
      )}

      {/* Main Layout Area */}
      <div
        className={cn(
          'flex flex-col min-h-screen transition-all duration-200 ease-in-out',
          isCollapsed ? 'md:pl-[72px]' : 'md:pl-64'
        )}
      >
        <Header
          isCollapsed={isCollapsed}
          onToggleCollapse={() => setIsCollapsed(!isCollapsed)}
          onMobileMenuToggle={() => setIsMobileOpen(true)}
          onLogoutClick={() => setIsLogoutModalOpen(true)}
          onQuickActionClick={() => router.push('/releases')}
        />

        {/* Content Canvas */}
        <main className="flex-1 p-3.5 sm:p-5 md:p-6 lg:p-8 max-w-[1600px] w-full mx-auto">
          {children}
        </main>
      </div>

      {/* Logout Confirmation Dialog */}
      <ConfirmModal
        isOpen={isLogoutModalOpen}
        onClose={() => setIsLogoutModalOpen(false)}
        onConfirm={handleLogout}
        title="Sign Out of Super Admin Console"
        message="Are you sure you want to end your administrative session? You will need to sign in again to access privileged controls."
        confirmText="Sign Out"
        isDanger={true}
        isLoading={isLoggingOut}
      />
    </div>
  );
}
