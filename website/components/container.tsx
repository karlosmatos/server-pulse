import { cn } from "@/lib/utils";
import React from "react";

export const Container = ({
  children,
  className,
  as: Component = "div",
  id,
}: {
  children: React.ReactNode;
  className?: string;
  as?: React.ElementType;
  id?: string;
}) => (
  <Component id={id} className={cn("mx-auto max-w-7xl", className)}>
    {children}
  </Component>
);
