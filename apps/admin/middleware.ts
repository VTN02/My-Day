import { NextResponse, type NextRequest } from 'next/server';

export async function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl;

  // Only protect admin dashboard and privileged API routes
  const isDashboardRoute =
    pathname.startsWith('/dashboard') ||
    pathname.startsWith('/users') ||
    pathname.startsWith('/releases') ||
    pathname.startsWith('/analytics') ||
    pathname.startsWith('/system-health') ||
    pathname.startsWith('/audit-logs') ||
    pathname.startsWith('/settings') ||
    pathname.startsWith('/profile');

  if (!isDashboardRoute) {
    return NextResponse.next();
  }

  // Check for presence of Supabase auth cookie
  // Standard Supabase SSR cookies usually start with 'sb-'
  const hasAuthCookie = request.cookies
    .getAll()
    .some((cookie) => cookie.name.startsWith('sb-') && cookie.name.endsWith('-auth-token'));

  // In production with Supabase configured, require authentication
  const isSupabaseConfigured = Boolean(
    process.env.NEXT_PUBLIC_SUPABASE_URL &&
    process.env.SUPABASE_SERVICE_ROLE_KEY &&
    !process.env.SUPABASE_SERVICE_ROLE_KEY.includes('dummy')
  );

  if (isSupabaseConfigured && !hasAuthCookie) {
    const loginUrl = new URL('/login', request.url);
    loginUrl.searchParams.set('redirect', pathname);
    return NextResponse.redirect(loginUrl);
  }

  return NextResponse.next();
}

export const config = {
  matcher: [
    '/dashboard/:path*',
    '/users/:path*',
    '/releases/:path*',
    '/analytics/:path*',
    '/system-health/:path*',
    '/audit-logs/:path*',
    '/settings/:path*',
    '/profile/:path*',
  ],
};
