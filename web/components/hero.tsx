"use client";

import * as React from "react";
import { motion } from "framer-motion";
import { Button } from "./ui/button";

const containerVariants = {
  hidden: { opacity: 0 },
  visible: {
    opacity: 1,
    transition: {
      staggerChildren: 0.15,
      delayChildren: 0.1,
    },
  },
};

const itemVariants = {
  hidden: { opacity: 0, y: 30 },
  visible: {
    opacity: 1,
    y: 0,
    transition: {
      duration: 0.6,
      ease: [0.22, 1, 0.36, 1] as const,
    },
  },
};

export function Hero() {
  return (
    <section className="relative min-h-screen flex items-center justify-center overflow-hidden pt-20">
      {/* Gradient Mesh Background */}
      <div className="absolute inset-0 -z-10">
        {/* Gradient Orbs */}
        <div className="absolute top-0 left-1/4 w-96 h-96 bg-gradient-to-br from-[var(--gradient-from)] to-[var(--gradient-via)] rounded-full opacity-20 blur-3xl animate-float" />
        <div
          className="absolute bottom-0 right-1/4 w-96 h-96 bg-gradient-to-br from-[var(--gradient-via)] to-[var(--gradient-to)] rounded-full opacity-20 blur-3xl"
          style={{ animationDelay: "1s" }}
        />
        <div
          className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[600px] h-[600px] bg-gradient-to-br from-[var(--gradient-to)] to-[var(--gradient-from)] rounded-full opacity-10 blur-3xl"
          style={{ animationDelay: "2s" }}
        />
      </div>

      {/* Content */}
      <div className="container mx-auto px-4 py-20">
        <motion.div
          variants={containerVariants}
          initial="hidden"
          animate="visible"
          className="max-w-5xl mx-auto text-center"
        >
          {/* Badge */}
          <motion.div variants={itemVariants} className="mb-6">
            <span className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-[var(--bg-elevated)] border border-[var(--border-default)] text-sm font-medium text-[var(--text-secondary)] shadow-soft">
              <span className="relative flex h-2 w-2">
                <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-[var(--status-success)] opacity-75" />
                <span className="relative inline-flex rounded-full h-2 w-2 bg-[var(--status-success)]" />
              </span>
              Now with AI-powered fixes
            </span>
          </motion.div>

          {/* Headline */}
          <motion.h1
            variants={itemVariants}
            className="text-5xl sm:text-6xl lg:text-7xl font-bold mb-6 leading-tight"
            style={{
              fontSize: "clamp(2.5rem, 5vw + 1rem, 6rem)",
            }}
          >
            <span className="text-gradient">PowerShell Code Quality</span>
            <br />
            Made Simple
          </motion.h1>

          {/* Subheadline */}
          <motion.p
            variants={itemVariants}
            className="text-xl sm:text-2xl text-[var(--text-secondary)] mb-10 max-w-3xl mx-auto leading-relaxed"
            style={{
              fontSize: "clamp(1.125rem, 2vw + 0.5rem, 1.5rem)",
            }}
          >
            Automatically detect and fix security issues, best practices, and
            style violations in your PowerShell scripts.{" "}
            <span className="text-[var(--text-primary)] font-medium">
              98%+ fix rate
            </span>{" "}
            with zero technical knowledge required.
          </motion.p>

          {/* CTA Buttons */}
          <motion.div
            variants={itemVariants}
            className="flex flex-col sm:flex-row items-center justify-center gap-4 mb-12"
          >
            <Button size="lg" className="min-w-[200px]">
              Get Started Free
            </Button>
            <Button
              size="lg"
              variant="outline"
              className="min-w-[200px]"
              leftIcon={
                <svg
                  className="w-5 h-5"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                  aria-hidden="true"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M14.752 11.168l-3.197-2.132A1 1 0 0010 9.87v4.263a1 1 0 001.555.832l3.197-2.132a1 1 0 000-1.664z"
                  />
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                  />
                </svg>
              }
            >
              Watch Demo
            </Button>
          </motion.div>

          {/* Stats */}
          <motion.div
            variants={itemVariants}
            className="grid grid-cols-2 md:grid-cols-4 gap-8 max-w-4xl mx-auto"
          >
            <div className="text-center">
              <div className="text-3xl sm:text-4xl font-bold text-gradient mb-2">
                98%+
              </div>
              <div className="text-sm text-[var(--text-secondary)]">
                Fix Rate
              </div>
            </div>
            <div className="text-center">
              <div className="text-3xl sm:text-4xl font-bold text-gradient mb-2">
                107+
              </div>
              <div className="text-sm text-[var(--text-secondary)]">
                Detection Rules
              </div>
            </div>
            <div className="text-center">
              <div className="text-3xl sm:text-4xl font-bold text-gradient mb-2">
                25+
              </div>
              <div className="text-sm text-[var(--text-secondary)]">
                Standards
              </div>
            </div>
            <div className="text-center">
              <div className="text-3xl sm:text-4xl font-bold text-gradient mb-2">
                100%
              </div>
              <div className="text-sm text-[var(--text-secondary)]">
                Open Source
              </div>
            </div>
          </motion.div>
        </motion.div>
      </div>

      {/* Scroll Indicator */}
      <motion.div
        initial={{ opacity: 0, y: -10 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 1, duration: 0.5 }}
        className="absolute bottom-8 left-1/2 -translate-x-1/2"
      >
        <a
          href="#features"
          className="flex flex-col items-center gap-2 text-[var(--text-tertiary)] hover:text-[var(--interactive-primary)] transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--focus-ring)] rounded-lg p-2"
          aria-label="Scroll to features"
        >
          <span className="text-xs uppercase tracking-wider">Explore</span>
          <svg
            className="w-6 h-6 animate-bounce"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
            aria-hidden="true"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M19 14l-7 7m0 0l-7-7m7 7V3"
            />
          </svg>
        </a>
      </motion.div>
    </section>
  );
}
