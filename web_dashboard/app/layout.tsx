import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";

const inter = Inter({ subsets: ["latin"] });

export const metadata: Metadata = {
  title: "Maps Dashboard - Professional Map Management",
  description: "Professional maps dashboard for managing your application. Track users, maps, analytics, and reports in one place.",
  keywords: ["maps", "dashboard", "analytics", "management", "reports"],
  authors: [{ name: "Maps App" }],
};

export const viewport = {
  width: "device-width",
  initialScale: 1,
  maximumScale: 1,
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body className={inter.className}>{children}</body>
    </html>
  );
}
