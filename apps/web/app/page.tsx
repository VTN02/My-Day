'use client';

import React, { useEffect, useRef } from 'react';
import Link from 'next/link';
import {
  Download,
  Shield,
  CheckCircle2,
  Smartphone,
  Sparkles,
  ArrowRight,
  ExternalLink,
} from 'lucide-react';

export default function HomePage() {
  const downloadSectionRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const adminUrl = process.env.NEXT_PUBLIC_ADMIN_URL || 'http://localhost:3000';

    // 1. Dispatch cookieless page view beacon
    try {
      const searchParams = new URLSearchParams(window.location.search);
      const ref = searchParams.get('ref') || 'direct';

      fetch(`${adminUrl}/api/analytics/collect`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          eventId: `web_view_${Date.now()}_${Math.random().toString(36).substring(7)}`,
          eventType: 'web_page_view',
          clientType: 'web',
          referralSource: ref,
          deviceCategory: window.innerWidth < 768 ? 'mobile' : 'desktop',
          timestamp: new Date().toISOString(),
        }),
      }).catch(() => {});
    } catch (e) {
      // Safe no-op
    }

    // 2. Track download button impression when visible
    if (downloadSectionRef.current && 'IntersectionObserver' in window) {
      const observer = new IntersectionObserver(
        (entries) => {
          entries.forEach((entry) => {
            if (entry.isIntersecting) {
              fetch(`${adminUrl}/api/analytics/collect`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                  eventId: `web_imp_${Date.now()}_${Math.random().toString(36).substring(7)}`,
                  eventType: 'download_button_impression',
                  clientType: 'web',
                  timestamp: new Date().toISOString(),
                }),
              }).catch(() => {});
              observer.disconnect();
            }
          });
        },
        { threshold: 0.5 }
      );
      observer.observe(downloadSectionRef.current);
      return () => observer.disconnect();
    }
  }, []);

  const handleDownloadClick = () => {
    try {
      const adminUrl = process.env.NEXT_PUBLIC_ADMIN_URL || 'http://localhost:3000';
      fetch(`${adminUrl}/api/analytics/collect`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          eventId: `web_click_${Date.now()}_${Math.random().toString(36).substring(7)}`,
          eventType: 'download_button_click',
          clientType: 'web',
          deviceCategory: window.innerWidth < 768 ? 'mobile' : 'desktop',
          timestamp: new Date().toISOString(),
        }),
      }).catch(() => {});
    } catch (e) {
      // Safe
    }
  };

  return (
    <main className="min-h-screen bg-[#F5F9FC] text-[#172B4D] selection:bg-blue-100 flex flex-col justify-between">
      <div>
        {/* Navbar */}
        <nav className="h-16 border-b border-slate-200/80 bg-white/80 backdrop-blur-md sticky top-0 z-30 px-6 flex items-center justify-between max-w-6xl mx-auto">
          <div className="flex items-center gap-2.5">
            <div className="w-8 h-8 rounded-xl bg-[#1565C0] flex items-center justify-center text-white shadow-xs">
              <Shield className="w-4 h-4" />
            </div>
            <span className="font-bold text-lg text-slate-900 tracking-tight">MyDay</span>
          </div>

          <div className="flex items-center gap-4">
            <a
              href="https://whatsapp.com/channel/0029VbC9tOXGU3BRlJoxya3h"
              target="_blank"
              rel="noopener noreferrer"
              className="text-xs font-semibold text-slate-600 hover:text-blue-600 flex items-center gap-1"
            >
              Community Channel <ExternalLink className="w-3.5 h-3.5" />
            </a>
            <a
              href="/api/download/apk"
              onClick={handleDownloadClick}
              className="text-xs font-semibold px-3.5 py-2 rounded-xl bg-[#1565C0] text-white hover:bg-blue-700 shadow-xs flex items-center gap-1.5"
            >
              <Download className="w-3.5 h-3.5" />
              <span>Download APK</span>
            </a>
          </div>
        </nav>

        {/* Hero Section */}
        <section className="py-20 px-6 text-center max-w-4xl mx-auto">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-blue-50 text-blue-700 border border-blue-200/60 text-xs font-semibold mb-6">
            <Sparkles className="w-3.5 h-3.5" />
            <span>New Release v1.1.1 Available</span>
          </div>

          <h1 className="text-4xl sm:text-5xl lg:text-6xl font-extrabold text-slate-900 tracking-tight leading-[1.15] mb-6">
            Your offline-first personal productivity and finance companion.
          </h1>

          <p className="text-base sm:text-lg text-slate-600 max-w-2xl mx-auto mb-10 leading-relaxed">
            Manage tasks, track budgets in integer minor units, record private notes, and split group outing expenses with zero mandatory cloud lock-in.
          </p>

          {/* Download Card */}
          <div
            ref={downloadSectionRef}
            className="max-w-md mx-auto bg-white p-6 rounded-2xl border border-slate-200 shadow-sm"
          >
            <div className="flex items-center justify-between text-xs text-slate-500 mb-4 pb-3 border-b border-slate-100">
              <span className="font-semibold text-slate-700">Official Android Build</span>
              <span className="font-mono bg-slate-100 px-2 py-0.5 rounded text-slate-600">v1.1.1 (Code 4)</span>
            </div>

            <a
              href="/api/download/apk"
              onClick={handleDownloadClick}
              className="w-full flex items-center justify-center gap-2 px-5 py-3.5 rounded-xl bg-[#1565C0] hover:bg-blue-700 text-white font-bold text-sm shadow-md shadow-blue-600/20 active:scale-[0.98] transition-all"
            >
              <Download className="w-4 h-4" />
              <span>Download APK (72 MB)</span>
            </a>

            <p className="text-[11px] text-slate-400 mt-3">
              Compatible with Android 8.0+. Cryptographically verified build artifact.
            </p>
          </div>
        </section>
      </div>

      {/* Footer */}
      <footer className="border-t border-slate-200/80 bg-white/60 py-8 px-6">
        <div className="max-w-6xl mx-auto flex flex-col sm:flex-row items-center justify-between gap-4 text-xs text-slate-500">
          <div className="flex items-center gap-2">
            <span className="font-semibold text-slate-700">MyDay</span>
            <span>•</span>
            <span>Offline-First Productivity Platform</span>
          </div>

          <div className="flex items-center gap-5">
            <Link href="/privacy" className="hover:text-blue-600 font-medium">
              Privacy Policy
            </Link>
            <Link href="/terms" className="hover:text-blue-600 font-medium">
              Terms of Service
            </Link>
            <a
              href="https://github.com/VTN02/My-Day"
              target="_blank"
              rel="noreferrer"
              className="hover:text-blue-600 font-medium"
            >
              GitHub
            </a>
          </div>
        </div>
      </footer>
    </main>
  );
}
