"use client";
import React from "react";
import { cn } from "@/lib/utils";
import { Container } from "./container";
import { SectionHeading } from "./typography";
import { Button } from "./button";
import { StackIcon } from "./brand-marks";
import { AppleIcon, BellIcon, CogIcon, CubeIcon, FlowIcon, GaugeIcon, KeyIcon, ListIcon, ServersIcon, TerminalIcon } from "./icons";
import { site } from "@/lib/site";

type Tile = { icon: React.FC<React.SVGProps<SVGSVGElement>>; dot?: string };

const rings: { size: number; duration: number; tiles: Tile[] }[] = [
  { size: 380, duration: 30, tiles: [] },
  {
    size: 600,
    duration: 42,
    tiles: [{ icon: GaugeIcon }, { icon: BellIcon, dot: "bg-warn" }, { icon: CogIcon }, { icon: KeyIcon }, { icon: FlowIcon }],
  },
  {
    size: 800,
    duration: 56,
    tiles: [
      { icon: ListIcon },
      { icon: ServersIcon, dot: "bg-brand" },
      { icon: CubeIcon },
      { icon: GaugeIcon },
      { icon: ServersIcon, dot: "bg-down" },
      { icon: TerminalIcon },
      { icon: CogIcon },
    ],
  },
];

const Orbit = ({ className }: { className?: string }) => (
  <div className={cn("pointer-events-none relative mx-auto size-[800px]", className)} aria-hidden>
    {[...rings].reverse().map((r, i) => (
      <div
        key={`bg-${r.size}`}
        className={cn(
          "absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 rounded-full shadow-inner",
          i === 0 && "bg-neutral-100 dark:bg-neutral-800/60",
          i === 1 && "bg-neutral-200/70 dark:bg-neutral-800",
          i === 2 && "bg-neutral-300/60 dark:bg-neutral-700/70",
        )}
        style={{ width: r.size, height: r.size }}
      />
    ))}
    {rings.map((r, ri) => {
      const reverse = ri % 2 === 1;
      return (
        <div
          key={r.size}
          className={cn(
            "absolute top-1/2 left-1/2 rounded-full",
            reverse ? "animate-counter-orbit" : "animate-orbit",
          )}
          style={{ width: r.size, height: r.size, marginLeft: -r.size / 2, marginTop: -r.size / 2, animationDuration: `${r.duration}s` }}
        >
          {r.tiles.map((t, i) => {
            const angle = (360 / r.tiles.length) * i + ri * 20;
            return (
              <div
                key={i}
                className="absolute top-1/2 left-1/2"
                style={{ transform: `rotate(${angle}deg) translateX(${r.size / 2}px) rotate(${-angle}deg)` }}
              >
                <div
                  className={cn(
                    "shadow-aceternity relative -mt-7 -ml-7 flex size-14 items-center justify-center rounded-md bg-white text-neutral-700 dark:bg-neutral-950 dark:text-neutral-300",
                    reverse ? "animate-orbit" : "animate-counter-orbit",
                  )}
                  style={{ animationDuration: `${r.duration}s` }}
                >
                  <t.icon className="size-6" />
                  {t.dot && <span className={cn("absolute top-2 right-2 size-2 rounded-full", t.dot)} />}
                </div>
              </div>
            );
          })}
        </div>
      );
    })}
  </div>
);

export const CTA = () => (
  <Container className="border-divide relative flex min-h-[520px] flex-col items-center justify-center overflow-hidden border-x px-4 py-16 md:min-h-[600px]">
    <Orbit className="absolute top-1/2 scale-75 md:scale-100 left-1/2 -translate-x-1/2 -translate-y-1/2 mask-radial-from-40% mask-radial-to-70%" />
    <StackIcon className="relative z-10 size-24 drop-shadow-xl" />
    <SectionHeading className="relative z-10 mt-6 text-center lg:text-6xl">
      Stop checking. <br /> Start knowing.
    </SectionHeading>
    <Button href={site.download} className="relative z-10 mt-8">
      <AppleIcon className="size-4" />
      Download for Mac
    </Button>
    <p className="relative z-10 mt-4 font-mono text-xs text-gray-600 dark:text-neutral-500">Free · macOS 14 Sonoma and later</p>
  </Container>
);
