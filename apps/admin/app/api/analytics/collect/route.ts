import { NextRequest, NextResponse } from 'next/server';
import { validateAndIngestEvent } from '@/lib/analytics-service';

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();

    // Support single event or batch events
    const events = Array.isArray(body) ? body : [body];

    if (events.length > 50) {
      return NextResponse.json(
        { error: 'Batch exceeds maximum permitted payload limit (50 events)' },
        { status: 400 }
      );
    }

    for (const evt of events) {
      const result = validateAndIngestEvent(evt);
      if (!result.success) {
        return NextResponse.json(
          { error: result.error || 'Invalid event payload' },
          { status: 422 }
        );
      }
    }

    return NextResponse.json({ ok: true, processed: events.length }, { status: 200 });
  } catch (err: any) {
    return NextResponse.json(
      { error: 'Malformed JSON payload or invalid request' },
      { status: 400 }
    );
  }
}
