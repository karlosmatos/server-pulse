"use client";
import React from "react";
import { motion } from "motion/react";
import { cn } from "@/lib/utils";
import { Container } from "./container";
import { Badge, SectionHeading, SubHeading } from "./typography";
import { DotGrid, Scale } from "./scale";
import { Bar, Card as PopCard, PulsingDot } from "./mac";
import { containers, processes, servers, services, statusLabel, workflows } from "@/lib/mock";
import {
  BellIcon,
  CogIcon,
  CubeIcon,
  FlowIcon,
  GaugeIcon,
  KeyIcon,
  ListIcon,
  ServersIcon,
  TerminalIcon,
} from "./icons";

const Card = ({ children, className }: { children: React.ReactNode; className?: string }) => (
  <div className={cn("relative p-4 md:p-8", className)}>{children}</div>
);

const Title = ({ icon, children }: { icon: React.ReactNode; children: React.ReactNode }) => (
  <div className="text-charcoal-700 flex items-center gap-2 text-lg font-medium dark:text-neutral-100">
    <span className="text-brand-ink dark:text-brand">{icon}</span>
    {children}
  </div>
);

const Desc = ({ children }: { children: React.ReactNode }) => (
  <p className="mt-2 max-w-md text-base text-gray-600 dark:text-neutral-400">{children}</p>
);

/** Panel that holds an illustration, framed like the template's skeletons. */
const Stage = ({ children, className }: { children: React.ReactNode; className?: string }) => (
  <div className={cn("relative mt-8 flex h-64 items-center justify-center overflow-hidden rounded-xl", className)}>
    <DotGrid className="mask-radial-from-30%" />
    <div className="relative">{children}</div>
  </div>
);

const surface =
  "shadow-popover rounded-xl bg-white p-3 text-[12px] text-neutral-700 dark:bg-neutral-900 dark:text-neutral-300 dark:shadow-[0_0_0_1px_rgba(255,255,255,0.08)]";

const GaugesSkeleton = () => (
  <div className={cn(surface, "w-[300px]")}>
    {[
      { label: "CPU", detail: "23.4%", value: 23 },
      { label: "Memory", detail: "6.9 / 8.0 GB", value: 86 },
      { label: "Disk", detail: "58G / 80G", value: 72 },
    ].map((g, i) => (
      <div key={g.label} className="mb-3 last:mb-0">
        <div className="mb-1 flex justify-between">
          <span className="text-neutral-500">{g.label}</span>
          <motion.span
            initial={{ opacity: 0 }}
            whileInView={{ opacity: 1 }}
            viewport={{ once: true }}
            transition={{ delay: 0.3 + i * 0.15 }}
            className={cn(
              "font-medium tabular-nums",
              g.value >= 85 ? "text-down" : g.value >= 60 ? "text-warn" : "text-neutral-900 dark:text-white",
            )}
          >
            {g.detail}
          </motion.span>
        </div>
        <Bar value={g.value} />
      </div>
    ))}
  </div>
);

const ProcessSkeleton = () => (
  <div className={cn(surface, "w-[320px] p-0")}>
    <div className="grid grid-cols-[48px_1fr_56px_56px] border-b border-black/5 px-3 py-2 font-mono text-[10.5px] text-neutral-400 uppercase dark:border-white/10">
      <span>PID</span>
      <span>Name</span>
      <span className="text-right">CPU</span>
      <span className="text-right">MEM</span>
    </div>
    {processes.map((p, i) => (
      <motion.div
        key={p.pid}
        initial={{ opacity: 0, x: -6 }}
        whileInView={{ opacity: 1, x: 0 }}
        viewport={{ once: true }}
        transition={{ delay: 0.1 + i * 0.08 }}
        className="grid grid-cols-[48px_1fr_56px_56px] px-3 py-1.5 font-mono text-[11.5px] tabular-nums"
      >
        <span className="text-neutral-400">{p.pid}</span>
        <span className="text-neutral-900 dark:text-white">{p.name}</span>
        <span className="text-right">{p.cpu.toFixed(1)}%</span>
        <span className="text-right">{p.mem.toFixed(1)}%</span>
      </motion.div>
    ))}
  </div>
);

const FleetSkeleton = () => (
  <div className="grid w-full max-w-3xl grid-cols-1 gap-3 px-2 sm:grid-cols-3">
    {servers.map((s, i) => (
      <motion.div
        key={s.name}
        initial={{ opacity: 0, y: 10 }}
        whileInView={{ opacity: 1, y: 0 }}
        viewport={{ once: true }}
        transition={{ delay: i * 0.12 }}
        className={cn(surface, "flex items-center gap-3")}
      >
        <PulsingDot status={s.status} />
        <div className="min-w-0">
          <p className="font-semibold text-neutral-900 dark:text-white">{s.name}</p>
          <p className="truncate font-mono text-[11px] text-neutral-500">{s.host}</p>
        </div>
        <span
          className={cn(
            "ml-auto rounded-full px-2 py-px text-[11px] font-semibold",
            s.status === "online" ? "text-brand-ink dark:text-brand bg-brand/15" : "text-warn bg-warn/15",
          )}
        >
          {statusLabel[s.status]}
        </span>
      </motion.div>
    ))}
  </div>
);

const DockerSkeleton = () => (
  <div className="grid w-[340px] grid-cols-2 gap-2">
    <PopCard icon={<CubeIcon className="size-3.5" />} title="Docker" tint="text-cyan-500" className={surface}>
      {containers.map((c) => (
        <div key={c.name} className="flex items-center gap-1.5 py-[3px]">
          <span className="bg-brand size-1.5 rounded-full" />
          <span className="flex-1 font-mono text-[11px]">{c.name}</span>
          <span className="text-[11px] text-neutral-400 tabular-nums">{c.mem}</span>
        </div>
      ))}
    </PopCard>
    <PopCard icon={<CogIcon className="size-3.5" />} title="systemd" tint="text-violet-500" className={surface}>
      {[...services.slice(0, 2), { name: "certbot", state: "failed" }].map((s) => (
        <div key={s.name} className="flex items-center gap-1.5 py-[3px]">
          <span className={cn("size-1.5 rounded-full", s.state === "failed" ? "bg-down" : "bg-brand")} />
          <span className="flex-1 font-mono text-[11px]">{s.name}</span>
          <span className={cn("text-[10.5px]", s.state === "failed" ? "text-down" : "text-neutral-400")}>{s.state}</span>
        </div>
      ))}
    </PopCard>
  </div>
);

const WorkflowSkeleton = () => (
  <div className={cn(surface, "w-[320px]")}>
    {workflows.map((w) => (
      <div key={w.name} className="flex items-center gap-2 border-b border-black/5 py-2 last:border-0 dark:border-white/10">
        <span className={cn("size-1.5 rounded-full", w.active ? "bg-brand" : "bg-neutral-400")} />
        <span className="flex-1 text-neutral-900 dark:text-white">{w.name}</span>
        <span
          className={cn(
            "rounded px-1.5 py-px font-mono text-[10.5px]",
            w.last === "error" ? "text-down bg-down/10" : "text-brand-ink dark:text-brand bg-brand/10",
          )}
        >
          {w.last}
        </span>
        <span className="w-14 text-right text-[11px] text-neutral-400">{w.ago}</span>
      </div>
    ))}
  </div>
);

export const Features = () => (
  <Container id="features" className="border-divide scroll-mt-20 border-x">
    <div className="flex flex-col items-center px-4 pt-16 pb-16">
      <Badge text="Features" />
      <SectionHeading className="mt-4">Everything you would ssh in to check</SectionHeading>
      <SubHeading className="mx-auto mt-6 max-w-lg">
        One popover per server. Open it when the dot changes colour, close it when it goes green again.
      </SubHeading>
    </div>

    <div className="border-divide divide-divide grid grid-cols-1 divide-y border-y md:grid-cols-2 md:divide-x md:divide-y-0">
      <Card>
        <Title icon={<GaugeIcon />}>Live gauges</Title>
        <Desc>CPU, memory and disk turn amber at 60% and red at 85%, so you see trouble before it pages anyone.</Desc>
        <Stage>
          <GaugesSkeleton />
        </Stage>
      </Card>
      <Card>
        <Title icon={<ListIcon />}>Processes</Title>
        <Desc>The top processes by CPU, or only the ones you name, with PID and memory.</Desc>
        <Stage>
          <ProcessSkeleton />
        </Stage>
      </Card>
    </div>

    <Card className="border-divide overflow-hidden border-b">
      <Title icon={<ServersIcon />}>Every server, one menu bar</Title>
      <Desc>Add as many servers as you like. The dot always shows the worst of them, and one click switches between them.</Desc>
      <div className="relative mt-8 flex min-h-48 items-center justify-center overflow-hidden rounded-xl py-8">
        <Scale className="rounded-xl" />
        <FleetSkeleton />
      </div>
    </Card>

    <div className="border-divide divide-divide grid grid-cols-1 divide-y border-b md:grid-cols-2 md:divide-x md:divide-y-0">
      <Card>
        <Title icon={<CubeIcon />}>Docker and systemd</Title>
        <Desc>Every container with its usage, and the state of the services you list: nginx, postgres, anything.</Desc>
        <Stage>
          <DockerSkeleton />
        </Stage>
      </Card>
      <Card>
        <Title icon={<FlowIcon />}>n8n workflows</Title>
        <Desc>Running n8n? See which workflows are active and how their last runs went, through its REST API.</Desc>
        <Stage>
          <WorkflowSkeleton />
        </Stage>
      </Card>
    </div>

    <div className="divide-divide grid grid-cols-1 divide-y md:grid-cols-3 md:divide-x md:divide-y-0">
      <Card>
        <Title icon={<TerminalIcon />}>One-click SSH</Title>
        <Desc>Opens Terminal or iTerm2, already connected to the selected server.</Desc>
      </Card>
      <Card>
        <Title icon={<BellIcon />}>Notifications</Title>
        <Desc>A macOS alert when a server stops answering or a watched process dies.</Desc>
      </Card>
      <Card>
        <Title icon={<KeyIcon />}>Secrets in Keychain</Title>
        <Desc>API keys live in the macOS Keychain, never in a plain config file.</Desc>
      </Card>
    </div>
  </Container>
);

