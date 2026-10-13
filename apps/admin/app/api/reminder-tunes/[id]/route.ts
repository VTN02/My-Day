import { NextRequest, NextResponse } from 'next/server';
import { createAdminServiceClient, isSupabaseConfigured } from '@/lib/supabase-server';
import { logAdminAction } from '@/lib/audit-logger';

export async function PATCH(
  req: NextRequest,
  { params }: { params: { id: string } }
) {
  if (!isSupabaseConfigured()) {
    return NextResponse.json(
      { error: 'Supabase credentials are not configured.' },
      { status: 503 }
    );
  }

  try {
    const { id } = params;
    const body = await req.json();
    const { is_active, is_default, name, description } = body;

    const supabase = createAdminServiceClient();

    // If making this tune default, unset other defaults
    if (is_default === true) {
      await supabase
        .from('reminder_tunes')
        .update({ is_default: false })
        .eq('is_default', true);
    }

    const updatePayload: Record<string, any> = {
      updated_at: new Date().toISOString(),
    };
    if (typeof is_active === 'boolean') updatePayload.is_active = is_active;
    if (typeof is_default === 'boolean') updatePayload.is_default = is_default;
    if (name) updatePayload.name = name.trim();
    if (description !== undefined) updatePayload.description = description.trim();

    const { data: updatedTune, error } = await supabase
      .from('reminder_tunes')
      .update(updatePayload)
      .eq('id', id)
      .select()
      .single();

    if (error) {
      return NextResponse.json({ error: error.message }, { status: 500 });
    }

    await logAdminAction({
      actorEmail: 'admin@myday.app',
      action: 'reminder_tune.update',
      targetType: 'reminder_tune',
      targetId: id,
      outcome: 'success',
      metadata: updatePayload,
    });

    return NextResponse.json({ success: true, tune: updatedTune });
  } catch (err: any) {
    return NextResponse.json(
      { error: err.message || 'Failed to update reminder tune.' },
      { status: 500 }
    );
  }
}

export async function DELETE(
  req: NextRequest,
  { params }: { params: { id: string } }
) {
  if (!isSupabaseConfigured()) {
    return NextResponse.json(
      { error: 'Supabase credentials are not configured.' },
      { status: 503 }
    );
  }

  try {
    const { id } = params;
    const supabase = createAdminServiceClient();

    // Retrieve storage path before deletion
    const { data: existingTune, error: fetchError } = await supabase
      .from('reminder_tunes')
      .select('*')
      .eq('id', id)
      .single();

    if (fetchError || !existingTune) {
      return NextResponse.json({ error: 'Tune not found.' }, { status: 404 });
    }

    if (existingTune.is_default) {
      return NextResponse.json(
        { error: 'Cannot delete the system recommended default tune. Designate another default first.' },
        { status: 400 }
      );
    }

    // Remove from storage
    if (existingTune.storage_path) {
      await supabase.storage
        .from('reminder-tunes')
        .remove([existingTune.storage_path]);
    }

    // Delete record from DB
    const { error: deleteError } = await supabase
      .from('reminder_tunes')
      .delete()
      .eq('id', id);

    if (deleteError) {
      return NextResponse.json({ error: deleteError.message }, { status: 500 });
    }

    await logAdminAction({
      actorEmail: 'admin@myday.app',
      action: 'reminder_tune.delete',
      targetType: 'reminder_tune',
      targetId: id,
      outcome: 'success',
      metadata: { name: existingTune.name, storagePath: existingTune.storage_path },
    });

    return NextResponse.json({ success: true });
  } catch (err: any) {
    return NextResponse.json(
      { error: err.message || 'Failed to delete reminder tune.' },
      { status: 500 }
    );
  }
}
