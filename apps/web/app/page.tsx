import React from 'react';

export default function HomePage() {
  return (
    <main className="min-h-screen flex flex-col items-center justify-center p-6 text-center">
      <div className="max-w-2xl bg-white p-8 rounded-2xl shadow-sm border border-slate-200">
        <div className="inline-flex items-center gap-2 px-3 py-1 bg-indigo-50 text-indigo-700 text-xs font-semibold rounded-full uppercase tracking-wider mb-4">
          Milestone Foundation
        </div>
        <h1 className="text-3xl font-extrabold tracking-tight text-slate-900 mb-2">
          MyDay Platform
        </h1>
        <p className="text-slate-600 mb-6">
          Your offline-first personal life management and productivity companion.
        </p>
        <div className="p-4 bg-slate-50 rounded-xl text-sm text-slate-500">
          Landing application foundation ready for Milestone 11.
        </div>
      </div>
    </main>
  );
}
