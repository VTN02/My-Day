'use client';

import React, { useEffect, useState } from 'react';
import {
  Sliders,
  Save,
  AlertTriangle,
  ExternalLink,
  ShieldAlert,
  Smartphone,
  Wrench,
  Link as LinkIcon,
  ToggleLeft,
  CheckCircle2,
  RefreshCw,
  AlertCircle,
} from 'lucide-react';
import { Card, CardHeader, CardTitle, CardDescription } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Badge } from '@/components/ui/badge';
import { ConfirmModal } from '@/components/ui/modal';

export default function PlatformSettingsPage() {
  const [minVersionCode, setMinVersionCode] = useState('4');
  const [recommendedVersion, setRecommendedVersion] = useState('1.1.1');
  const [updateAdvisory, setUpdateAdvisory] = useState(
    'Please upgrade to the latest MyDay release to ensure data integrity and full feature access.'
  );

  const [isMaintenanceEnabled, setIsMaintenanceEnabled] = useState(false);
  const [maintenanceMessage, setMaintenanceMessage] = useState(
    'MyDay platform is currently performing scheduled infrastructure maintenance.'
  );

  const [whatsappUrl, setWhatsappUrl] = useState(
    'https://whatsapp.com/channel/0029VbC9tOXGU3BRlJoxya3h'
  );
  const [websiteUrl, setWebsiteUrl] = useState('https://myday.app');
  const [supportUrl, setSupportUrl] = useState('https://github.com/VTN02/My-Day/issues');

  const [isConfirmSaveOpen, setIsConfirmSaveOpen] = useState(false);
  const [isSaving, setIsSaving] = useState(false);
  const [isLoading, setIsLoading] = useState(true);
  const [notification, setNotification] = useState<{ type: 'success' | 'error'; message: string } | null>(null);

  const fetchSettings = async () => {
    setIsLoading(true);
    try {
      const res = await fetch('/api/settings', { cache: 'no-store' });
      const json = await res.json();
      if (res.ok && json.settings) {
        setMinVersionCode(String(json.settings.minVersionCode || '4'));
        setRecommendedVersion(json.settings.recommendedVersion || '1.1.1');
        setUpdateAdvisory(json.settings.updateAdvisory || '');
        setIsMaintenanceEnabled(Boolean(json.settings.isMaintenanceEnabled));
        setMaintenanceMessage(json.settings.maintenanceMessage || '');
        setWhatsappUrl(json.settings.whatsappUrl || '');
        setWebsiteUrl(json.settings.websiteUrl || '');
        setSupportUrl(json.settings.supportUrl || '');
      }
    } catch (e) {
      // Retain defaults
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchSettings();
  }, []);

  const showNotification = (type: 'success' | 'error', message: string) => {
    setNotification({ type, message });
    setTimeout(() => setNotification(null), 4000);
  };

  const handleSave = async () => {
    setIsSaving(true);
    try {
      const res = await fetch('/api/settings', {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          minVersionCode,
          recommendedVersion,
          updateAdvisory,
          isMaintenanceEnabled,
          maintenanceMessage,
          whatsappUrl,
          websiteUrl,
          supportUrl,
        }),
      });

      const json = await res.json();
      if (res.ok && json.success) {
        showNotification('success', 'Platform settings saved to database and audit log recorded.');
        setIsConfirmSaveOpen(false);
      } else {
        showNotification('error', json.error || 'Failed to save platform configuration.');
      }
    } catch (e: any) {
      showNotification('error', e?.message || 'Network error updating settings.');
    } finally {
      setIsSaving(false);
      setIsConfirmSaveOpen(false);
    }
  };

  return (
    <div className="space-y-6">
      {/* Header & Save Button */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl sm:text-3xl font-bold text-slate-800 tracking-tight">
            App Configuration
          </h1>
          <p className="text-xs sm:text-sm text-slate-500 mt-1">
            Global version compatibility, maintenance windows, community URLs, and feature flags.
          </p>
        </div>

        <div className="flex items-center gap-2.5">
          <Button
            variant="outline"
            size="sm"
            onClick={fetchSettings}
            isLoading={isLoading}
            className="rounded-xl"
          >
            <RefreshCw className="w-4 h-4 text-slate-500" />
            <span>Reload</span>
          </Button>

          <Button
            variant="primary"
            size="sm"
            onClick={() => setIsConfirmSaveOpen(true)}
            className="rounded-xl shadow-xs"
          >
            <Save className="w-4 h-4" />
            <span>Save Configuration</span>
          </Button>
        </div>
      </div>

      {/* Notification Banner */}
      {notification && (
        <div
          className={`p-3.5 rounded-xl border text-xs flex items-center gap-2.5 transition-all ${
            notification.type === 'success'
              ? 'bg-emerald-50 border-emerald-200 text-emerald-800'
              : 'bg-rose-50 border-rose-200 text-rose-800'
          }`}
        >
          {notification.type === 'success' ? (
            <CheckCircle2 className="w-4 h-4 text-emerald-600 shrink-0" />
          ) : (
            <AlertCircle className="w-4 h-4 text-rose-600 shrink-0" />
          )}
          <span>{notification.message}</span>
        </div>
      )}

      {/* Section 1: Android Version Compatibility Policy */}
      <Card>
        <CardHeader>
          <div className="flex items-center gap-2.5">
            <div className="p-2 rounded-xl bg-blue-50 text-blue-600">
              <Smartphone className="w-5 h-5" />
            </div>
            <div>
              <CardTitle>Client App Version Compatibility</CardTitle>
              <CardDescription>
                Governs minimum version requirements enforced on mobile clients
              </CardDescription>
            </div>
          </div>
        </CardHeader>

        <div className="space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-xs font-semibold text-slate-700 mb-1.5">
                Minimum Supported Version Code
              </label>
              <Input
                type="number"
                value={minVersionCode}
                onChange={(e) => setMinVersionCode(e.target.value)}
                placeholder="4"
              />
              <p className="text-[11px] text-slate-400 mt-1">
                Clients running an older build will be prompted to upgrade before continuing.
              </p>
            </div>

            <div>
              <label className="block text-xs font-semibold text-slate-700 mb-1.5">
                Recommended Version Name
              </label>
              <Input
                value={recommendedVersion}
                onChange={(e) => setRecommendedVersion(e.target.value)}
                placeholder="1.1.1"
              />
              <p className="text-[11px] text-slate-400 mt-1">
                Current stable version presented on the public web landing page.
              </p>
            </div>
          </div>

          <div>
            <label className="block text-xs font-semibold text-slate-700 mb-1.5">
              Client Advisory Notice Message
            </label>
            <textarea
              rows={2}
              value={updateAdvisory}
              onChange={(e) => setUpdateAdvisory(e.target.value)}
              className="w-full text-xs text-slate-800 p-3 rounded-xl border border-slate-200 focus:outline-none focus:border-blue-500"
            />
          </div>
        </div>
      </Card>

      {/* Section 2: Platform Maintenance Windows */}
      <Card>
        <CardHeader>
          <div className="flex items-center gap-2.5">
            <div className="p-2 rounded-xl bg-amber-50 text-amber-600">
              <Wrench className="w-5 h-5" />
            </div>
            <div>
              <CardTitle>Emergency Maintenance Mode</CardTitle>
              <CardDescription>
                Broadcast downtime notification across public website and mobile clients
              </CardDescription>
            </div>
          </div>
        </CardHeader>

        <div className="space-y-4">
          <div className="flex items-center justify-between p-3.5 rounded-xl border border-slate-200/80 bg-slate-50/50">
            <div>
              <span className="text-xs font-semibold text-slate-800 block">
                Enable Maintenance Lockdown
              </span>
              <span className="text-[11px] text-slate-500">
                Puts APIs into read-only mode and displays maintenance advisory.
              </span>
            </div>
            <input
              type="checkbox"
              checked={isMaintenanceEnabled}
              onChange={(e) => setIsMaintenanceEnabled(e.target.checked)}
              className="w-5 h-5 rounded text-blue-600 focus:ring-blue-500"
            />
          </div>

          <div>
            <label className="block text-xs font-semibold text-slate-700 mb-1.5">
              Public Maintenance Notice
            </label>
            <Input
              value={maintenanceMessage}
              onChange={(e) => setMaintenanceMessage(e.target.value)}
              placeholder="MyDay platform is currently performing scheduled maintenance."
            />
          </div>
        </div>
      </Card>

      {/* Section 3: Official Community & Support Links */}
      <Card>
        <CardHeader>
          <div className="flex items-center gap-2.5">
            <div className="p-2 rounded-xl bg-emerald-50 text-emerald-600">
              <LinkIcon className="w-5 h-5" />
            </div>
            <div>
              <CardTitle>Official Public & Support Endpoints</CardTitle>
              <CardDescription>
                Live endpoints shared across mobile settings and website headers
              </CardDescription>
            </div>
          </div>
        </CardHeader>

        <div className="space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-xs font-semibold text-slate-700 mb-1.5">
                Official WhatsApp Channel URL
              </label>
              <Input
                value={whatsappUrl}
                onChange={(e) => setWhatsappUrl(e.target.value)}
              />
            </div>

            <div>
              <label className="block text-xs font-semibold text-slate-700 mb-1.5">
                Public Website Landing URL
              </label>
              <Input
                value={websiteUrl}
                onChange={(e) => setWebsiteUrl(e.target.value)}
              />
            </div>
          </div>

          <div>
            <label className="block text-xs font-semibold text-slate-700 mb-1.5">
              GitHub Issues / Support Ticket URL
            </label>
            <Input
              value={supportUrl}
              onChange={(e) => setSupportUrl(e.target.value)}
            />
          </div>
        </div>
      </Card>

      {/* Save Confirmation Dialog */}
      <ConfirmModal
        isOpen={isConfirmSaveOpen}
        onClose={() => setIsConfirmSaveOpen(false)}
        onConfirm={handleSave}
        title="Confirm Platform Configuration Update"
        message="Are you sure you want to save these global changes? The new policy will immediately apply to all connected clients and an immutable audit log entry will be recorded."
        confirmText={isSaving ? 'Saving to Database...' : 'Apply Changes'}
      />
    </div>
  );
}
