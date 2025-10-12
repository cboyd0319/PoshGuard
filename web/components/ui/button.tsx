"use client";

import * as React from "react";
import { cva, type VariantProps } from "class-variance-authority";
import { cn } from "@/lib/utils";

const buttonVariants = cva(
  [
    "inline-flex items-center justify-center gap-2",
    "font-medium transition-all duration-150",
    "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2",
    "disabled:pointer-events-none disabled:opacity-50",
    "active:scale-[0.98]",
    "relative overflow-hidden",
  ].join(" "),
  {
    variants: {
      variant: {
        primary: [
          "bg-[var(--interactive-primary)] text-white",
          "hover:bg-[var(--interactive-primary-hover)]",
          "active:bg-[var(--interactive-primary-active)]",
          "focus-visible:ring-[var(--focus-ring)]",
          "shadow-sm hover:shadow-md",
        ].join(" "),
        secondary: [
          "bg-[var(--interactive-secondary)] text-white",
          "hover:opacity-90",
          "focus-visible:ring-[var(--interactive-secondary)]",
          "shadow-sm hover:shadow-md",
        ].join(" "),
        outline: [
          "border-2 border-[var(--border-default)] bg-transparent",
          "hover:bg-[var(--bg-elevated)] hover:border-[var(--interactive-primary)]",
          "focus-visible:ring-[var(--focus-ring)]",
        ].join(" "),
        ghost: [
          "bg-transparent hover:bg-[var(--bg-elevated)]",
          "focus-visible:ring-[var(--focus-ring)]",
        ].join(" "),
        link: [
          "text-[var(--interactive-link)] underline-offset-4",
          "hover:underline",
          "focus-visible:ring-[var(--focus-ring)]",
        ].join(" "),
        destructive: [
          "bg-[var(--status-error)] text-white",
          "hover:opacity-90",
          "focus-visible:ring-[var(--status-error)]",
          "shadow-sm hover:shadow-md",
        ].join(" "),
      },
      size: {
        sm: "h-9 px-3 text-sm rounded-md",
        md: "h-11 px-5 text-base rounded-lg",
        lg: "h-14 px-8 text-lg rounded-xl",
        icon: "h-11 w-11 rounded-lg",
      },
      fullWidth: {
        true: "w-full",
      },
    },
    defaultVariants: {
      variant: "primary",
      size: "md",
    },
  }
);

export interface ButtonProps
  extends React.ButtonHTMLAttributes<HTMLButtonElement>,
    VariantProps<typeof buttonVariants> {
  loading?: boolean;
  leftIcon?: React.ReactNode;
  rightIcon?: React.ReactNode;
}

const Button = React.forwardRef<HTMLButtonElement, ButtonProps>(
  (
    {
      className,
      variant,
      size,
      fullWidth,
      loading,
      leftIcon,
      rightIcon,
      children,
      disabled,
      ...props
    },
    ref
  ) => {
    return (
      <button
        className={cn(buttonVariants({ variant, size, fullWidth, className }))}
        ref={ref}
        disabled={disabled || loading}
        aria-busy={loading}
        {...props}
      >
        {loading && (
          <svg
            className="animate-spin h-4 w-4"
            xmlns="http://www.w3.org/2000/svg"
            fill="none"
            viewBox="0 0 24 24"
            aria-hidden="true"
          >
            <circle
              className="opacity-25"
              cx="12"
              cy="12"
              r="10"
              stroke="currentColor"
              strokeWidth="4"
            />
            <path
              className="opacity-75"
              fill="currentColor"
              d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
            />
          </svg>
        )}
        {!loading && leftIcon && <span aria-hidden="true">{leftIcon}</span>}
        {children}
        {!loading && rightIcon && <span aria-hidden="true">{rightIcon}</span>}
      </button>
    );
  }
);
Button.displayName = "Button";

export { Button, buttonVariants };
