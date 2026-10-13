import React from 'react';
import Link from 'next/link';
import { Shield, ArrowLeft } from 'lucide-react';

export default function TermsOfServicePage() {
  return (
    <main className="min-h-screen bg-[#F5F9FC] text-[#172B4D] py-12 px-6">
      <div className="max-w-3xl mx-auto">
        <div className="mb-8">
          <Link
            href="/"
            className="text-xs font-semibold text-blue-600 hover:text-blue-700 inline-flex items-center gap-1.5 mb-4"
          >
            <ArrowLeft className="w-3.5 h-3.5" />
            <span>Back to Home</span>
          </Link>
          <div className="flex items-center gap-2.5 mb-2">
            <div className="w-8 h-8 rounded-xl bg-[#1565C0] flex items-center justify-center text-white">
              <Shield className="w-4 h-4" />
            </div>
            <h1 className="text-2xl sm:text-3xl font-extrabold text-slate-900 tracking-tight">
              Terms of Service
            </h1>
          </div>
          <p className="text-xs text-slate-500">
            Effective Date: October 12, 2026
          </p>
        </div>

        <div className="bg-white p-8 rounded-2xl border border-slate-200/80 shadow-xs space-y-6 text-sm text-slate-700 leading-relaxed">
          <section className="space-y-2">
            <h2 className="text-base font-bold text-slate-900">1. Acceptance of Terms</h2>
            <p>
              By accessing the MyDay website or downloading the MyDay Android application, you agree to these Terms of Service. If you do not agree, do not install or use the software.
            </p>
          </section>

          <section className="space-y-2">
            <h2 className="text-base font-bold text-slate-900">2. Software License & Ownership</h2>
            <p>
              MyDay is licensed under standard open-source terms. You are granted a personal, non-exclusive license to use the application on compatible Android devices.
            </p>
          </section>

          <section className="space-y-2">
            <h2 className="text-base font-bold text-slate-900">3. Financial Calculations Disclaimer</h2>
            <p>
              The Personal Finance and MyDay Split modules compute calculations in integer minor currency units to avoid floating-point inaccuracies. MyDay is an organizational tracking tool and does not provide financial, accounting, tax, or legal advice.
            </p>
          </section>

          <section className="space-y-2">
            <h2 className="text-base font-bold text-slate-900">4. Limitation of Liability</h2>
            <p>
              MyDay is provided &quot;as is&quot; without warranties of any kind. Users are responsible for maintaining backups of their device and local SQLite database files.
            </p>
          </section>
        </div>
      </div>
    </main>
  );
}
