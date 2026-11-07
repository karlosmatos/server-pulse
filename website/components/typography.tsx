import React from "react";
import { cn } from "@/lib/utils";
import { ShimmerText } from "./shimmer-text";

type Props = { children: React.ReactNode; className?: string };

export const Heading = ({ children, className }: Props) => (
  <h1
    className={cn(
      "text-center text-4xl font-medium tracking-tight text-balance text-black md:text-5xl lg:text-7xl dark:text-white",
      className,
    )}
  >
    {children}
  </h1>
);

export const SectionHeading = ({ children, className }: Props) => (
  <h2
    className={cn(
      "text-charcoal-700 text-center text-2xl font-medium tracking-tight text-balance md:text-3xl lg:text-4xl dark:text-neutral-100",
      className,
    )}
  >
    {children}
  </h2>
);

export const SubHeading = ({
  children,
  className,
  as: Component = "p",
}: Props & { as?: React.ElementType }) => (
  <Component
    className={cn(
      "text-center text-sm font-medium tracking-tight text-pretty text-gray-600 lg:text-base dark:text-neutral-400",
      className,
    )}
  >
    {children}
  </Component>
);

export const Badge = ({ text }: { text: string }) => (
  <ShimmerText
    duration={1.2}
    className="font-mono text-sm [--base-color:var(--color-brand-ink)] [--base-gradient-color:var(--color-white)] dark:[--base-color:var(--color-brand)]"
  >
    {text}
  </ShimmerText>
);

export const Eyebrow = ({ children, className }: Props) => (
  <p
    className={cn(
      "text-center font-mono text-sm tracking-tight text-neutral-500 uppercase dark:text-neutral-400",
      className,
    )}
  >
    {children}
  </p>
);
