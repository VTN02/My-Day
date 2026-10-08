import type { Metadata } from 'next';
import React from 'react';

export const metadata: Metadata = {
  title: 'MyDay — Personal Life Management and Productivity Platform',
  description: 'Clean, intuitive, privacy-conscious and offline-first personal productivity platform.',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body className="bg-[#F7F8FC] text-[#0F172A] antialiased">
        {children}
      </body>
    </html>
  );
}
