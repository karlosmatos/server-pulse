"use client";
import { ThemeProvider } from "next-themes";
import { MotionConfig } from "motion/react";

export const Providers = ({ children }: { children: React.ReactNode }) => (
  <ThemeProvider attribute="class" defaultTheme="system" enableSystem>
    <MotionConfig reducedMotion="user">{children}</MotionConfig>
  </ThemeProvider>
);
