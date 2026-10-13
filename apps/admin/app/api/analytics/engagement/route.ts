import { NextRequest, NextResponse } from 'next/server';
import { getEngagementAnalytics } from '@/lib/analytics-service';

export async function GET(req: NextRequest) {
  const searchParams = req.nextUrl.searchParams;
  const days = parseInt(searchParams.get('days') || '30', 10);
  const data = getEngagementAnalytics(isNaN(days) ? 30 : days);
  return NextResponse.json(data);
}
