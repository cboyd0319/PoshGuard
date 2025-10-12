"use client";

import * as React from "react";
import { motion } from "framer-motion";
import { Button } from "./ui/button";

export function CTA() {
  return (
    <section className="py-24 bg-[var(--bg-elevated)] relative overflow-hidden">
      {/* Background Effects */}
      <div className="absolute inset-0 -z-10">
        <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-full h-full max-w-4xl">
          <div
            className="absolute inset-0 opacity-30 blur-3xl"
            style={{
              background:
                "radial-gradient(circle, var(--gradient-from) 0%, var(--gradient-via) 50%, var(--gradient-to) 100%)",
            }}
          />
        </div>
      </div>

      <div className="container mx-auto px-4">
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6 }}
          className="relative"
        >
          {/* Main Card */}
          <div className="relative max-w-5xl mx-auto">
            <div
              className="absolute inset-0 rounded-3xl blur-xl opacity-50"
              style={{
                background:
                  "linear-gradient(135deg, var(--gradient-from), var(--gradient-via), var(--gradient-to))",
              }}
            />

            <div className="relative bg-[var(--bg-surface)] rounded-3xl shadow-2xl border border-[var(--border-default)] overflow-hidden">
              <div className="p-8 md:p-16 text-center">
                {/* Icon */}
                <motion.div
                  initial={{ scale: 0 }}
                  whileInView={{ scale: 1 }}
                  viewport={{ once: true }}
                  transition={{
                    type: "spring",
                    stiffness: 200,
                    damping: 20,
                    delay: 0.2,
                  }}
                  className="inline-flex items-center justify-center w-20 h-20 rounded-2xl mb-8 shadow-lg"
                  style={{
                    background:
                      "linear-gradient(135deg, var(--gradient-from), var(--gradient-via))",
                  }}
                >
                  <svg
                    className="w-10 h-10 text-white"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                    aria-hidden="true"
                  >
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth={2}
                      d="M13 10V3L4 14h7v7l9-11h-7z"
                    />
                  </svg>
                </motion.div>

                {/* Headline */}
                <h2
                  className="text-4xl sm:text-5xl font-bold mb-6"
                  style={{ fontSize: "clamp(2rem, 4vw + 0.5rem, 3rem)" }}
                >
                  Ready to{" "}
                  <span className="text-gradient">Transform Your Code?</span>
                </h2>

                {/* Description */}
                <p
                  className="text-xl text-[var(--text-secondary)] mb-10 max-w-2xl mx-auto leading-relaxed"
                  style={{ fontSize: "clamp(1rem, 1.5vw + 0.5rem, 1.25rem)" }}
                >
                  Join thousands of developers using PoshGuard to write better,
                  safer PowerShell code. Start fixing issues in seconds.
                </p>

                {/* CTA Buttons */}
                <div className="flex flex-col sm:flex-row items-center justify-center gap-4">
                  <Button size="lg" className="min-w-[200px] shadow-lg">
                    Get Started Free
                  </Button>
                  <Button
                    size="lg"
                    variant="outline"
                    className="min-w-[200px]"
                  >
                    View Documentation
                  </Button>
                </div>

                {/* Trust Badges */}
                <div className="mt-12 pt-8 border-t border-[var(--border-default)]">
                  <div className="grid grid-cols-2 md:grid-cols-4 gap-6 items-center">
                    <div className="text-center">
                      <div className="text-2xl font-bold text-gradient mb-1">
                        98%+
                      </div>
                      <div className="text-xs text-[var(--text-tertiary)]">
                        Fix Success Rate
                      </div>
                    </div>
                    <div className="text-center">
                      <div className="text-2xl font-bold text-gradient mb-1">
                        &lt;3s
                      </div>
                      <div className="text-xs text-[var(--text-tertiary)]">
                        Processing Time
                      </div>
                    </div>
                    <div className="text-center">
                      <div className="text-2xl font-bold text-gradient mb-1">
                        25+
                      </div>
                      <div className="text-xs text-[var(--text-tertiary)]">
                        Standards Compliant
                      </div>
                    </div>
                    <div className="text-center">
                      <div className="text-2xl font-bold text-gradient mb-1">
                        100%
                      </div>
                      <div className="text-xs text-[var(--text-tertiary)]">
                        Free & Open Source
                      </div>
                    </div>
                  </div>
                </div>
              </div>

              {/* Decorative Elements */}
              <div className="absolute top-0 right-0 w-64 h-64 opacity-10 pointer-events-none">
                <svg
                  viewBox="0 0 200 200"
                  xmlns="http://www.w3.org/2000/svg"
                  aria-hidden="true"
                >
                  <path
                    fill="currentColor"
                    d="M44.7,-76.4C58.8,-69.2,71.8,-59.1,79.6,-45.8C87.4,-32.6,90,-16.3,88.5,-0.9C87,14.6,81.4,29.2,73.1,42.2C64.8,55.2,53.8,66.6,40.5,73.8C27.2,81,11.6,84,-4.3,81.3C-20.2,78.6,-40.4,70.2,-54.9,57.4C-69.4,44.6,-78.2,27.4,-81.1,9.1C-84,-9.2,-81,-28.6,-72.8,-44.2C-64.6,-59.8,-51.2,-71.6,-36.4,-78.5C-21.6,-85.4,-5.4,-87.4,9.2,-83.8C23.8,-80.2,30.6,-83.6,44.7,-76.4Z"
                    transform="translate(100 100)"
                    className="text-[var(--interactive-primary)]"
                  />
                </svg>
              </div>
            </div>
          </div>
        </motion.div>
      </div>
    </section>
  );
}
