import { NextRequest, NextResponse } from 'next/server';
import { createAdminServiceClient, isSupabaseConfigured } from '@/lib/supabase-server';
import { logAdminAction } from '@/lib/audit-logger';

// Magic bytes for MP3 file validation:
// 1. ID3v2 tag: "ID3" (0x49 0x44 0x33)
// 2. MP3 frame sync: 0xFF followed by 0xE0-0xFF (first 11 bits are 1)
function isValidMp3Buffer(buffer: Buffer): boolean {
  if (buffer.length < 4) return false;
  // Check ID3v2 tag
  if (buffer[0] === 0x49 && buffer[1] === 0x44 && buffer[2] === 0x33) {
    return true;
  }
  // Check MPEG-1/2 Audio Layer 3 frame sync header (0xFF, 0xFB, 0xF3, 0xF2, etc.)
  if (buffer[0] === 0xff && (buffer[1] & 0xe0) === 0xe0) {
    return true;
  }
  return false;
}

export async function GET() {
  if (!isSupabaseConfigured()) {
    return NextResponse.json({ tunes: [] });
  }

  try {
    const supabase = createAdminServiceClient();
    const { data: tunes, error } = await supabase
      .from('reminder_tunes')
      .select('*')
      .order('is_default', { ascending: false })
      .order('created_at', { ascending: false });

    if (error) {
      return NextResponse.json({ error: error.message }, { status: 500 });
    }

    return NextResponse.json({ tunes: tunes || [] });
  } catch (err: any) {
    return NextResponse.json({ error: err.message || 'Internal server error' }, { status: 500 });
  }
}

export async function POST(req: NextRequest) {
  if (!isSupabaseConfigured()) {
    return NextResponse.json(
      { error: 'Supabase credentials are not configured in apps/admin/.env.local' },
      { status: 503 }
    );
  }

  try {
    const formData = await req.formData();
    const file = formData.get('file') as File | null;
    const name = (formData.get('name') as string)?.trim();
    const description = (formData.get('description') as string)?.trim() || '';
    const isActive = formData.get('is_active') === 'true';
    const isDefault = formData.get('is_default') === 'true';

    if (!file || !name) {
      return NextResponse.json(
        { error: 'Audio file and tune name are required.' },
        { status: 400 }
      );
    }

    // 1. File size constraint (Max 5 MB)
    const MAX_SIZE_BYTES = 5 * 1024 * 1024;
    if (file.size > MAX_SIZE_BYTES) {
      return NextResponse.json(
        { error: 'File size exceeds 5 MB limit.' },
        { status: 400 }
      );
    }

    // 2. Format & content inspection (MP3 format and magic bytes)
    const arrayBuffer = await file.arrayBuffer();
    const buffer = Buffer.from(arrayBuffer);

    if (!isValidMp3Buffer(buffer)) {
      return NextResponse.json(
        { error: 'Invalid audio file format. Only valid MP3 audio files are permitted.' },
        { status: 400 }
      );
    }

    const supabase = createAdminServiceClient();

    // 3. Generate secure storage path
    const sanitizedFileName = file.name.replace(/[^a-zA-Z0-9._-]/g, '_');
    const storagePath = `tunes/${Date.now()}-${sanitizedFileName}`;

    // Upload to Supabase Storage bucket 'reminder-tunes'
    const { error: uploadError } = await supabase.storage
      .from('reminder-tunes')
      .upload(storagePath, buffer, {
        contentType: 'audio/mpeg',
        upsert: true,
      });

    if (uploadError) {
      return NextResponse.json(
        { error: `Storage upload failed: ${uploadError.message}` },
        { status: 500 }
      );
    }

    // Retrieve public download URL
    const { data: urlData } = supabase.storage
      .from('reminder-tunes')
      .getPublicUrl(storagePath);

    const downloadUrl = urlData.publicUrl;

    // Estimate duration from file size and typical 128kbps bitrate
    const estimatedDuration = Math.min(30, Math.max(3, Math.round((buffer.length / 16000) * 10) / 10));

    // If marked default, unset existing defaults first
    if (isDefault) {
      await supabase
        .from('reminder_tunes')
        .update({ is_default: false })
        .eq('is_default', true);
    }

    // Insert record into PostgreSQL reminder_tunes table
    const { data: insertedTune, error: insertError } = await supabase
      .from('reminder_tunes')
      .insert({
        name,
        description,
        storage_path: storagePath,
        file_size_bytes: file.size,
        duration_seconds: estimatedDuration,
        mime_type: 'audio/mpeg',
        is_active: isActive,
        is_default: isDefault,
        download_url: downloadUrl,
      })
      .select()
      .single();

    if (insertError) {
      return NextResponse.json(
        { error: `Database insert failed: ${insertError.message}` },
        { status: 500 }
      );
    }

    // Append-only audit logging
    await logAdminAction({
      actorEmail: 'admin@myday.app',
      action: 'reminder_tune.upload',
      targetType: 'reminder_tune',
      targetId: insertedTune.id,
      outcome: 'success',
      metadata: {
        name,
        storagePath,
        fileSizeBytes: file.size,
        isDefault,
      },
    });

    return NextResponse.json({ success: true, tune: insertedTune });
  } catch (err: any) {
    return NextResponse.json(
      { error: err.message || 'Failed to process tune upload.' },
      { status: 500 }
    );
  }
}
