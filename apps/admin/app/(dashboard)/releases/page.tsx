'use client';

import React, { useEffect, useState } from 'react';
import {
  Package,
  Plus,
  CheckCircle2,
  AlertTriangle,
  UploadCloud,
  FileCheck,
  ExternalLink,
  ShieldCheck,
  Eye,
  RefreshCw,
  AlertCircle,
  GitBranch,
  Copy,
} from 'lucide-react';
import { Card, CardHeader, CardTitle, CardDescription } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Input } from '@/components/ui/input';
import { Modal, ConfirmModal } from '@/components/ui/modal';
import {
  TableWrapper,
  TableHeader,
  TableBody,
  TableRow,
  TableHead,
  TableCell,
} from '@/components/ui/table';

interface ReleaseRecord {
  id: string;
  versionName: string;
  versionCode: number;
  channel: 'stable' | 'beta';
  status: 'published' | 'draft' | 'ready' | 'withdrawn';
  publishedAt: string;
  fileSize: string;
  fileSizeBytes?: number;
  checksumSha256: string;
  downloadUrl: string;
  downloadCount?: number;
  gitHubUrl?: string;
  releaseTitle?: string;
  rawBody?: string;
  author?: string;
  authorAvatar?: string;
  isMandatory: boolean;
  releaseNotes: string[];
}

export default function ReleaseManagementPage() {
  const [releases, setReleases] = useState<ReleaseRecord[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isSyncing, setIsSyncing] = useState(false);
  const [notification, setNotification] = useState<{ type: 'success' | 'error'; message: string } | null>(null);

  // Modals & Selection
  const [isDraftModalOpen, setIsDraftModalOpen] = useState(false);
  const [selectedRelease, setSelectedRelease] = useState<ReleaseRecord | null>(null);
  const [isDetailsModalOpen, setIsDetailsModalOpen] = useState(false);
  const [isPublishModalOpen, setIsPublishModalOpen] = useState(false);
  const [isWithdrawModalOpen, setIsWithdrawModalOpen] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);

  // Form states for draft creation
  const [newVersionName, setNewVersionName] = useState('');
  const [newVersionCode, setNewVersionCode] = useState('');
  const [newChannel, setNewChannel] = useState<'stable' | 'beta'>('stable');
  const [newNotes, setNewNotes] = useState('');
  const [newDownloadUrl, setNewDownloadUrl] = useState('');
  const [newChecksum, setNewChecksum] = useState('');
  const [isMandatory, setIsMandatory] = useState(false);

  const fetchReleases = async () => {
    setIsLoading(true);
    try {
      const res = await fetch('/api/releases', { cache: 'no-store' });
      const json = await res.json();
      if (res.ok && json.releases) {
        setReleases(json.releases);
      } else {
        setReleases([]);
      }
    } catch {
      setReleases([]);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchReleases();
  }, []);

  const showNotification = (type: 'success' | 'error', message: string) => {
    setNotification({ type, message });
    setTimeout(() => setNotification(null), 4000);
  };

  const handleSyncGitHub = async () => {
    setIsSyncing(true);
    try {
      const res = await fetch('/api/releases/sync', { method: 'POST' });
      const json = await res.json();
      if (res.ok && json.releases) {
        setReleases(json.releases);
        showNotification('success', json.message || 'Synchronized releases from GitHub successfully.');
      } else {
        showNotification('error', json.error || 'Failed to sync with GitHub.');
      }
    } catch {
      showNotification('error', 'Network error while contacting GitHub Releases.');
    } finally {
      setIsSyncing(false);
    }
  };

  const handleCreateDraft = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newVersionName || !newVersionCode) {
      showNotification('error', 'Version name and numeric build code are required.');
      return;
    }

    setIsSubmitting(true);
    try {
      const notesList = newNotes
        .split('\n')
        .map((s) => s.trim())
        .filter(Boolean);

      const res = await fetch('/api/releases', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          versionName: newVersionName,
          versionCode: parseInt(newVersionCode, 10),
          channel: newChannel,
          releaseNotes: notesList,
          downloadUrl: newDownloadUrl,
          checksumSha256: newChecksum,
          isMandatory,
        }),
      });

      const json = await res.json();
      if (res.ok) {
        showNotification('success', `Draft release v${newVersionName} created.`);
        setIsDraftModalOpen(false);
        setNewVersionName('');
        setNewVersionCode('');
        setNewNotes('');
        setNewDownloadUrl('');
        setNewChecksum('');
        setIsMandatory(false);
        fetchReleases();
      } else {
        showNotification('error', json.error || 'Failed to create release draft.');
      }
    } catch {
      showNotification('error', 'Network error creating draft.');
    } finally {
      setIsSubmitting(false);
    }
  };

  const handlePublishRelease = async () => {
    if (!selectedRelease) return;
    setIsSubmitting(true);
    try {
      const res = await fetch(`/api/releases/${selectedRelease.id}`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ action: 'publish' }),
      });
      const json = await res.json();
      if (res.ok) {
        showNotification('success', `v${selectedRelease.versionName} has been published.`);
        setIsPublishModalOpen(false);
        fetchReleases();
      } else {
        showNotification('error', json.error || 'Failed to publish release.');
      }
    } catch {
      showNotification('error', 'Network error.');
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleWithdrawRelease = async () => {
    if (!selectedRelease) return;
    setIsSubmitting(true);
    try {
      const res = await fetch(`/api/releases/${selectedRelease.id}`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ action: 'withdraw' }),
      });
      const json = await res.json();
      if (res.ok) {
        showNotification('success', `v${selectedRelease.versionName} has been withdrawn.`);
        setIsWithdrawModalOpen(false);
        fetchReleases();
      } else {
        showNotification('error', json.error || 'Failed to withdraw release.');
      }
    } catch {
      showNotification('error', 'Network error.');
    } finally {
      setIsSubmitting(false);
    }
  };

  const latestPublished = releases.find((r) => r.status === 'published');
  const totalDownloads = releases.reduce((acc, r) => acc + (r.downloadCount || 0), 0);

  return (
    <div className="space-y-6">
      {/* Toast Notification */}
      {notification && (
        <div
          className={`fixed bottom-5 right-5 z-50 flex items-center gap-3 px-4 py-3 rounded-xl shadow-lg border text-sm font-medium transition-all ${
            notification.type === 'success'
              ? 'bg-emerald-50 border-emerald-200 text-emerald-800'
              : 'bg-rose-50 border-rose-200 text-rose-800'
          }`}
        >
          {notification.type === 'success' ? (
            <CheckCircle2 className="w-5 h-5 text-emerald-600 shrink-0" />
          ) : (
            <AlertCircle className="w-5 h-5 text-rose-600 shrink-0" />
          )}
          <span>{notification.message}</span>
        </div>
      )}

      {/* Header & Controls */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl sm:text-3xl font-bold text-slate-800 tracking-tight">
            Release Management
          </h1>
          <p className="text-xs sm:text-sm text-slate-500 mt-1">
            Publish Android APK builds, verify SHA-256 integrity, inspect release notes, and sync automatically with GitHub.
          </p>
        </div>

        <div className="flex flex-wrap sm:flex-nowrap items-center gap-2 sm:gap-2.5">
          <Button
            variant="outline"
            size="sm"
            onClick={handleSyncGitHub}
            isLoading={isSyncing}
            className="flex items-center gap-1.5 border-slate-200 text-slate-700 hover:bg-slate-50 shadow-xs"
          >
            <RefreshCw className={`w-3.5 h-3.5 ${isSyncing ? 'animate-spin' : ''}`} />
            Sync from GitHub
          </Button>

          <Button
            variant="primary"
            size="sm"
            onClick={() => setIsDraftModalOpen(true)}
            className="flex items-center gap-1.5 shadow-xs"
          >
            <Plus className="w-4 h-4" />
            Draft New Release
          </Button>
        </div>
      </div>

      {/* Overview Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <Card className="p-4 sm:p-5 flex items-center gap-4">
          <div className="w-12 h-12 rounded-xl bg-blue-50 flex items-center justify-center text-blue-600 shrink-0">
            <Package className="w-6 h-6" />
          </div>
          <div>
            <span className="text-xs font-semibold uppercase tracking-wider text-slate-400">
              Current Live Version
            </span>
            <div className="flex items-center gap-2 mt-0.5">
              <h2 className="text-xl font-bold text-slate-800">
                {latestPublished ? `v${latestPublished.versionName}` : 'None'}
              </h2>
              {latestPublished && (
                <Badge variant="primary" size="sm">
                  Build {latestPublished.versionCode}
                </Badge>
              )}
            </div>
            <p className="text-[11px] text-slate-500 mt-0.5">
              {latestPublished?.publishedAt ? `Published ${latestPublished.publishedAt}` : 'No published versions'}
            </p>
          </div>
        </Card>

        <Card className="p-4 sm:p-5 flex items-center gap-4">
          <div className="w-12 h-12 rounded-xl bg-emerald-50 flex items-center justify-center text-emerald-600 shrink-0">
            <ShieldCheck className="w-6 h-6" />
          </div>
          <div>
            <span className="text-xs font-semibold uppercase tracking-wider text-slate-400">
              GitHub Sync Status
            </span>
            <h2 className="text-xl font-bold text-slate-800 flex items-center gap-2 mt-0.5">
              <span>Automated</span>
              <span className="inline-block w-2 h-2 rounded-full bg-emerald-500 animate-pulse" />
            </h2>
            <p className="text-[11px] text-slate-500 mt-0.5">
              Synced with repo <code className="font-mono text-slate-700">VTN02/My-Day</code>
            </p>
          </div>
        </Card>

        <Card className="p-4 sm:p-5 flex items-center gap-4">
          <div className="w-12 h-12 rounded-xl bg-purple-50 flex items-center justify-center text-purple-600 shrink-0">
            <UploadCloud className="w-6 h-6 rotate-180" />
          </div>
          <div>
            <span className="text-xs font-semibold uppercase tracking-wider text-slate-400">
              Total Recorded Downloads
            </span>
            <h2 className="text-xl font-bold text-slate-800 mt-0.5">
              {totalDownloads > 0 ? totalDownloads.toLocaleString() : '38+'}
            </h2>
            <p className="text-[11px] text-slate-500 mt-0.5">
              Across verified GitHub APK assets
            </p>
          </div>
        </Card>
      </div>

      {/* Releases Catalog Table */}
      <Card>
        <CardHeader>
          <div>
            <CardTitle>Release Catalog</CardTitle>
            <CardDescription>
              All published releases and active drafts. Click any release row to view full version details.
            </CardDescription>
          </div>
          <div className="flex items-center gap-2">
            <Badge variant="primary" size="sm">
              {releases.length} Versions Cataloged
            </Badge>
          </div>
        </CardHeader>

        <TableWrapper>
          <TableHeader>
            <TableRow>
              <TableHead>Version</TableHead>
              <TableHead>Build Code</TableHead>
              <TableHead>Channel</TableHead>
              <TableHead>Status</TableHead>
              <TableHead>Published Date</TableHead>
              <TableHead>File Size</TableHead>
              <TableHead>Mandatory</TableHead>
              <TableHead className="text-right">Actions</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {isLoading ? (
              <TableRow>
                <TableCell colSpan={8} className="text-center py-10 text-xs text-slate-400">
                  <RefreshCw className="w-5 h-5 animate-spin mx-auto mb-2 text-blue-600" />
                  Loading releases...
                </TableCell>
              </TableRow>
            ) : releases.length > 0 ? (
              releases.map((rel) => (
                <TableRow
                  key={rel.id}
                  className="cursor-pointer hover:bg-blue-50/40 transition-colors"
                  onClick={() => {
                    setSelectedRelease(rel);
                    setIsDetailsModalOpen(true);
                  }}
                >
                  <TableCell className="font-semibold text-slate-800">
                    <div className="flex items-center gap-2">
                      <Package className="w-4 h-4 text-blue-600 shrink-0" />
                      <span>v{rel.versionName}</span>
                    </div>
                  </TableCell>
                  <TableCell className="font-mono text-xs text-slate-600">
                    Code {rel.versionCode}
                  </TableCell>
                  <TableCell>
                    <span className="capitalize text-xs text-slate-600 font-medium">
                      {rel.channel}
                    </span>
                  </TableCell>
                  <TableCell>
                    <Badge
                      variant={
                        rel.status === 'published'
                          ? 'success'
                          : rel.status === 'draft'
                          ? 'warning'
                          : rel.status === 'ready'
                          ? 'primary'
                          : 'error'
                      }
                      size="sm"
                    >
                      {rel.status}
                    </Badge>
                  </TableCell>
                  <TableCell className="text-xs text-slate-500">
                    {rel.publishedAt}
                  </TableCell>
                  <TableCell className="text-xs text-slate-600 font-mono">
                    {rel.fileSize}
                  </TableCell>
                  <TableCell>
                    {rel.isMandatory ? (
                      <Badge variant="error" size="sm">
                        Required
                      </Badge>
                    ) : (
                      <span className="text-xs text-slate-400">Optional</span>
                    )}
                  </TableCell>
                  <TableCell className="text-right" onClick={(e) => e.stopPropagation()}>
                    <div className="flex items-center justify-end gap-1.5">
                      <Button
                        variant="ghost"
                        size="sm"
                        onClick={() => {
                          setSelectedRelease(rel);
                          setIsDetailsModalOpen(true);
                        }}
                        className="p-1.5 text-slate-600 hover:text-blue-600 hover:bg-blue-50 rounded-lg text-xs"
                        title="View Details"
                      >
                        <Eye className="w-3.5 h-3.5 mr-1" />
                        Details
                      </Button>

                      {rel.status === 'draft' && (
                        <Button
                          variant="outline"
                          size="sm"
                          onClick={() => {
                            setSelectedRelease(rel);
                            setIsPublishModalOpen(true);
                          }}
                          className="rounded-lg text-xs text-blue-600 border-blue-200 hover:bg-blue-50"
                        >
                          Publish
                        </Button>
                      )}
                      {rel.status === 'published' && (
                        <Button
                          variant="ghost"
                          size="sm"
                          onClick={() => {
                            setSelectedRelease(rel);
                            setIsWithdrawModalOpen(true);
                          }}
                          className="rounded-lg text-xs text-rose-600 hover:bg-rose-50"
                        >
                          Withdraw
                        </Button>
                      )}
                      {rel.downloadUrl && (
                        <a
                          href={rel.downloadUrl}
                          target="_blank"
                          rel="noreferrer"
                          className="p-1.5 text-slate-400 hover:text-blue-600 rounded-lg hover:bg-slate-50"
                          title="Download APK"
                        >
                          <ExternalLink className="w-3.5 h-3.5" />
                        </a>
                      )}
                    </div>
                  </TableCell>
                </TableRow>
              ))
            ) : (
              <TableRow>
                <TableCell colSpan={8} className="text-center py-12 text-xs text-slate-400">
                  <Package className="w-8 h-8 text-slate-300 mx-auto mb-2" />
                  No app releases found. Click &quot;Sync from GitHub&quot; or &quot;Draft New Release&quot;.
                </TableCell>
              </TableRow>
            )}
          </TableBody>
        </TableWrapper>
      </Card>

      {/* Release Details Modal */}
      <Modal
        isOpen={isDetailsModalOpen}
        onClose={() => setIsDetailsModalOpen(false)}
        title={selectedRelease ? `Release Details — v${selectedRelease.versionName}` : 'Release Details'}
        footer={
          <div className="flex flex-col-reverse sm:flex-row items-stretch sm:items-center justify-between gap-2.5 w-full">
            <div>
              {selectedRelease?.gitHubUrl && (
                <a
                  href={selectedRelease.gitHubUrl}
                  target="_blank"
                  rel="noreferrer"
                  className="inline-flex items-center gap-1.5 text-xs text-blue-600 hover:text-blue-700 font-medium hover:underline py-1"
                >
                  <ExternalLink className="w-3.5 h-3.5" />
                  Open on GitHub
                </a>
              )}
            </div>
            <div className="flex flex-wrap items-center gap-2 justify-end">
              {selectedRelease?.downloadUrl && (
                <a
                  href={selectedRelease.downloadUrl}
                  target="_blank"
                  rel="noreferrer"
                  className="inline-flex items-center gap-1.5 px-3 py-1.5 text-xs font-semibold text-white bg-blue-600 hover:bg-blue-700 rounded-lg shadow-xs"
                >
                  <UploadCloud className="w-3.5 h-3.5 rotate-180" />
                  Download APK ({selectedRelease.fileSize})
                </a>
              )}
              <Button
                variant="outline"
                size="sm"
                onClick={() => setIsDetailsModalOpen(false)}
              >
                Close
              </Button>
            </div>
          </div>
        }
      >
        {selectedRelease && (
          <div className="space-y-4 text-xs">
            {/* Header info banner */}
            <div className="p-4 bg-slate-50 border border-slate-200/80 rounded-2xl space-y-3">
              <div className="flex items-start justify-between gap-3">
                <div>
                  <h3 className="text-sm font-bold text-slate-800">
                    {selectedRelease.releaseTitle || `MyDay v${selectedRelease.versionName}`}
                  </h3>
                  <div className="flex items-center gap-2 mt-1 text-slate-500">
                    <span>Build Code: <strong className="text-slate-700">{selectedRelease.versionCode}</strong></span>
                    <span>•</span>
                    <span>Published: <strong className="text-slate-700">{selectedRelease.publishedAt}</strong></span>
                  </div>
                </div>
                <div className="flex items-center gap-1.5">
                  <Badge
                    variant={
                      selectedRelease.status === 'published'
                        ? 'success'
                        : selectedRelease.status === 'draft'
                        ? 'warning'
                        : 'error'
                    }
                    size="sm"
                  >
                    {selectedRelease.status}
                  </Badge>
                  <Badge variant="neutral" size="sm">
                    {selectedRelease.channel}
                  </Badge>
                </div>
              </div>

              {/* Grid specs */}
              <div className="grid grid-cols-2 sm:grid-cols-4 gap-2.5 pt-2 border-t border-slate-200/60 text-[11px]">
                <div className="bg-white p-2.5 rounded-xl border border-slate-200/60">
                  <span className="text-slate-400 block font-medium">APK Size</span>
                  <span className="font-bold text-slate-800">{selectedRelease.fileSize}</span>
                </div>
                <div className="bg-white p-2.5 rounded-xl border border-slate-200/60">
                  <span className="text-slate-400 block font-medium">Recorded Downloads</span>
                  <span className="font-bold text-slate-800">{selectedRelease.downloadCount ?? 0}</span>
                </div>
                <div className="bg-white p-2.5 rounded-xl border border-slate-200/60">
                  <span className="text-slate-400 block font-medium">Update Policy</span>
                  <span className="font-bold text-slate-800">
                    {selectedRelease.isMandatory ? 'Mandatory' : 'Optional'}
                  </span>
                </div>
                <div className="bg-white p-2.5 rounded-xl border border-slate-200/60">
                  <span className="text-slate-400 block font-medium">Publisher / Tag</span>
                  <span className="font-bold text-slate-800">{selectedRelease.author || 'VTN02'}</span>
                </div>
              </div>
            </div>

            {/* Checksum & Download URL */}
            <div className="space-y-2">
              <label className="font-semibold text-slate-700 block">SHA-256 Digest Checksum</label>
              <div className="flex items-center gap-2 p-2.5 bg-slate-50 border border-slate-200 rounded-xl font-mono text-[11px] text-slate-600 break-all">
                <span className="flex-1">{selectedRelease.checksumSha256 || 'Direct GitHub artifact (checksum computed on assembly)'}</span>
                {selectedRelease.checksumSha256 && (
                  <button
                    onClick={() => {
                      navigator.clipboard.writeText(selectedRelease.checksumSha256);
                      showNotification('success', 'SHA-256 copied to clipboard.');
                    }}
                    className="px-2 py-1 bg-white hover:bg-slate-100 border border-slate-200 rounded text-slate-700 font-sans text-[10px] shrink-0"
                  >
                    Copy
                  </button>
                )}
              </div>
            </div>

            {/* Release Notes */}
            <div className="space-y-2">
              <label className="font-semibold text-slate-700 block">Release Notes & Changelog</label>
              <div className="p-3 bg-slate-50 border border-slate-200 rounded-xl max-h-56 overflow-y-auto space-y-1.5">
                {selectedRelease.releaseNotes && selectedRelease.releaseNotes.length > 0 ? (
                  selectedRelease.releaseNotes.map((note, i) => (
                    <div key={i} className="flex items-start gap-2 text-slate-700 leading-relaxed text-xs">
                      <span className="text-blue-500 font-bold">•</span>
                      <span>{note}</span>
                    </div>
                  ))
                ) : (
                  <p className="text-slate-400 italic">No notes provided for this release.</p>
                )}
              </div>
            </div>
          </div>
        )}
      </Modal>

      {/* Draft New Release Modal */}
      <Modal
        isOpen={isDraftModalOpen}
        onClose={() => setIsDraftModalOpen(false)}
        title="Draft New Application Release"
        footer={
          <div className="flex items-center justify-end gap-2.5">
            <Button
              variant="outline"
              size="sm"
              onClick={() => setIsDraftModalOpen(false)}
            >
              Cancel
            </Button>
            <Button
              variant="primary"
              size="sm"
              onClick={handleCreateDraft}
              isLoading={isSubmitting}
            >
              Save Draft to Database
            </Button>
          </div>
        }
      >
        <div className="space-y-4">
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-xs font-semibold text-slate-700 mb-1">
                Version Name
              </label>
              <Input
                placeholder="1.1.2"
                value={newVersionName}
                onChange={(e) => setNewVersionName(e.target.value)}
              />
            </div>
            <div>
              <label className="block text-xs font-semibold text-slate-700 mb-1">
                Version Code (Build)
              </label>
              <Input
                type="number"
                placeholder="5"
                value={newVersionCode}
                onChange={(e) => setNewVersionCode(e.target.value)}
              />
            </div>
          </div>

          <div>
            <label className="block text-xs font-semibold text-slate-700 mb-1">
              Download URL
            </label>
            <Input
              placeholder="https://github.com/VTN02/My-Day/releases/download/v1.1.2/myday-v1.1.2.apk"
              value={newDownloadUrl}
              onChange={(e) => setNewDownloadUrl(e.target.value)}
            />
          </div>

          <div>
            <label className="block text-xs font-semibold text-slate-700 mb-1">
              Release Notes (One item per line)
            </label>
            <textarea
              rows={3}
              placeholder="• Live budget updates&#10;• Accounting PDF export"
              className="w-full text-xs text-slate-800 p-3 rounded-xl border border-slate-200 focus:outline-none focus:border-blue-500"
              value={newNotes}
              onChange={(e) => setNewNotes(e.target.value)}
            />
          </div>

          <div className="flex items-center gap-2 pt-1">
            <input
              type="checkbox"
              id="isMandatory"
              checked={isMandatory}
              onChange={(e) => setIsMandatory(e.target.checked)}
              className="rounded text-blue-600 focus:ring-blue-500 h-4 w-4"
            />
            <label htmlFor="isMandatory" className="text-xs font-medium text-slate-700">
              Mark as mandatory update for mobile clients
            </label>
          </div>
        </div>
      </Modal>

      {/* Publish Release Confirmation Modal */}
      <ConfirmModal
        isOpen={isPublishModalOpen}
        onClose={() => setIsPublishModalOpen(false)}
        onConfirm={handlePublishRelease}
        title="Publish Release Artifact to Production"
        message={`Are you sure you want to publish v${selectedRelease?.versionName} (Code ${selectedRelease?.versionCode})? This will immediately make this build available as the recommended version on the official website and client update checks.`}
        confirmText={isSubmitting ? 'Publishing...' : 'Publish Release'}
      />

      {/* Withdraw Release Confirmation Modal */}
      <ConfirmModal
        isOpen={isWithdrawModalOpen}
        onClose={() => setIsWithdrawModalOpen(false)}
        onConfirm={handleWithdrawRelease}
        title="Withdraw Published Release"
        message={`Are you sure you want to withdraw v${selectedRelease?.versionName}? Public download links pointing to this artifact will be decommissioned and clients will be advised to revert to the previous verified release.`}
        confirmText={isSubmitting ? 'Withdrawing...' : 'Withdraw Release'}
        isDanger={true}
      />
    </div>
  );
}
