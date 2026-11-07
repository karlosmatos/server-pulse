"use client";
import React, { useEffect, useState } from "react";
import { motion, useReducedMotion } from "motion/react";
import { cn } from "@/lib/utils";
import { containers, servers, services, statusColor, statusLabel } from "@/lib/mock";
import { ClockIcon, CogIcon, CubeIcon, GaugeIcon, TerminalIcon, WarnTriangle } from "./icons";

/* ---------- Menu bar ---------- */

export type Indicator = { kind: "ok" | "warn" | "down"; count?: number };

export const StatusIndicator = ({ kind, count }: Indicator) => (
  <span
    className={cn(
      "inline-flex h-[22px] items-center gap-1 rounded-[5px] px-1.5 text-[12px] font-semibold tabular-nums",
      "bg-black/[0.07] dark:bg-white/[0.14]",
      kind === "warn" && "text-warn",
      kind === "down" && "text-down",
    )}
  >
    {kind === "warn" ? (
      <WarnTriangle className="size-3.5" />
    ) : (
      <span className={cn("size-2.5 rounded-full", kind === "ok" ? "bg-brand" : "bg-down")} />
    )}
    {count ? <span>{count}</span> : null}
  </span>
);

const useClock = () => {
  const [now, setNow] = useState<string | null>(null);
  useEffect(() => {
    const fmt = () =>
      new Date()
        .toLocaleString("en-GB", { weekday: "short", day: "numeric", month: "short", hour: "2-digit", minute: "2-digit" })
        .replace(",", "");
    setNow(fmt());
    const t = setInterval(() => setNow(fmt()), 15_000);
    return () => clearInterval(t);
  }, []);
  return now ?? "Sat 7 Nov 14:32";
};

export const MenuBar = ({
  indicator = { kind: "ok" },
  className,
  compact,
}: {
  indicator?: Indicator;
  className?: string;
  compact?: boolean;
}) => {
  const clock = useClock();
  return (
    <div
      className={cn(
        "flex h-8 items-center justify-between gap-4 px-3 text-[13px] text-neutral-800 dark:text-neutral-200",
        className,
      )}
    >
      {!compact && (
        <div className="hidden items-center gap-4 sm:flex">
          <svg viewBox="0 0 24 24" className="size-3.5" fill="currentColor" aria-hidden>
            <path d="M16.4 12.6c0-2.6 2.1-3.8 2.2-3.9-1.2-1.8-3.1-2-3.7-2-1.6-.2-3.1.9-3.9.9s-2-.9-3.4-.9c-1.7 0-3.3 1-4.2 2.6-1.8 3.1-.5 7.7 1.3 10.2.9 1.2 1.9 2.6 3.2 2.6 1.3-.1 1.8-.8 3.3-.8s2 .8 3.4.8c1.4 0 2.3-1.3 3.1-2.5 1-1.4 1.4-2.8 1.4-2.9-.1 0-2.7-1-2.7-4.1zM13.9 5c.7-.9 1.2-2 1-3.2-1 0-2.3.7-3 1.6-.7.8-1.2 2-1.1 3.1 1.2.1 2.3-.6 3.1-1.5z" />
          </svg>
          <span className="font-semibold">Terminal</span>
          <span className="hidden md:inline">Shell</span>
          <span className="hidden md:inline">Edit</span>
          <span className="hidden md:inline">View</span>
          <span className="hidden lg:inline">Window</span>
        </div>
      )}
      <div className="ml-auto flex items-center gap-3.5">
        {!compact && (
          <>
            <svg className="hidden size-4 opacity-80 sm:block" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" aria-hidden>
              <rect x="2" y="7" width="18" height="10" rx="2.5" />
              <path d="M22 11v2" />
              <rect x="4" y="9" width="11" height="6" rx="1" fill="currentColor" stroke="none" />
            </svg>
            <svg className="hidden size-4 opacity-80 sm:block" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" aria-hidden>
              <path d="M2 9a15 15 0 0 1 20 0M5 12.5a10 10 0 0 1 14 0M8.5 16a5 5 0 0 1 7 0" />
              <circle cx="12" cy="19.5" r="1" fill="currentColor" />
            </svg>
          </>
        )}
        <StatusIndicator {...indicator} />
        <span className="tabular-nums">{clock}</span>
      </div>
    </div>
  );
};

/* ---------- Popover ---------- */

const useTelemetry = () => {
  const reduce = useReducedMotion();
  const [cpu, setCpu] = useState(23.4);
  const [mem, setMem] = useState(3.1);
  useEffect(() => {
    if (reduce) return;
    const t = setInterval(() => {
      setCpu((c) => Math.min(58, Math.max(9, c + (Math.random() - 0.5) * 9)));
      setMem((m) => Math.min(4.3, Math.max(2.8, m + (Math.random() - 0.5) * 0.2)));
    }, 2200);
    return () => clearInterval(t);
  }, [reduce]);
  return { cpu, mem };
};

export const Bar = ({ value, className }: { value: number; className?: string }) => (
  <div className={cn("h-[5px] overflow-hidden rounded-full bg-black/[0.08] dark:bg-white/10", className)}>
    <motion.div
      className={cn("h-full rounded-full", value >= 85 ? "bg-down" : value >= 60 ? "bg-warn" : "bg-brand")}
      initial={false}
      animate={{ width: `${value}%` }}
      transition={{ duration: 0.8, ease: "easeOut" }}
    />
  </div>
);

export const Card = ({
  icon,
  title,
  tint,
  children,
  className,
}: {
  icon: React.ReactNode;
  title: string;
  tint: string;
  children: React.ReactNode;
  className?: string;
}) => (
  <div className={cn("rounded-[10px] bg-black/[0.035] p-3 dark:bg-white/[0.05]", className)}>
    <div className="mb-2.5 flex items-center gap-1.5 text-[12px] font-semibold text-neutral-800 dark:text-neutral-100">
      <span className={tint}>{icon}</span>
      {title}
    </div>
    {children}
  </div>
);

export const PulsingDot = ({ status = "online" as keyof typeof statusColor, className }: { status?: keyof typeof statusColor; className?: string }) => (
  <span className={cn("relative inline-flex size-3.5 shrink-0", className)}>
    {status === "online" && <span className={cn("animate-ping-slow absolute inset-0 rounded-full", statusColor[status])} />}
    <span className={cn("relative size-full rounded-full", statusColor[status])} />
  </span>
);

export const Popover = ({ className, arrow = true }: { className?: string; arrow?: boolean }) => {
  const { cpu, mem } = useTelemetry();
  const server = servers[0];
  return (
    <div
      className={cn(
        "shadow-popover relative w-[340px] rounded-[14px] bg-white/90 p-3 text-[12px] text-neutral-800 backdrop-blur-xl dark:bg-neutral-900/90 dark:text-neutral-200 dark:shadow-[0_0_0_1px_rgba(255,255,255,0.1),0_30px_60px_-20px_rgba(0,0,0,0.8)]",
        className,
      )}
    >
      {arrow && (
        <span className="absolute -top-[6px] right-[68px] max-sm:right-[118px] size-3 rotate-45 rounded-[2px] bg-white/90 shadow-[-1px_-1px_0_0_rgba(0,0,0,0.06)] dark:bg-neutral-900/90 dark:shadow-[-1px_-1px_0_0_rgba(255,255,255,0.1)]" />
      )}
      <div className="mb-2.5 flex gap-1.5">
        {servers.map((s, i) => (
          <span
            key={s.name}
            className={cn(
              "inline-flex items-center gap-1.5 rounded-full px-2.5 py-1 text-[11.5px]",
              i === 0
                ? "bg-black/[0.08] font-medium text-neutral-900 dark:bg-white/15 dark:text-white"
                : "text-neutral-500 dark:text-neutral-400",
            )}
          >
            <span className={cn("size-1.5 rounded-full", statusColor[s.status])} />
            {s.name}
          </span>
        ))}
      </div>

      <div className="flex items-center gap-3 rounded-[10px] bg-brand/[0.07] p-3">
        <PulsingDot />
        <div className="min-w-0">
          <p className="text-[17px] leading-tight font-bold tracking-tight text-neutral-900 dark:text-white">{server.name}</p>
          <div className="mt-1 flex items-center gap-1.5 text-neutral-500 dark:text-neutral-400">
            <span className="text-brand-ink dark:text-brand rounded-full bg-brand/15 px-2 py-px text-[11px] font-semibold">
              {statusLabel[server.status]}
            </span>
            <span>{server.host}</span>
            <ClockIcon className="size-3 opacity-60" />
            <span>{server.uptime}</span>
          </div>
        </div>
      </div>

      <Card icon={<GaugeIcon className="size-3.5" />} title="System" tint="text-blue-500" className="mt-2">
        <div className="space-y-2.5">
          {[
            { label: "CPU", detail: `${cpu.toFixed(1)}%`, value: cpu },
            { label: "Memory", detail: `${mem.toFixed(1)} / 8.0 GB`, value: (mem / 8) * 100 },
            { label: "Disk", detail: "41G / 80G", value: 51 },
          ].map((g) => (
            <div key={g.label}>
              <div className="mb-1 flex justify-between text-neutral-500 dark:text-neutral-400">
                <span>{g.label}</span>
                <span className="font-medium text-neutral-900 tabular-nums dark:text-white">{g.detail}</span>
              </div>
              <Bar value={g.value} />
            </div>
          ))}
        </div>
      </Card>

      <div className="mt-2 grid grid-cols-2 gap-2">
        <Card icon={<CubeIcon className="size-3.5" />} title="Docker" tint="text-cyan-500">
          {containers.map((c) => (
            <div key={c.name} className="flex items-center gap-1.5 py-[3px] text-neutral-600 dark:text-neutral-300">
              <span className="size-1.5 rounded-full bg-brand" />
              <span className="flex-1 font-mono text-[11px]">{c.name}</span>
              <span className="text-[11px] text-neutral-400 tabular-nums">{c.cpu}</span>
            </div>
          ))}
        </Card>
        <Card icon={<CogIcon className="size-3.5" />} title="Services" tint="text-violet-500">
          {services.map((s) => (
            <div key={s.name} className="flex items-center gap-1.5 py-[3px] text-neutral-600 dark:text-neutral-300">
              <span className="size-1.5 rounded-full bg-brand" />
              <span className="flex-1 font-mono text-[11px]">{s.name}</span>
            </div>
          ))}
        </Card>
      </div>

      <div className="mt-2.5 flex items-center justify-between px-1 text-[11px] text-neutral-400">
        <span>Check for Updates…</span>
        <span className="flex items-center gap-3">
          <TerminalIcon className="size-3.5" />
          <CogIcon className="size-3.5" />
        </span>
      </div>
    </div>
  );
};

/* ---------- Notification banner ---------- */

export const Notification = ({
  title,
  body,
  className,
}: {
  title: string;
  body: string;
  className?: string;
}) => (
  <div
    className={cn(
      "shadow-popover flex w-[320px] items-start gap-3 rounded-2xl bg-white/85 p-3 backdrop-blur-xl dark:bg-neutral-800/85",
      className,
    )}
  >
    <span className="flex size-9 shrink-0 items-center justify-center rounded-[9px] bg-[#0F131B]">
      <span className="size-3.5 rounded-full bg-brand" />
    </span>
    <div className="min-w-0 text-[12.5px] leading-snug">
      <div className="flex justify-between gap-2">
        <span className="font-semibold text-neutral-900 dark:text-white">{title}</span>
        <span className="text-neutral-400">now</span>
      </div>
      <p className="text-neutral-600 dark:text-neutral-300">{body}</p>
    </div>
  </div>
);
