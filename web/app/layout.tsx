import type { Metadata, Viewport } from "next";
import "./globals.css";

export const viewport: Viewport = {
  width: "device-width",
  initialScale: 1,
  themeColor: [
    { media: "(prefers-color-scheme: light)", color: "#FFFFFF" },
    { media: "(prefers-color-scheme: dark)", color: "#0A0A0B" },
  ],
};

export const metadata: Metadata = {
  title: {
    default: "PoshGuard - PowerShell Code Quality Made Simple",
    template: "%s | PoshGuard",
  },
  description:
    "Automatically detect and fix security issues, best practices, and style violations in your PowerShell scripts. 98%+ fix rate with zero technical knowledge required.",
  keywords: [
    "PowerShell",
    "code quality",
    "security",
    "linter",
    "auto-fix",
    "static analysis",
    "best practices",
  ],
  authors: [{ name: "PoshGuard Team" }],
  creator: "PoshGuard",
  publisher: "PoshGuard",
  robots: {
    index: true,
    follow: true,
  },
  openGraph: {
    type: "website",
    locale: "en_US",
    url: "https://poshguard.dev",
    title: "PoshGuard - PowerShell Code Quality Made Simple",
    description:
      "Automatically detect and fix security issues in PowerShell scripts. 98%+ fix rate.",
    siteName: "PoshGuard",
  },
  twitter: {
    card: "summary_large_image",
    title: "PoshGuard - PowerShell Code Quality Made Simple",
    description:
      "Automatically detect and fix security issues in PowerShell scripts. 98%+ fix rate.",
  },
  icons: {
    icon: "/favicon.ico",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body className="antialiased">
        {children}
      </body>
    </html>
  );
}
