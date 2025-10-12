"use client";

import * as React from "react";
import { cn } from "@/lib/utils";

export interface InputProps
  extends React.InputHTMLAttributes<HTMLInputElement> {
  label?: string;
  error?: string;
  helperText?: string;
  leftIcon?: React.ReactNode;
  rightIcon?: React.ReactNode;
}

const Input = React.forwardRef<HTMLInputElement, InputProps>(
  (
    {
      className,
      type,
      label,
      error,
      helperText,
      leftIcon,
      rightIcon,
      id,
      disabled,
      ...props
    },
    ref
  ) => {
    const inputId = id || `input-${React.useId()}`;
    const errorId = `${inputId}-error`;
    const helperId = `${inputId}-helper`;

    return (
      <div className="w-full">
        {label && (
          <label
            htmlFor={inputId}
            className="block text-sm font-medium mb-2 text-[var(--text-primary)]"
          >
            {label}
          </label>
        )}
        <div className="relative">
          {leftIcon && (
            <div className="absolute left-3 top-1/2 -translate-y-1/2 pointer-events-none text-[var(--text-secondary)]">
              {leftIcon}
            </div>
          )}
          <input
            id={inputId}
            type={type}
            className={cn(
              [
                "flex h-11 w-full rounded-lg",
                "border-2 border-[var(--border-default)]",
                "bg-[var(--bg-surface)] px-4 py-2",
                "text-base text-[var(--text-primary)]",
                "placeholder:text-[var(--text-tertiary)]",
                "transition-all duration-150",
                "focus-visible:outline-none focus-visible:ring-2",
                "focus-visible:ring-[var(--focus-ring)] focus-visible:ring-offset-2",
                "focus-visible:border-[var(--interactive-primary)]",
                "disabled:cursor-not-allowed disabled:opacity-50",
                "hover:border-[var(--border-strong)]",
                leftIcon && "pl-10",
                rightIcon && "pr-10",
                error && "border-[var(--status-error)] focus-visible:ring-[var(--status-error)]",
              ],
              className
            )}
            ref={ref}
            disabled={disabled}
            aria-invalid={!!error}
            aria-describedby={
              error ? errorId : helperText ? helperId : undefined
            }
            {...props}
          />
          {rightIcon && (
            <div className="absolute right-3 top-1/2 -translate-y-1/2 pointer-events-none text-[var(--text-secondary)]">
              {rightIcon}
            </div>
          )}
        </div>
        {error && (
          <p
            id={errorId}
            className="mt-1.5 text-sm text-[var(--status-error)]"
            role="alert"
          >
            {error}
          </p>
        )}
        {helperText && !error && (
          <p id={helperId} className="mt-1.5 text-sm text-[var(--text-secondary)]">
            {helperText}
          </p>
        )}
      </div>
    );
  }
);
Input.displayName = "Input";

export { Input };
