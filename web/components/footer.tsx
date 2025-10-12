"use client";

import * as React from "react";
import { Button } from "./ui/button";
import { Input } from "./ui/input";

export function Footer() {
  const [email, setEmail] = React.useState("");
  const [loading, setLoading] = React.useState(false);
  const [success, setSuccess] = React.useState(false);
  const [error, setError] = React.useState("");

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError("");
    setLoading(true);

    // Email validation
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      setError("Please enter a valid email address");
      setLoading(false);
      return;
    }

    // Simulate API call
    await new Promise((resolve) => setTimeout(resolve, 1000));

    setLoading(false);
    setSuccess(true);
    setEmail("");

    // Show confetti effect (reduced for accessibility)
    if (!window.matchMedia("(prefers-reduced-motion: reduce)").matches) {
      // Simple confetti effect
      const confettiCount = 30;
      for (let i = 0; i < confettiCount; i++) {
        createConfetti();
      }
    }

    // Reset success message after 3 seconds
    setTimeout(() => setSuccess(false), 3000);
  };

  const createConfetti = () => {
    const confetti = document.createElement("div");
    confetti.style.cssText = `
      position: fixed;
      width: 10px;
      height: 10px;
      background: hsl(${Math.random() * 360}, 70%, 60%);
      top: ${window.innerHeight / 2}px;
      left: ${window.innerWidth / 2}px;
      border-radius: 50%;
      pointer-events: none;
      z-index: 9999;
      animation: confettiFall ${1 + Math.random()}s ease-out forwards;
    `;

    const styleSheet = document.createElement("style");
    styleSheet.textContent = `
      @keyframes confettiFall {
        to {
          transform: translate(
            ${(Math.random() - 0.5) * 200}px,
            ${200 + Math.random() * 100}px
          ) rotate(${Math.random() * 360}deg);
          opacity: 0;
        }
      }
    `;

    document.head.appendChild(styleSheet);
    document.body.appendChild(confetti);

    setTimeout(() => {
      confetti.remove();
      styleSheet.remove();
    }, 2000);
  };

  const currentYear = new Date().getFullYear();

  return (
    <footer className="bg-[var(--bg-surface)] border-t border-[var(--border-default)]">
      <div className="container mx-auto px-4 py-16">
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-12 mb-12">
          {/* Brand */}
          <div>
            <div className="flex items-center gap-2 mb-4">
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
                  fill="url(#footer-logo-gradient)"
                />
                <path
                  d="M16 8L24 12V20L16 24L8 20V12L16 8Z"
                  stroke="white"
                  strokeWidth="2"
                  strokeLinejoin="round"
                />
                <defs>
                  <linearGradient
                    id="footer-logo-gradient"
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
              <span className="text-xl font-bold">PoshGuard</span>
            </div>
            <p className="text-[var(--text-secondary)] text-sm mb-4">
              The world's best PowerShell code quality and security tool.
              98%+ fix rate with zero technical knowledge required.
            </p>
            <div className="flex gap-4">
              <a
                href="https://github.com/cboyd0319/PoshGuard"
                target="_blank"
                rel="noopener noreferrer"
                className="text-[var(--text-secondary)] hover:text-[var(--interactive-primary)] transition-colors"
                aria-label="GitHub"
              >
                <svg
                  className="w-6 h-6"
                  fill="currentColor"
                  viewBox="0 0 24 24"
                  aria-hidden="true"
                >
                  <path d="M12 2C6.477 2 2 6.484 2 12.017c0 4.425 2.865 8.18 6.839 9.504.5.092.682-.217.682-.483 0-.237-.008-.868-.013-1.703-2.782.605-3.369-1.343-3.369-1.343-.454-1.158-1.11-1.466-1.11-1.466-.908-.62.069-.608.069-.608 1.003.07 1.531 1.032 1.531 1.032.892 1.53 2.341 1.088 2.91.832.092-.647.35-1.088.636-1.338-2.22-.253-4.555-1.113-4.555-4.951 0-1.093.39-1.988 1.029-2.688-.103-.253-.446-1.272.098-2.65 0 0 .84-.27 2.75 1.026A9.564 9.564 0 0112 6.844c.85.004 1.705.115 2.504.337 1.909-1.296 2.747-1.027 2.747-1.027.546 1.379.202 2.398.1 2.651.64.7 1.028 1.595 1.028 2.688 0 3.848-2.339 4.695-4.566 4.943.359.309.678.92.678 1.855 0 1.338-.012 2.419-.012 2.747 0 .268.18.58.688.482A10.019 10.019 0 0022 12.017C22 6.484 17.522 2 12 2z" />
                </svg>
              </a>
            </div>
          </div>

          {/* Product */}
          <div>
            <h3 className="font-semibold mb-4 text-[var(--text-primary)]">
              Product
            </h3>
            <ul className="space-y-2">
              <li>
                <a
                  href="#features"
                  className="text-[var(--text-secondary)] hover:text-[var(--interactive-primary)] transition-colors text-sm"
                >
                  Features
                </a>
              </li>
              <li>
                <a
                  href="#pricing"
                  className="text-[var(--text-secondary)] hover:text-[var(--interactive-primary)] transition-colors text-sm"
                >
                  Pricing
                </a>
              </li>
              <li>
                <a
                  href="#"
                  className="text-[var(--text-secondary)] hover:text-[var(--interactive-primary)] transition-colors text-sm"
                >
                  Changelog
                </a>
              </li>
              <li>
                <a
                  href="#"
                  className="text-[var(--text-secondary)] hover:text-[var(--interactive-primary)] transition-colors text-sm"
                >
                  Roadmap
                </a>
              </li>
            </ul>
          </div>

          {/* Resources */}
          <div>
            <h3 className="font-semibold mb-4 text-[var(--text-primary)]">
              Resources
            </h3>
            <ul className="space-y-2">
              <li>
                <a
                  href="https://github.com/cboyd0319/PoshGuard"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-[var(--text-secondary)] hover:text-[var(--interactive-primary)] transition-colors text-sm"
                >
                  Documentation
                </a>
              </li>
              <li>
                <a
                  href="#"
                  className="text-[var(--text-secondary)] hover:text-[var(--interactive-primary)] transition-colors text-sm"
                >
                  Blog
                </a>
              </li>
              <li>
                <a
                  href="#"
                  className="text-[var(--text-secondary)] hover:text-[var(--interactive-primary)] transition-colors text-sm"
                >
                  Examples
                </a>
              </li>
              <li>
                <a
                  href="#"
                  className="text-[var(--text-secondary)] hover:text-[var(--interactive-primary)] transition-colors text-sm"
                >
                  Community
                </a>
              </li>
            </ul>
          </div>

          {/* Newsletter */}
          <div>
            <h3 className="font-semibold mb-4 text-[var(--text-primary)]">
              Stay Updated
            </h3>
            <p className="text-[var(--text-secondary)] text-sm mb-4">
              Get the latest updates and tips delivered to your inbox.
            </p>
            <form onSubmit={handleSubmit} className="space-y-3">
              <Input
                type="email"
                placeholder="Enter your email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                disabled={loading || success}
                error={error}
                aria-label="Email address"
              />
              <Button
                type="submit"
                size="sm"
                fullWidth
                loading={loading}
                disabled={success}
              >
                {success ? "✓ Subscribed!" : "Subscribe"}
              </Button>
            </form>
          </div>
        </div>

        {/* Bottom Bar */}
        <div className="pt-8 border-t border-[var(--border-default)] flex flex-col md:flex-row items-center justify-between gap-4">
          <p className="text-sm text-[var(--text-secondary)]">
            © {currentYear} PoshGuard. All rights reserved.
          </p>
          <div className="flex gap-6">
            <a
              href="#"
              className="text-sm text-[var(--text-secondary)] hover:text-[var(--interactive-primary)] transition-colors"
            >
              Privacy
            </a>
            <a
              href="#"
              className="text-sm text-[var(--text-secondary)] hover:text-[var(--interactive-primary)] transition-colors"
            >
              Terms
            </a>
            <a
              href="#"
              className="text-sm text-[var(--text-secondary)] hover:text-[var(--interactive-primary)] transition-colors"
            >
              Contact
            </a>
          </div>
        </div>
      </div>
    </footer>
  );
}
