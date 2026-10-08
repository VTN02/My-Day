import React from 'react';

export default function AdminDashboardPage() {
  return (
    <main className="min-h-screen flex flex-col items-center justify-center p-6 text-center">
      <div className="max-w-xl bg-[#151B2E] p-8 rounded-2xl shadow-xl border border-slate-800">
        <div className="inline-flex items-center gap-2 px-3 py-1 bg-indigo-900/50 text-indigo-400 text-xs font-semibold rounded-full uppercase tracking-wider mb-4">
          Admin Portal
        </div>
        <h1 className="text-2xl font-bold tracking-tight text-white mb-2">
          MyDay Super Admin
        </h1>
        <p className="text-slate-400 mb-6 text-sm">
          Platform health, telemetry, release management and operational controls.
        </p>
        <div className="p-4 bg-slate-900/60 rounded-xl text-xs text-slate-500 border border-slate-800">
          Admin console foundation initialized for Milestone 12.
        </div>
      </div>
    </main>
  );
}
