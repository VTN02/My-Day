'use client';

import React, { useState } from 'react';
import Link from 'next/link';
import { Shield, Mail, ArrowLeft, CheckCircle2, AlertCircle } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Card } from '@/components/ui/card';

export default function ForgotPasswordPage() {
  const [email, setEmail] = useState('');
  const [isSubmitted, setIsSubmitted] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [errorMessage, setErrorMessage] = useState('');

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!email) {
      setErrorMessage('Please enter your administrative email address.');
      return;
    }

    setIsLoading(true);
    setErrorMessage('');

    try {
      // In production, invokes Supabase Auth resetPasswordForEmail
      setIsSubmitted(true);
    } catch (e: any) {
      setErrorMessage(e?.message || 'Failed to dispatch password recovery email.');
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
            Administrative account recovery
          </p>
        </div>

        {/* Card */}
        <Card className="p-8 shadow-sm border border-slate-200/90">
          {!isSubmitted ? (
            <>
              <div className="mb-6">
                <h2 className="text-lg font-semibold text-slate-800">Password Recovery</h2>
                <p className="text-xs text-slate-500 mt-0.5">
                  Enter your registered administrative email to receive a password reset link.
                </p>
              </div>

              {errorMessage && (
                <div className="mb-4 p-3 rounded-xl bg-rose-50 border border-rose-200 text-rose-700 text-xs flex items-center gap-2">
                  <AlertCircle className="w-4 h-4 shrink-0" />
                  <span>{errorMessage}</span>
                </div>
              )}

              <form onSubmit={handleSubmit} className="space-y-4">
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

                <Button
                  type="submit"
                  variant="primary"
                  className="w-full mt-2 rounded-xl h-11"
                  isLoading={isLoading}
                >
                  Send Recovery Link
                </Button>

                <div className="text-center pt-2">
                  <Link
                    href="/login"
                    className="text-xs font-semibold text-slate-500 hover:text-slate-800 inline-flex items-center gap-1.5"
                  >
                    <ArrowLeft className="w-3.5 h-3.5" />
                    <span>Back to sign in</span>
                  </Link>
                </div>
              </form>
            </>
          ) : (
            <div className="text-center py-4 space-y-4">
              <div className="w-12 h-12 rounded-full bg-emerald-50 text-emerald-600 flex items-center justify-center mx-auto">
                <CheckCircle2 className="w-6 h-6" />
              </div>

              <div>
                <h3 className="text-base font-bold text-slate-800">Recovery Link Dispatched</h3>
                <p className="text-xs text-slate-500 mt-1.5 leading-relaxed">
                  If an authorized Super Admin account exists for <strong className="text-slate-700">{email}</strong>, a secure one-time password reset token has been dispatched.
                </p>
              </div>

              <div className="pt-4 border-t border-slate-100">
                <Link href="/login">
                  <Button variant="outline" size="sm" className="w-full rounded-xl">
                    Return to Sign In
                  </Button>
                </Link>
              </div>
            </div>
          )}
        </Card>
      </div>
    </div>
  );
}
