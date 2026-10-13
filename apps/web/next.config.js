/** @type {import('next').NextConfig} */
const nextConfig = {
  // Standalone output for Vercel serverless deployment
  output: 'standalone',

  eslint: {
    ignoreDuringBuilds: false,
  },
  typescript: {
    ignoreBuildErrors: false,
  },
};

module.exports = nextConfig;
