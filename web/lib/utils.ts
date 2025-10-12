import { type ClassValue, clsx } from "clsx";

/**
 * Utility function to merge Tailwind classes with proper precedence
 */
export function cn(...inputs: ClassValue[]) {
  return clsx(inputs);
}

/**
 * Check if user prefers reduced motion
 */
export function prefersReducedMotion(): boolean {
  if (typeof window === "undefined") return false;
  return window.matchMedia("(prefers-reduced-motion: reduce)").matches;
}

/**
 * Debounce function for performance optimization
 */
export function debounce<T extends (...args: any[]) => any>(
  func: T,
  wait: number
): (...args: Parameters<T>) => void {
  let timeout: NodeJS.Timeout;
  return (...args: Parameters<T>) => {
    clearTimeout(timeout);
    timeout = setTimeout(() => func(...args), wait);
  };
}

/**
 * Generate unique ID for accessibility
 */
export function generateId(prefix: string = "id"): string {
  return `${prefix}-${Math.random().toString(36).substr(2, 9)}`;
}
