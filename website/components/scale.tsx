import { cn } from "@/lib/utils";

/** The template's diagonal hatch, used behind illustrations. */
export const Scale = ({ className }: { className?: string }) => (
  <div
    className={cn(
      "pointer-events-none absolute inset-0 border border-(--pattern-fg) bg-[image:repeating-linear-gradient(315deg,_var(--pattern-fg)_0,_var(--pattern-fg)_1px,_transparent_0,_transparent_50%)] bg-[size:10px_10px]",
      className,
    )}
  />
);

export const DotGrid = ({ className }: { className?: string }) => (
  <div
    className={cn(
      "pointer-events-none absolute inset-0 bg-[radial-gradient(var(--color-dots)_1px,transparent_1px)] [background-size:10px_10px]",
      className,
    )}
  />
);
