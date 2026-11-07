"use client";
import { cn } from "@/lib/utils";
import React, { useEffect, useRef, useState } from "react";
import { motion } from "motion/react";

/** Corner marker that lights up green when the pointer comes close. */
export const Dot = ({
  top,
  left,
  right,
  bottom,
}: {
  top?: boolean;
  left?: boolean;
  right?: boolean;
  bottom?: boolean;
}) => {
  const ref = useRef<HTMLDivElement>(null);
  const [near, setNear] = useState(false);

  useEffect(() => {
    const onMove = (e: MouseEvent) => {
      const r = ref.current?.getBoundingClientRect();
      if (!r) return;
      const d = Math.hypot(e.clientX - (r.left + r.width / 2), e.clientY - (r.top + r.height / 2));
      setNear(d <= 100);
    };
    window.addEventListener("mousemove", onMove);
    return () => window.removeEventListener("mousemove", onMove);
  }, []);

  return (
    <motion.div
      ref={ref}
      className={cn(
        "absolute z-10 h-2 w-2",
        top && "top-0 xl:-top-1",
        left && "left-0 xl:-left-1",
        right && "right-0 xl:-right-1",
        bottom && "bottom-0 xl:-bottom-1",
      )}
      animate={{
        backgroundColor: near ? "var(--color-brand)" : "var(--color-primary)",
        boxShadow: near ? "0 0 20px var(--color-brand), 0 0 40px var(--color-brand)" : "none",
        scale: near ? 1.5 : 1,
        borderRadius: near ? "50%" : "0%",
      }}
      transition={{ duration: 0.3, ease: "easeOut" }}
    />
  );
};

export const CornerDots = () => (
  <>
    <Dot top left />
    <Dot top right />
    <Dot bottom left />
    <Dot bottom right />
  </>
);
