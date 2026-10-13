'use client';

import React, { useState } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { Shield, Lock, Mail, ArrowRight, ShieldAlert, AlertCircle } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Card } from '@/components/ui/card';

export default function AdminLoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [errorMessage, setErrorMessage] = useState('');

  const handleCredentialsSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setErrorMessage('');

    if (!email || !password) {
      setErrorMessage('Please enter both administrative email and password.');
      return;
    }

    setIsLoading(true);

    try {
      const res = await fetch('/api/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, password }),
      });

      const json = await res.json();

      if (res.ok && json.success) {
        router.push('/dashboard');
      } else if (json.status === 'not_configured') {
        // In local development before Supabase keys are populated
        setErrorMessage(
          'Supabase backend not yet configured. Set NEXT_PUBLIC_SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY in .env.'
        );
      } else {
        setErrorMessage(json.error || 'Invalid credentials or unauthorized account.');
      }
    } catch (err: any) {
      setErrorMessage(err?.message || 'Connection error contacting authentication service.');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-[#F6F8FC] flex flex-col items-center justify-center p-4">
      <div className="w-full max-w-md">
        {/* Brand Header */}
        <div className="flex flex-col items-center text-center mb-8">
          <div className="w-16 h-16 flex items-center justify-center mb-3.5">
            <img
              src="/logo.png"
              alt="MyDay Logo"
              className="w-full h-full object-contain"
            />
          </div>
          <h1 className="text-2xl font-bold text-slate-800 tracking-tight">
            MyDay Super Admin
          </h1>
          <p className="text-xs text-slate-500 mt-1">
            Privileged administrative management console
          </p>
        </div>

        {/* Card */}
        <Card className="p-8 shadow-sm border border-slate-200/90">
          <div className="mb-6">
            <h2 className="text-lg font-semibold text-slate-800">Administrator Sign In</h2>
            <p className="text-xs text-slate-500 mt-0.5">
              Enter privileged credentials to access platform controls.
            </p>
          </div>

          {errorMessage && (
            <div className="mb-5 p-3.5 rounded-xl bg-rose-50 border border-rose-200 text-rose-700 text-xs flex items-start gap-2.5">
              <AlertCircle className="w-4 h-4 shrink-0 mt-0.5" />
              <span>{errorMessage}</span>
            </div>
          )}

          <form onSubmit={handleCredentialsSubmit} className="space-y-4">
            <div>
              <label className="block text-xs font-semibold text-slate-700 mb-1.5">
                Admin Email
              </label>
              <Input
                type="email"
                placeholder="super_admin@myday.app"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                icon={<Mail className="w-4 h-4" />}
                required
              />
            </div>

            <div>
              <div className="flex items-center justify-between mb-1.5">
                <label className="text-xs font-semibold text-slate-700">Password</label>
                <Link
                  href="/forgot-password"
                  className="text-[11px] font-medium text-blue-600 hover:text-blue-700 hover:underline"
                >
                  Forgot password?
                </Link>
              </div>
              <Input
                type="password"
                placeholder="••••••••••••"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                icon={<Lock className="w-4 h-4" />}
                required
              />
            </div>

            <Button
              type="submit"
              variant="primary"
              className="w-full mt-2 rounded-xl h-11"
              isLoading={isLoading}
            >
              <span>Sign In to Super Admin</span>
              <ArrowRight className="w-4 h-4 ml-1" />
            </Button>
          </form>

          {/* Security Advisory */}
          <div className="mt-6 pt-5 border-t border-slate-100 flex items-start gap-2.5">
            <ShieldAlert className="w-4 h-4 text-slate-400 shrink-0 mt-0.5" />
            <p className="text-[11px] text-slate-400 leading-relaxed">
              Privileged access is restricted to verified administrators. All authentication attempts and actions are recorded in the immutable audit log.
            </p>
          </div>
        </Card>
      </div>
    </div>
  );
}
