import { cn } from "@/lib/utils";
import React from "react";

type Variant = "primary" | "secondary";

export const Button = ({
  children,
  variant = "primary",
  className,
  href,
  ...props
}: {
  children: React.ReactNode;
  variant?: Variant;
  className?: string;
  href?: string;
} & React.ButtonHTMLAttributes<HTMLButtonElement>) => {
  const classes = cn(
    "inline-flex items-center justify-center gap-2 rounded-xl px-5 py-2 text-center text-sm font-medium transition duration-150 active:scale-[0.98] sm:text-base",
    variant === "primary"
      ? "bg-charcoal-900 text-white hover:bg-black dark:bg-white dark:text-black dark:hover:bg-neutral-200"
      : "border-divide border bg-white text-black hover:bg-gray-200 dark:border-neutral-700 dark:bg-neutral-950 dark:text-white dark:hover:bg-neutral-800",
    className,
  );
  if (href) {
    return (
      <a href={href} className={classes}>
        {children}
      </a>
    );
  }
  return (
    <button {...props} className={classes}>
      {children}
    </button>
  );
};
