"use client";

import * as React from "react";
import { motion, useMotionValue, useSpring, useTransform } from "framer-motion";
import { Card, CardHeader, CardTitle, CardDescription } from "./ui/card";

interface Feature {
  icon: React.ReactNode;
  title: string;
  description: string;
  color: string;
}

const features: Feature[] = [
  {
    icon: (
      <svg
        className="w-8 h-8"
        fill="none"
        stroke="currentColor"
        viewBox="0 0 24 24"
      >
        <path
          strokeLinecap="round"
          strokeLinejoin="round"
          strokeWidth={2}
          d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"
        />
      </svg>
    ),
    title: "Security First",
    description:
      "Detect and fix security vulnerabilities automatically. OWASP ASVS Level 1 compliant with 25+ standards coverage.",
    color: "#10B981",
  },
  {
    icon: (
      <svg
        className="w-8 h-8"
        fill="none"
        stroke="currentColor"
        viewBox="0 0 24 24"
      >
        <path
          strokeLinecap="round"
          strokeLinejoin="round"
          strokeWidth={2}
          d="M13 10V3L4 14h7v7l9-11h-7z"
        />
      </svg>
    ),
    title: "Lightning Fast",
    description:
      "Process files in under 3 seconds. Optimized performance with parallel processing and smart caching.",
    color: "#F59E0B",
  },
  {
    icon: (
      <svg
        className="w-8 h-8"
        fill="none"
        stroke="currentColor"
        viewBox="0 0 24 24"
      >
        <path
          strokeLinecap="round"
          strokeLinejoin="round"
          strokeWidth={2}
          d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z"
        />
      </svg>
    ),
    title: "AI-Powered",
    description:
      "Reinforcement learning continuously improves fix quality. 98%+ success rate with confidence scoring.",
    color: "#6366F1",
  },
  {
    icon: (
      <svg
        className="w-8 h-8"
        fill="none"
        stroke="currentColor"
        viewBox="0 0 24 24"
      >
        <path
          strokeLinecap="round"
          strokeLinejoin="round"
          strokeWidth={2}
          d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"
        />
        <path
          strokeLinecap="round"
          strokeLinejoin="round"
          strokeWidth={2}
          d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"
        />
      </svg>
    ),
    title: "Preview Changes",
    description:
      "See exactly what will change before applying fixes. Automatic backups with one-click rollback.",
    color: "#3B82F6",
  },
  {
    icon: (
      <svg
        className="w-8 h-8"
        fill="none"
        stroke="currentColor"
        viewBox="0 0 24 24"
      >
        <path
          strokeLinecap="round"
          strokeLinejoin="round"
          strokeWidth={2}
          d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253"
        />
      </svg>
    ),
    title: "107+ Rules",
    description:
      "Comprehensive detection beyond PSScriptAnalyzer. Best practices, style, and custom security patterns.",
    color: "#8B5CF6",
  },
  {
    icon: (
      <svg
        className="w-8 h-8"
        fill="none"
        stroke="currentColor"
        viewBox="0 0 24 24"
      >
        <path
          strokeLinecap="round"
          strokeLinejoin="round"
          strokeWidth={2}
          d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z"
        />
      </svg>
    ),
    title: "Zero Knowledge Required",
    description:
      "Designed for complete beginners. Clear guidance, helpful tooltips, and plain language explanations.",
    color: "#EC4899",
  },
];

function MagneticCard({ feature, index }: { feature: Feature; index: number }) {
  const ref = React.useRef<HTMLDivElement>(null);
  const x = useMotionValue(0);
  const y = useMotionValue(0);

  const springConfig = { damping: 25, stiffness: 150 };
  const rotateX = useSpring(useTransform(y, [-50, 50], [5, -5]), springConfig);
  const rotateY = useSpring(useTransform(x, [-50, 50], [-5, 5]), springConfig);

  const handleMouseMove = (event: React.MouseEvent<HTMLDivElement>) => {
    if (!ref.current) return;
    const rect = ref.current.getBoundingClientRect();
    const centerX = rect.left + rect.width / 2;
    const centerY = rect.top + rect.height / 2;
    x.set(event.clientX - centerX);
    y.set(event.clientY - centerY);
  };

  const handleMouseLeave = () => {
    x.set(0);
    y.set(0);
  };

  return (
    <motion.div
      ref={ref}
      initial={{ opacity: 0, y: 30 }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true, margin: "-100px" }}
      transition={{
        duration: 0.5,
        delay: index * 0.1,
        ease: [0.22, 1, 0.36, 1],
      }}
      style={{
        rotateX,
        rotateY,
        transformStyle: "preserve-3d",
      }}
      onMouseMove={handleMouseMove}
      onMouseLeave={handleMouseLeave}
      className="h-full"
    >
      <Card
        variant="interactive"
        className="h-full group relative overflow-hidden"
      >
        {/* Gradient Overlay on Hover */}
        <div
          className="absolute inset-0 opacity-0 group-hover:opacity-10 transition-opacity duration-300"
          style={{
            background: `linear-gradient(135deg, ${feature.color}, transparent)`,
          }}
        />

        <CardHeader className="relative z-10">
          <div
            className="w-14 h-14 rounded-xl flex items-center justify-center mb-4 shadow-sm transition-transform duration-300 group-hover:scale-110"
            style={{
              backgroundColor: `${feature.color}15`,
              color: feature.color,
            }}
          >
            {feature.icon}
          </div>
          <CardTitle className="text-xl mb-2">{feature.title}</CardTitle>
          <CardDescription className="text-base leading-relaxed">
            {feature.description}
          </CardDescription>
        </CardHeader>
      </Card>
    </motion.div>
  );
}

export function Features() {
  return (
    <section id="features" className="py-24 bg-[var(--bg-elevated)]">
      <div className="container mx-auto px-4">
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6 }}
          className="text-center mb-16"
        >
          <h2
            className="text-4xl sm:text-5xl font-bold mb-4 text-gradient"
            style={{ fontSize: "clamp(2rem, 4vw + 0.5rem, 3rem)" }}
          >
            Everything You Need
          </h2>
          <p
            className="text-xl text-[var(--text-secondary)] max-w-3xl mx-auto"
            style={{ fontSize: "clamp(1rem, 1.5vw + 0.5rem, 1.25rem)" }}
          >
            Professional-grade code quality tools with beginner-friendly design.
            No technical knowledge required.
          </p>
        </motion.div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {features.map((feature, index) => (
            <MagneticCard key={index} feature={feature} index={index} />
          ))}
        </div>
      </div>
    </section>
  );
}
