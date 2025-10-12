"use client";

import * as React from "react";
import { cn } from "@/lib/utils";
import { Button } from "./ui/button";

export function Navigation() {
  const [scrolled, setScrolled] = React.useState(false);

  React.useEffect(() => {
    const handleScroll = () => {
      setScrolled(window.scrollY > 20);
    };

    window.addEventListener("scroll", handleScroll, { passive: true });
    return () => window.removeEventListener("scroll", handleScroll);
  }, []);

  return (
    <nav
      className={cn(
        "fixed top-0 left-0 right-0 z-50 transition-all duration-300",
        scrolled
          ? "bg-[var(--bg-surface)]/80 backdrop-blur-lg shadow-md h-16"
          : "bg-transparent h-20"
      )}
      role="navigation"
      aria-label="Main navigation"
    >
      <div className="container mx-auto px-4 h-full">
        <div className="flex items-center justify-between h-full">
          {/* Logo */}
          <a
            href="#"
            className="flex items-center gap-2 text-xl font-bold text-gradient focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--focus-ring)] rounded-lg"
          >
            <svg
              className="w-8 h-8"
              viewBox="0 0 32 32"
              fill="none"
              xmlns="http://www.w3.org/2000/svg"
              aria-hidden="true"
            >
              <rect
                width="32"
                height="32"
                rx="8"
                fill="url(#logo-gradient)"
              />
              <path
                d="M16 8L24 12V20L16 24L8 20V12L16 8Z"
                stroke="white"
                strokeWidth="2"
                strokeLinejoin="round"
              />
              <defs>
                <linearGradient
                  id="logo-gradient"
                  x1="0"
                  y1="0"
                  x2="32"
                  y2="32"
                  gradientUnits="userSpaceOnUse"
                >
                  <stop stopColor="#6366F1" />
                  <stop offset="0.5" stopColor="#8B5CF6" />
                  <stop offset="1" stopColor="#EC4899" />
                </linearGradient>
              </defs>
            </svg>
            <span>PoshGuard</span>
          </a>

          {/* Desktop Navigation */}
          <ul className="hidden md:flex items-center gap-8">
            <li>
              <a
                href="#features"
                className="text-[var(--text-secondary)] hover:text-[var(--interactive-primary)] transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--focus-ring)] rounded px-2 py-1"
              >
                Features
              </a>
            </li>
            <li>
              <a
                href="#testimonials"
                className="text-[var(--text-secondary)] hover:text-[var(--interactive-primary)] transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--focus-ring)] rounded px-2 py-1"
              >
                Testimonials
              </a>
            </li>
            <li>
              <a
                href="#pricing"
                className="text-[var(--text-secondary)] hover:text-[var(--interactive-primary)] transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--focus-ring)] rounded px-2 py-1"
              >
                Pricing
              </a>
            </li>
            <li>
              <a
                href="https://github.com/cboyd0319/PoshGuard"
                target="_blank"
                rel="noopener noreferrer"
                className="text-[var(--text-secondary)] hover:text-[var(--interactive-primary)] transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--focus-ring)] rounded px-2 py-1"
              >
                Docs
              </a>
            </li>
          </ul>

          {/* CTA Buttons */}
          <div className="flex items-center gap-3">
            <Button variant="ghost" className="hidden sm:inline-flex">
              Sign In
            </Button>
            <Button>Get Started</Button>
          </div>
        </div>
      </div>
    </nav>
  );
}
