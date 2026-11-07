import type { Metadata } from "next";
import localFont from "next/font/local";
import { DM_Mono } from "next/font/google";
import "./globals.css";
import { Providers } from "@/components/providers";
import { Navbar } from "@/components/navbar";
import { Footer } from "@/components/footer";
import { site } from "@/lib/site";

const interDisplay = localFont({
  src: [
    { path: "../fonts/InterDisplay-Regular.ttf", weight: "400" },
    { path: "../fonts/InterDisplay-Medium.ttf", weight: "500" },
    { path: "../fonts/InterDisplay-SemiBold.ttf", weight: "600" },
    { path: "../fonts/InterDisplay-Bold.ttf", weight: "700" },
  ],
  variable: "--font-inter-display",
  display: "swap",
});

const dmMono = DM_Mono({ subsets: ["latin"], weight: ["400", "500"], variable: "--font-dm-mono" });

export const metadata: Metadata = {
  metadataBase: new URL(site.url),
  title: "ServerPulse · Your servers, one dot away",
  description: site.description,
  icons: { icon: `${process.env.NEXT_PUBLIC_BASE_PATH ?? ""}/logo/logo-stack.svg` },
  openGraph: { title: "ServerPulse", description: site.description, url: site.url, type: "website" },
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" suppressHydrationWarning className={`${interDisplay.variable} ${dmMono.variable}`}>
      <body className="font-primary bg-white text-neutral-900 antialiased dark:bg-black dark:text-neutral-100">
        <Providers>
          <Navbar />
          {children}
          <Footer />
        </Providers>
      </body>
    </html>
  );
}
