import type { Metadata } from 'next';
import React from 'react';

export const metadata: Metadata = {
  title: 'MyDay Super Admin Console',
  description: 'Administrative management console for MyDay platform.',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body className="bg-[#0B1020] text-[#F1F5F9] antialiased">
        {children}
      </body>
    </html>
  );
}
