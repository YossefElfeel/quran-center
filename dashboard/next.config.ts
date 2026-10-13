import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  outputFileTracingIncludes: {"/certificates/*/pdf": ["./app/fonts/Cairo.ttf"]},
};

export default nextConfig;
