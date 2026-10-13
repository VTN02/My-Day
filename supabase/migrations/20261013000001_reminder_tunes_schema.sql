-- MyDay Platform — Reminder Tunes Catalog & Storage Schema
-- Migration: 20261013000001_reminder_tunes_schema.sql

-- 1. Create reminder_tunes table
CREATE TABLE IF NOT EXISTS public.reminder_tunes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  storage_path TEXT NOT NULL UNIQUE,
  file_size_bytes BIGINT NOT NULL DEFAULT 0,
  duration_seconds NUMERIC(5,2) NOT NULL DEFAULT 0,
  mime_type TEXT NOT NULL DEFAULT 'audio/mpeg',
  is_active BOOLEAN NOT NULL DEFAULT true,
  is_default BOOLEAN NOT NULL DEFAULT false,
  download_url TEXT NOT NULL,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Index for public mobile catalog retrieval
CREATE INDEX IF NOT EXISTS idx_reminder_tunes_active 
  ON public.reminder_tunes (is_active, is_default DESC);

CREATE INDEX IF NOT EXISTS idx_reminder_tunes_created_at 
  ON public.reminder_tunes (created_at DESC);

-- Enable RLS
ALTER TABLE public.reminder_tunes ENABLE ROW LEVEL SECURITY;

-- 2. Row Level Security Policies
-- Anonymous public read access for active tunes
DROP POLICY IF EXISTS "Public read for active tunes" ON public.reminder_tunes;
CREATE POLICY "Public read for active tunes"
  ON public.reminder_tunes FOR SELECT
  USING (is_active = true);

-- Admin-only full management
DROP POLICY IF EXISTS "Admins full management on reminder_tunes" ON public.reminder_tunes;
CREATE POLICY "Admins full management on reminder_tunes"
  ON public.reminder_tunes FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.admin_user_roles
      WHERE admin_user_roles.user_id = auth.uid()
        AND admin_user_roles.role IN ('super_admin', 'admin')
        AND admin_user_roles.is_active = true
    )
  );

-- 3. Storage Bucket Initialization (storage.buckets & storage.objects policies)
INSERT INTO storage.buckets (id, name, public)
VALUES ('reminder-tunes', 'reminder-tunes', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- Bucket read policy: public can download objects from reminder-tunes
DROP POLICY IF EXISTS "Public can view reminder-tunes objects" ON storage.objects;
CREATE POLICY "Public can view reminder-tunes objects"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'reminder-tunes');

-- Bucket upload policy: authenticated admins can upload
DROP POLICY IF EXISTS "Admins can upload reminder-tunes objects" ON storage.objects;
CREATE POLICY "Admins can upload reminder-tunes objects"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'reminder-tunes' AND
    EXISTS (
      SELECT 1 FROM public.admin_user_roles
      WHERE admin_user_roles.user_id = auth.uid()
        AND admin_user_roles.role IN ('super_admin', 'admin')
        AND admin_user_roles.is_active = true
    )
  );

-- Bucket delete policy: authenticated admins can delete
DROP POLICY IF EXISTS "Admins can delete reminder-tunes objects" ON storage.objects;
CREATE POLICY "Admins can delete reminder-tunes objects"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'reminder-tunes' AND
    EXISTS (
      SELECT 1 FROM public.admin_user_roles
      WHERE admin_user_roles.user_id = auth.uid()
        AND admin_user_roles.role IN ('super_admin', 'admin')
        AND admin_user_roles.is_active = true
    )
  );
