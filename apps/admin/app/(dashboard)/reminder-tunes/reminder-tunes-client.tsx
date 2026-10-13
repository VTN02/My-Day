'use client';

import React, { useState, useRef } from 'react';
import {
  Music,
  Upload,
  Play,
  Pause,
  Trash2,
  CheckCircle2,
  Star,
  Search,
  Filter,
  AlertCircle,
  FileAudio,
  Radio,
  Clock,
  HardDrive,
  Volume2,
} from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Modal } from '@/components/ui/modal';
import { Input } from '@/components/ui/input';
import { EmptyState } from '@/components/ui/empty-state';

export interface ReminderTune {
  id: string;
  name: string;
  description: string | null;
  storage_path: string;
  file_size_bytes: number;
  duration_seconds: number;
  mime_type: string;
  is_active: boolean;
  is_default: boolean;
  download_url: string;
  created_at: string;
  updated_at: string;
}

interface ReminderTunesClientProps {
  initialTunes: ReminderTune[];
  isNotConfigured?: boolean;
}

export function ReminderTunesClient({ initialTunes, isNotConfigured = false }: ReminderTunesClientProps) {
  const [tunes, setTunes] = useState<ReminderTune[]>(initialTunes);
  const [searchQuery, setSearchQuery] = useState('');
  const [filterActive, setFilterActive] = useState<'all' | 'active' | 'inactive'>('all');

  // Audio Playback State
  const [playingTuneId, setPlayingTuneId] = useState<string | null>(null);
  const audioRef = useRef<HTMLAudioElement | null>(null);

  // Upload Modal State
  const [isUploadOpen, setIsUploadOpen] = useState(false);
  const [uploadFile, setUploadFile] = useState<File | null>(null);
  const [uploadName, setUploadName] = useState('');
  const [uploadDescription, setUploadDescription] = useState('');
  const [uploadIsActive, setUploadIsActive] = useState(true);
  const [uploadIsDefault, setUploadIsDefault] = useState(false);
  const [uploadError, setUploadError] = useState<string | null>(null);
  const [isUploading, setIsUploading] = useState(false);

  // Delete Confirmation Modal State
  const [deletingTune, setDeletingTune] = useState<ReminderTune | null>(null);
  const [isDeleting, setIsDeleting] = useState(false);

  // Action Loading State
  const [loadingActionId, setLoadingActionId] = useState<string | null>(null);

  const handlePlayPause = (tune: ReminderTune) => {
    if (playingTuneId === tune.id) {
      if (audioRef.current) {
        audioRef.current.pause();
      }
      setPlayingTuneId(null);
    } else {
      if (audioRef.current) {
        audioRef.current.pause();
      }
      audioRef.current = new Audio(tune.download_url);
      audioRef.current.play().catch((e) => console.error('Audio playback error', e));
      audioRef.current.onended = () => setPlayingTuneId(null);
      setPlayingTuneId(tune.id);
    }
  };

  const handleToggleActive = async (tune: ReminderTune) => {
    setLoadingActionId(tune.id);
    try {
      const res = await fetch(`/api/reminder-tunes/${tune.id}`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ is_active: !tune.is_active }),
      });
      const data = await res.json();
      if (res.ok && data.tune) {
        setTunes((prev) =>
          prev.map((t) => (t.id === tune.id ? { ...t, is_active: !tune.is_active } : t))
        );
      } else {
        alert(data.error || 'Failed to update tune status.');
      }
    } catch (err: any) {
      alert(err.message || 'Network error.');
    } finally {
      setLoadingActionId(null);
    }
  };

  const handleSetDefault = async (tune: ReminderTune) => {
    if (tune.is_default) return;
    setLoadingActionId(tune.id);
    try {
      const res = await fetch(`/api/reminder-tunes/${tune.id}`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ is_default: true, is_active: true }),
      });
      const data = await res.json();
      if (res.ok && data.tune) {
        setTunes((prev) =>
          prev.map((t) => ({
            ...t,
            is_default: t.id === tune.id,
            is_active: t.id === tune.id ? true : t.is_active,
          }))
        );
      } else {
        alert(data.error || 'Failed to set default tune.');
      }
    } catch (err: any) {
      alert(err.message || 'Network error.');
    } finally {
      setLoadingActionId(null);
    }
  };

  const handleDelete = async () => {
    if (!deletingTune) return;
    setIsDeleting(true);
    try {
      const res = await fetch(`/api/reminder-tunes/${deletingTune.id}`, {
        method: 'DELETE',
      });
      const data = await res.json();
      if (res.ok) {
        if (playingTuneId === deletingTune.id && audioRef.current) {
          audioRef.current.pause();
          setPlayingTuneId(null);
        }
        setTunes((prev) => prev.filter((t) => t.id !== deletingTune.id));
        setDeletingTune(null);
      } else {
        alert(data.error || 'Failed to delete tune.');
      }
    } catch (err: any) {
      alert(err.message || 'Network error.');
    } finally {
      setIsDeleting(false);
    }
  };

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      if (!file.name.toLowerCase().endsWith('.mp3')) {
        setUploadError('Only MP3 files are supported.');
        setUploadFile(null);
        return;
      }
      if (file.size > 5 * 1024 * 1024) {
        setUploadError('File exceeds 5 MB limit.');
        setUploadFile(null);
        return;
      }
      setUploadError(null);
      setUploadFile(file);
      if (!uploadName) {
        const cleanName = file.name.replace(/\.mp3$/i, '').replace(/[-_]/g, ' ');
        setUploadName(cleanName.charAt(0).toUpperCase() + cleanName.slice(1));
      }
    }
  };

  const handleUploadSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!uploadFile || !uploadName) {
      setUploadError('Please specify a title and select an MP3 file.');
      return;
    }

    setIsUploading(true);
    setUploadError(null);

    const formData = new FormData();
    formData.append('file', uploadFile);
    formData.append('name', uploadName);
    formData.append('description', uploadDescription);
    formData.append('is_active', String(uploadIsActive));
    formData.append('is_default', String(uploadIsDefault));

    try {
      const res = await fetch('/api/reminder-tunes', {
        method: 'POST',
        body: formData,
      });
      const data = await res.json();
      if (res.ok && data.tune) {
        setTunes((prev) => {
          if (uploadIsDefault) {
            return [data.tune, ...prev.map((t) => ({ ...t, is_default: false }))];
          }
          return [data.tune, ...prev];
        });
        setIsUploadOpen(false);
        setUploadFile(null);
        setUploadName('');
        setUploadDescription('');
        setUploadIsActive(true);
        setUploadIsDefault(false);
      } else {
        setUploadError(data.error || 'Upload failed.');
      }
    } catch (err: any) {
      setUploadError(err.message || 'Network error during upload.');
    } finally {
      setIsUploading(false);
    }
  };

  // KPIs
  const totalTunes = tunes.length;
  const activeTunes = tunes.filter((t) => t.is_active).length;
  const defaultTune = tunes.find((t) => t.is_default);
  const totalStorageBytes = tunes.reduce((acc, t) => acc + (t.file_size_bytes || 0), 0);
  const totalStorageFormatted = (totalStorageBytes / (1024 * 1024)).toFixed(2) + ' MB';

  // Filtered List
  const filteredTunes = tunes.filter((t) => {
    const matchesSearch =
      t.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      (t.description && t.description.toLowerCase().includes(searchQuery.toLowerCase()));
    const matchesActive =
      filterActive === 'all'
        ? true
        : filterActive === 'active'
        ? t.is_active
        : !t.is_active;
    return matchesSearch && matchesActive;
  });

  const formatFileSize = (bytes: number) => {
    if (bytes < 1024 * 1024) {
      return (bytes / 1024).toFixed(1) + ' KB';
    }
    return (bytes / (1024 * 1024)).toFixed(2) + ' MB';
  };

  return (
    <div className="space-y-6">
      {/* Unconfigured Alert Banner */}
      {isNotConfigured && (
        <div className="p-4 bg-amber-50 border border-amber-200 rounded-xl flex items-start gap-3 shadow-sm">
          <AlertCircle className="w-5 h-5 text-amber-600 mt-0.5 shrink-0" />
          <div className="space-y-1">
            <h3 className="text-sm font-semibold text-amber-900">
              Supabase Connection Not Configured
            </h3>
            <p className="text-xs text-amber-700 leading-relaxed">
              To upload, manage, and distribute reminder tunes to mobile devices, add your Supabase credentials in{' '}
              <code className="bg-amber-100/80 px-1.5 py-0.5 rounded text-amber-900 font-mono text-[11px]">
                apps/admin/.env.local
              </code>
              : <code className="bg-amber-100/80 px-1.5 py-0.5 rounded text-amber-900 font-mono text-[11px]">NEXT_PUBLIC_SUPABASE_URL</code> and{' '}
              <code className="bg-amber-100/80 px-1.5 py-0.5 rounded text-amber-900 font-mono text-[11px]">SUPABASE_SERVICE_ROLE_KEY</code>.
            </p>
          </div>
        </div>
      )}

      {/* Top Banner & Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold tracking-tight text-slate-900">
            Reminder Tunes Catalog
          </h1>
          <p className="text-sm text-slate-500 mt-1">
            Manage genuine MP3 audio tunes delivered to MyDay mobile users for smart task reminders.
          </p>
        </div>
        <Button
          onClick={() => setIsUploadOpen(true)}
          className="bg-blue-600 hover:bg-blue-700 text-white shadow-sm flex items-center gap-2"
        >
          <Upload className="w-4 h-4" />
          Upload New Tune
        </Button>
      </div>

      {/* KPI Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <Card className="p-4 bg-white border border-slate-200">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold uppercase text-slate-500 tracking-wider">
              Total Tunes
            </span>
            <div className="p-2 bg-blue-50 text-blue-600 rounded-lg">
              <Music className="w-4 h-4" />
            </div>
          </div>
          <div className="text-2xl font-bold text-slate-900 mt-2">{totalTunes}</div>
          <p className="text-xs text-slate-400 mt-1">Platform audio catalog</p>
        </Card>

        <Card className="p-4 bg-white border border-slate-200">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold uppercase text-slate-500 tracking-wider">
              Published & Active
            </span>
            <div className="p-2 bg-emerald-50 text-emerald-600 rounded-lg">
              <Radio className="w-4 h-4" />
            </div>
          </div>
          <div className="text-2xl font-bold text-slate-900 mt-2">{activeTunes}</div>
          <p className="text-xs text-slate-400 mt-1">Available to mobile devices</p>
        </Card>

        <Card className="p-4 bg-white border border-slate-200">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold uppercase text-slate-500 tracking-wider">
              Default Recommended
            </span>
            <div className="p-2 bg-amber-50 text-amber-600 rounded-lg">
              <Star className="w-4 h-4" />
            </div>
          </div>
          <div className="text-base font-bold text-slate-900 mt-2 truncate">
            {defaultTune ? defaultTune.name : 'System Default'}
          </div>
          <p className="text-xs text-slate-400 mt-1">Initial user assignment</p>
        </Card>

        <Card className="p-4 bg-white border border-slate-200">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold uppercase text-slate-500 tracking-wider">
              Storage Footprint
            </span>
            <div className="p-2 bg-purple-50 text-purple-600 rounded-lg">
              <HardDrive className="w-4 h-4" />
            </div>
          </div>
          <div className="text-2xl font-bold text-slate-900 mt-2">{totalStorageFormatted}</div>
          <p className="text-xs text-slate-400 mt-1">Supabase storage bucket</p>
        </Card>
      </div>

      {/* Filter and Search Bar */}
      <Card className="p-4 bg-white border border-slate-200">
        <div className="flex flex-col sm:flex-row gap-3 items-center justify-between">
          <div className="relative w-full sm:w-80">
            <Search className="absolute left-3 top-2.5 h-4 w-4 text-slate-400" />
            <Input
              placeholder="Search tunes by name..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="pl-9 text-sm"
            />
          </div>
          <div className="flex items-center gap-2 w-full sm:w-auto">
            <Filter className="w-4 h-4 text-slate-400" />
            <div className="flex rounded-lg border border-slate-200 p-0.5 bg-slate-50 text-xs font-medium">
              <button
                onClick={() => setFilterActive('all')}
                className={`px-3 py-1.5 rounded-md transition ${
                  filterActive === 'all'
                    ? 'bg-white text-slate-900 shadow-sm'
                    : 'text-slate-500 hover:text-slate-900'
                }`}
              >
                All ({tunes.length})
              </button>
              <button
                onClick={() => setFilterActive('active')}
                className={`px-3 py-1.5 rounded-md transition ${
                  filterActive === 'active'
                    ? 'bg-white text-slate-900 shadow-sm'
                    : 'text-slate-500 hover:text-slate-900'
                }`}
              >
                Active ({activeTunes})
              </button>
              <button
                onClick={() => setFilterActive('inactive')}
                className={`px-3 py-1.5 rounded-md transition ${
                  filterActive === 'inactive'
                    ? 'bg-white text-slate-900 shadow-sm'
                    : 'text-slate-500 hover:text-slate-900'
                }`}
              >
                Inactive ({tunes.length - activeTunes})
              </button>
            </div>
          </div>
        </div>
      </Card>

      {/* Tunes Table */}
      <Card className="bg-white border border-slate-200 overflow-hidden">
        {filteredTunes.length === 0 ? (
          <div className="py-12">
            <EmptyState
              icon={<FileAudio className="w-6 h-6" />}
              title="No reminder tunes found"
              description={
                tunes.length === 0
                  ? 'No reminder tunes have been uploaded yet. Upload your first MP3 tune to populate the catalog.'
                  : 'No tunes match your search criteria.'
              }
              actionText={tunes.length === 0 ? 'Upload Tune' : undefined}
              onAction={tunes.length === 0 ? () => setIsUploadOpen(true) : undefined}
            />
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm">
              <thead className="bg-slate-50 border-b border-slate-200 text-xs uppercase font-semibold text-slate-500">
                <tr>
                  <th className="px-5 py-3">Play</th>
                  <th className="px-5 py-3">Tune Name & Description</th>
                  <th className="px-5 py-3">Duration</th>
                  <th className="px-5 py-3">Size</th>
                  <th className="px-5 py-3">Catalog Status</th>
                  <th className="px-5 py-3">Default</th>
                  <th className="px-5 py-3 text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {filteredTunes.map((tune) => {
                  const isPlaying = playingTuneId === tune.id;
                  const isLoading = loadingActionId === tune.id;

                  return (
                    <tr
                      key={tune.id}
                      className="hover:bg-slate-50/80 transition-colors"
                    >
                      {/* Play Preview */}
                      <td className="px-5 py-4 w-12">
                        <button
                          onClick={() => handlePlayPause(tune)}
                          className={`w-9 h-9 rounded-full flex items-center justify-center transition shadow-sm ${
                            isPlaying
                              ? 'bg-blue-600 text-white animate-pulse'
                              : 'bg-slate-100 text-slate-700 hover:bg-blue-50 hover:text-blue-600'
                          }`}
                          title={isPlaying ? 'Pause audio' : 'Preview tune'}
                        >
                          {isPlaying ? (
                            <Pause className="w-4 h-4 fill-current" />
                          ) : (
                            <Play className="w-4 h-4 fill-current ml-0.5" />
                          )}
                        </button>
                      </td>

                      {/* Name & Description */}
                      <td className="px-5 py-4">
                        <div className="flex items-center gap-2">
                          <span className="font-semibold text-slate-900">
                            {tune.name}
                          </span>
                          {tune.is_default && (
                            <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] font-bold bg-amber-100 text-amber-800">
                              <Star className="w-3 h-3 fill-amber-500" />
                              RECOMMENDED
                            </span>
                          )}
                        </div>
                        {tune.description && (
                          <p className="text-xs text-slate-500 mt-0.5 max-w-md line-clamp-1">
                            {tune.description}
                          </p>
                        )}
                      </td>

                      {/* Duration */}
                      <td className="px-5 py-4 text-slate-600 font-mono text-xs">
                        <div className="flex items-center gap-1.5">
                          <Clock className="w-3.5 h-3.5 text-slate-400" />
                          {tune.duration_seconds}s
                        </div>
                      </td>

                      {/* File Size */}
                      <td className="px-5 py-4 text-slate-600 text-xs font-mono">
                        {formatFileSize(tune.file_size_bytes)}
                      </td>

                      {/* Active Status */}
                      <td className="px-5 py-4">
                        <button
                          onClick={() => handleToggleActive(tune)}
                          disabled={isLoading}
                          className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium cursor-pointer transition ${
                            tune.is_active
                              ? 'bg-emerald-50 text-emerald-700 hover:bg-emerald-100'
                              : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
                          }`}
                        >
                          <span
                            className={`w-1.5 h-1.5 rounded-full ${
                              tune.is_active ? 'bg-emerald-500' : 'bg-slate-400'
                            }`}
                          />
                          {tune.is_active ? 'Published' : 'Draft'}
                        </button>
                      </td>

                      {/* Set as Default */}
                      <td className="px-5 py-4">
                        {tune.is_default ? (
                          <Badge variant="warning">
                            Default
                          </Badge>
                        ) : (
                          <button
                            onClick={() => handleSetDefault(tune)}
                            disabled={isLoading}
                            className="text-xs text-slate-500 hover:text-blue-600 font-medium underline-offset-2 hover:underline"
                          >
                            Set Default
                          </button>
                        )}
                      </td>

                      {/* Actions */}
                      <td className="px-5 py-4 text-right">
                        <button
                          onClick={() => setDeletingTune(tune)}
                          className="p-1.5 rounded-lg text-slate-400 hover:text-red-600 hover:bg-red-50 transition"
                          title="Delete tune"
                        >
                          <Trash2 className="w-4 h-4" />
                        </button>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}
      </Card>

      {/* Upload Tune Modal */}
      <Modal
        isOpen={isUploadOpen}
        onClose={() => !isUploading && setIsUploadOpen(false)}
        title="Upload Reminder Tune"
        description="Add a new MP3 audio notification to the MyDay catalog. Max 5 MB, max 30s recommended."
      >
        <form onSubmit={handleUploadSubmit} className="space-y-4 mt-2">
          {uploadError && (
            <div className="p-3 bg-red-50 border border-red-200 rounded-lg flex items-center gap-2 text-xs text-red-700">
              <AlertCircle className="w-4 h-4 shrink-0" />
              <span>{uploadError}</span>
            </div>
          )}

          {/* File Picker */}
          <div>
            <label className="block text-xs font-semibold uppercase tracking-wider text-slate-700 mb-1.5">
              MP3 Audio File *
            </label>
            <div className="border-2 border-dashed border-slate-300 rounded-lg p-5 text-center hover:border-blue-500 transition cursor-pointer relative bg-slate-50/50">
              <input
                type="file"
                accept=".mp3,audio/mpeg"
                onChange={handleFileChange}
                disabled={isUploading}
                className="absolute inset-0 w-full h-full opacity-0 cursor-pointer"
              />
              <FileAudio className="w-8 h-8 mx-auto text-blue-500 mb-2" />
              {uploadFile ? (
                <div>
                  <p className="text-sm font-semibold text-slate-900">{uploadFile.name}</p>
                  <p className="text-xs text-slate-500 mt-0.5 font-mono">
                    {formatFileSize(uploadFile.size)}
                  </p>
                </div>
              ) : (
                <div>
                  <p className="text-sm font-medium text-slate-700">
                    Click to browse or drop an MP3 file
                  </p>
                  <p className="text-xs text-slate-400 mt-1">Accepts audio/mpeg up to 5 MB</p>
                </div>
              )}
            </div>
          </div>

          {/* Name */}
          <div>
            <label className="block text-xs font-semibold uppercase tracking-wider text-slate-700 mb-1">
              Tune Name *
            </label>
            <Input
              placeholder="e.g. Gentle Morning Chime"
              value={uploadName}
              onChange={(e) => setUploadName(e.target.value)}
              disabled={isUploading}
              required
            />
          </div>

          {/* Description */}
          <div>
            <label className="block text-xs font-semibold uppercase tracking-wider text-slate-700 mb-1">
              Description (Optional)
            </label>
            <textarea
              placeholder="Short note about the melody style, instruments, or ideal tasks..."
              value={uploadDescription}
              onChange={(e) => setUploadDescription(e.target.value)}
              disabled={isUploading}
              rows={2}
              className="w-full text-sm rounded-lg border border-slate-300 p-2.5 focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500 text-slate-900"
            />
          </div>

          {/* Switches */}
          <div className="space-y-3 pt-1 border-t border-slate-100">
            <label className="flex items-center gap-3 cursor-pointer">
              <input
                type="checkbox"
                checked={uploadIsActive}
                onChange={(e) => setUploadIsActive(e.target.checked)}
                disabled={isUploading}
                className="w-4 h-4 text-blue-600 rounded border-slate-300 focus:ring-blue-500"
              />
              <div>
                <span className="text-sm font-medium text-slate-800">Publish Immediately</span>
                <p className="text-xs text-slate-400">Available to mobile users upon next catalog refresh</p>
              </div>
            </label>

            <label className="flex items-center gap-3 cursor-pointer">
              <input
                type="checkbox"
                checked={uploadIsDefault}
                onChange={(e) => setUploadIsDefault(e.target.checked)}
                disabled={isUploading}
                className="w-4 h-4 text-amber-500 rounded border-slate-300 focus:ring-amber-500"
              />
              <div>
                <span className="text-sm font-medium text-slate-800">
                  Set as Recommended Default
                </span>
                <p className="text-xs text-slate-400">Becomes the highlighted tune for new users</p>
              </div>
            </label>
          </div>

          {/* Footer Buttons */}
          <div className="flex justify-end gap-2 pt-4 border-t border-slate-100">
            <Button
              type="button"
              variant="outline"
              onClick={() => setIsUploadOpen(false)}
              disabled={isUploading}
            >
              Cancel
            </Button>
            <Button
              type="submit"
              disabled={isUploading || !uploadFile}
              className="bg-blue-600 hover:bg-blue-700 text-white"
            >
              {isUploading ? 'Uploading MP3...' : 'Upload & Publish'}
            </Button>
          </div>
        </form>
      </Modal>

      {/* Delete Confirmation Modal */}
      <Modal
        isOpen={Boolean(deletingTune)}
        onClose={() => !isDeleting && setDeletingTune(null)}
        title="Delete Reminder Tune"
        description="Are you sure you want to delete this reminder tune from the catalog?"
      >
        <div className="space-y-4 mt-2">
          <p className="text-sm text-slate-600">
            Deleting <strong className="text-slate-900">{deletingTune?.name}</strong> will remove the audio
            file from storage and make it unavailable for future mobile downloads. Existing offline copies
            on user devices will continue to function normally.
          </p>
          <div className="flex justify-end gap-2 pt-4 border-t border-slate-100">
            <Button
              variant="outline"
              onClick={() => setDeletingTune(null)}
              disabled={isDeleting}
            >
              Cancel
            </Button>
            <Button
              onClick={handleDelete}
              disabled={isDeleting}
              className="bg-red-600 hover:bg-red-700 text-white"
            >
              {isDeleting ? 'Deleting...' : 'Confirm Delete'}
            </Button>
          </div>
        </div>
      </Modal>
    </div>
  );
}
