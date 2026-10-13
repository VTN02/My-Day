import { createAdminServiceClient, isSupabaseConfigured } from '@/lib/supabase-server';
import { ReminderTunesClient } from './reminder-tunes-client';

export const dynamic = 'force-dynamic';

export default async function ReminderTunesPage() {
  if (!isSupabaseConfigured()) {
    return <ReminderTunesClient initialTunes={[]} isNotConfigured={true} />;
  }

  try {
    const supabase = createAdminServiceClient();

    const { data: tunes, error } = await supabase
      .from('reminder_tunes')
      .select('*')
      .order('is_default', { ascending: false })
      .order('created_at', { ascending: false });

    if (error) {
      console.warn('[ReminderTunesPage] Error fetching tunes:', error.message);
      return <ReminderTunesClient initialTunes={[]} isNotConfigured={true} />;
    }

    return <ReminderTunesClient initialTunes={tunes || []} />;
  } catch (err) {
    console.warn('[ReminderTunesPage] Exception while connecting to Supabase:', err);
    return <ReminderTunesClient initialTunes={[]} isNotConfigured={true} />;
  }
}
