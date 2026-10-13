import React from 'react';
import Link from 'next/link';
import { Shield, ArrowLeft, Lock, CheckCircle2 } from 'lucide-react';

export default function PrivacyPolicyPage() {
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
              Privacy Policy
            </h1>
          </div>
          <p className="text-xs text-slate-500">
            Effective Date: October 12, 2026 • MyDay Architecture Commitment
          </p>
        </div>

        <div className="bg-white p-8 rounded-2xl border border-slate-200/80 shadow-xs space-y-6 text-sm text-slate-700 leading-relaxed">
          <section className="space-y-2">
            <h2 className="text-base font-bold text-slate-900">1. Strict Zero-Content Privacy Policy</h2>
            <p>
              MyDay is designed from first principles as an <strong>offline-first personal productivity and finance companion</strong>. Your personal task titles, task descriptions, personal note bodies, monetary balances, transaction details, and group expense participant details remain strictly stored on your local device (or encrypted in private user database partitions).
            </p>
            <p>
              The MyDay Super Admin Console and platform telemetry pipelines are cryptographically barred from collecting or inspecting your personal task, note, or financial content.
            </p>
          </section>

          <section className="space-y-2">
            <h2 className="text-base font-bold text-slate-900">2. Cookieless Web Reach Hashing</h2>
            <p>
              When discovering MyDay via the public website, we employ an ephemeral daily rotating cryptographic salt to estimate unique visitor counts. We do not set persistent advertising tracking cookies, store cross-site advertising IDs, or sell visitor browsing profiles to any third party.
            </p>
          </section>

          <section className="space-y-2">
            <h2 className="text-base font-bold text-slate-900">3. Anonymous Client Telemetry & Opt-Out</h2>
            <p>
              The MyDay Android application includes an optional anonymous telemetry client designed to help Super Admins diagnose APK release stability, feature adoption, and app version distribution.
            </p>
            <ul className="list-disc pl-5 space-y-1 text-xs text-slate-600">
              <li>Telemetry uses an anonymous, randomly generated installation UUID.</li>
              <li>Installation UUIDs are never tied to your email or personal identity.</li>
              <li>You may toggle <strong>Anonymous Usage Telemetry</strong> off at any time under Mobile App <strong>Settings → Telemetry & Diagnostics</strong>.</li>
            </ul>
          </section>

          <section className="space-y-2">
            <h2 className="text-base font-bold text-slate-900">4. Contact & Security Reporting</h2>
            <p>
              For privacy inquiries or vulnerability disclosures, please file an issue through our verified repository or reach out via our official community channel.
            </p>
          </section>
        </div>
      </div>
    </main>
  );
}
