// Static export so the site can be hosted on GitHub Pages.
// Set NEXT_PUBLIC_BASE_PATH=/server-pulse when publishing to a project page.
const basePath = process.env.NEXT_PUBLIC_BASE_PATH || "";

/** @type {import('next').NextConfig} */
const nextConfig = {
  output: "export",
  basePath,
  images: { unoptimized: true },
  turbopack: { root: import.meta.dirname },
};

export default nextConfig;
