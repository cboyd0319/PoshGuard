"use client";

import * as React from "react";
import { motion, AnimatePresence } from "framer-motion";
import { Card } from "./ui/card";

interface Testimonial {
  name: string;
  role: string;
  company: string;
  content: string;
  avatar: string;
}

const testimonials: Testimonial[] = [
  {
    name: "Sarah Mitchell",
    role: "DevOps Engineer",
    company: "TechCorp",
    content:
      "PoshGuard transformed our PowerShell workflow. We caught critical security issues before they hit production. The AI-powered fixes are incredibly accurate.",
    avatar: "SM",
  },
  {
    name: "Mike Chen",
    role: "Security Lead",
    company: "FinanceHub",
    content:
      "Best PowerShell tool I've used. The 98%+ fix rate isn't marketing hype - it's real. Saved us countless hours of manual code review.",
    avatar: "MC",
  },
  {
    name: "Emma Rodriguez",
    role: "IT Administrator",
    company: "Healthcare Plus",
    content:
      "As someone new to PowerShell, PoshGuard made me productive immediately. The explanations are crystal clear and the previews give me confidence.",
    avatar: "ER",
  },
];

export function Testimonials() {
  const [current, setCurrent] = React.useState(0);
  const [direction, setDirection] = React.useState(0);

  const paginate = (newDirection: number) => {
    setDirection(newDirection);
    setCurrent((prev) => {
      const next = prev + newDirection;
      if (next < 0) return testimonials.length - 1;
      if (next >= testimonials.length) return 0;
      return next;
    });
  };

  // Auto-advance carousel
  React.useEffect(() => {
    const timer = setInterval(() => {
      paginate(1);
    }, 5000);

    return () => clearInterval(timer);
  }, []);

  const variants = {
    enter: (direction: number) => ({
      x: direction > 0 ? 300 : -300,
      opacity: 0,
    }),
    center: {
      x: 0,
      opacity: 1,
    },
    exit: (direction: number) => ({
      x: direction < 0 ? 300 : -300,
      opacity: 0,
    }),
  };

  return (
    <section
      id="testimonials"
      className="py-24 bg-[var(--bg-surface)]"
      aria-label="Customer testimonials"
    >
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
            Loved by Developers
          </h2>
          <p
            className="text-xl text-[var(--text-secondary)] max-w-3xl mx-auto"
            style={{ fontSize: "clamp(1rem, 1.5vw + 0.5rem, 1.25rem)" }}
          >
            See what teams are saying about PoshGuard
          </p>
        </motion.div>

        <div className="relative max-w-4xl mx-auto">
          {/* Carousel Container */}
          <div className="relative h-[400px] overflow-hidden">
            <AnimatePresence initial={false} custom={direction} mode="wait">
              <motion.div
                key={current}
                custom={direction}
                variants={variants}
                initial="enter"
                animate="center"
                exit="exit"
                transition={{
                  x: { type: "spring", stiffness: 300, damping: 30 },
                  opacity: { duration: 0.2 },
                }}
                className="absolute inset-0 flex items-center justify-center px-4"
              >
                <Card
                  variant="elevated"
                  className="w-full max-w-3xl p-8 md:p-12"
                >
                  <div className="flex flex-col items-center text-center">
                    {/* Avatar */}
                    <div
                      className="w-16 h-16 rounded-full flex items-center justify-center text-2xl font-bold text-white mb-6 shadow-lg"
                      style={{
                        background:
                          "linear-gradient(135deg, var(--gradient-from), var(--gradient-via))",
                      }}
                    >
                      {testimonials[current].avatar}
                    </div>

                    {/* Content */}
                    <blockquote className="text-xl md:text-2xl text-[var(--text-primary)] mb-6 leading-relaxed">
                      "{testimonials[current].content}"
                    </blockquote>

                    {/* Author */}
                    <div>
                      <div className="font-semibold text-[var(--text-primary)]">
                        {testimonials[current].name}
                      </div>
                      <div className="text-sm text-[var(--text-secondary)]">
                        {testimonials[current].role} at{" "}
                        {testimonials[current].company}
                      </div>
                    </div>
                  </div>
                </Card>
              </motion.div>
            </AnimatePresence>
          </div>

          {/* Navigation Buttons */}
          <div className="flex justify-center items-center gap-4 mt-8">
            <button
              onClick={() => paginate(-1)}
              className="w-12 h-12 rounded-full bg-[var(--bg-elevated)] border border-[var(--border-default)] flex items-center justify-center hover:bg-[var(--interactive-primary)] hover:text-white hover:border-[var(--interactive-primary)] transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--focus-ring)]"
              aria-label="Previous testimonial"
            >
              <svg
                className="w-6 h-6"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
                aria-hidden="true"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M15 19l-7-7 7-7"
                />
              </svg>
            </button>

            {/* Indicators */}
            <div className="flex gap-2" role="tablist" aria-label="Testimonial navigation">
              {testimonials.map((_, index) => (
                <button
                  key={index}
                  onClick={() => {
                    setDirection(index > current ? 1 : -1);
                    setCurrent(index);
                  }}
                  className={`w-2 h-2 rounded-full transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--focus-ring)] ${
                    index === current
                      ? "w-8 bg-[var(--interactive-primary)]"
                      : "bg-[var(--border-strong)]"
                  }`}
                  aria-label={`Go to testimonial ${index + 1}`}
                  aria-current={index === current}
                  role="tab"
                />
              ))}
            </div>

            <button
              onClick={() => paginate(1)}
              className="w-12 h-12 rounded-full bg-[var(--bg-elevated)] border border-[var(--border-default)] flex items-center justify-center hover:bg-[var(--interactive-primary)] hover:text-white hover:border-[var(--interactive-primary)] transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--focus-ring)]"
              aria-label="Next testimonial"
            >
              <svg
                className="w-6 h-6"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
                aria-hidden="true"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M9 5l7 7-7 7"
                />
              </svg>
            </button>
          </div>
        </div>
      </div>
    </section>
  );
}
