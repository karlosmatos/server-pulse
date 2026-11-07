"use client";
import React, { useEffect, useState } from "react";
import { AnimatePresence, motion } from "motion/react";
import { cn } from "@/lib/utils";
import { Container } from "./container";
import { Badge, SectionHeading, SubHeading } from "./typography";
import { DotGrid } from "./scale";
import { KeyIcon, PlusIcon, ServersIcon } from "./icons";
import { MenuBar, type Indicator } from "./mac";

const DURATION = 7000;

const AddServerSkeleton = () => (
  <div className="flex h-full items-center justify-center p-6">
    <div className="shadow-popover w-full max-w-[360px] rounded-xl bg-white p-4 text-[12.5px] dark:bg-neutral-900">
      <p className="mb-3 font-semibold text-neutral-900 dark:text-white">New server</p>
      {[
        ["Name", "prod-api"],
        ["Host", "10.0.4.12"],
        ["User", "deploy"],
        ["SSH key", "~/.ssh/id_ed25519"],
        ["Services", "nginx, postgresql"],
      ].map(([k, v], i) => (
        <motion.div
          key={k}
          initial={{ opacity: 0, y: 6 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.15 + i * 0.12 }}
          className="mb-2 flex items-center gap-3"
        >
          <span className="w-16 text-right text-neutral-500">{k}</span>
          <span className="flex-1 rounded-md border border-black/10 px-2 py-1 font-mono text-[11.5px] text-neutral-800 dark:border-white/10 dark:text-neutral-200">
            {v}
          </span>
        </motion.div>
      ))}
      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 1.1 }}
        className="text-brand-ink dark:text-brand mt-3 flex items-center justify-end gap-1.5 font-medium"
      >
        <span className="bg-brand size-1.5 rounded-full" />
        Connected in 182 ms
      </motion.div>
    </div>
  </div>
);

const lines = [
  { t: "$ uptime", c: "text-neutral-500" },
  { t: "  up 41 days, load 0.42 0.38 0.31", c: "text-neutral-300" },
  { t: "$ free -m && df -h /", c: "text-neutral-500" },
  { t: "  mem 3174/8192   disk 41G/80G 51%", c: "text-neutral-300" },
  { t: "$ docker stats --no-stream", c: "text-neutral-500" },
  { t: "  api 4.2%  postgres 1.8%  redis 0.3%", c: "text-neutral-300" },
  { t: "$ systemctl is-active nginx", c: "text-neutral-500" },
  { t: "  active", c: "text-brand" },
];

const PollSkeleton = () => (
  <div className="flex h-full items-center justify-center p-6">
    <div className="min-h-[244px] w-full max-w-[400px] rounded-xl bg-[#0D1016] p-4 font-mono text-[12px] leading-relaxed shadow-2xl">
      <p className="mb-2 text-neutral-600"># every 30 s · prod-api · read-only</p>
      {lines.map((l, i) => (
        <motion.p
          key={i}
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.2 + i * 0.35, duration: 0.15 }}
          className={cn("whitespace-pre", l.c)}
        >
          {l.t}
        </motion.p>
      ))}
    </div>
  </div>
);

const states: (Indicator & { label: string })[] = [
  { kind: "ok", label: "All three servers online" },
  { kind: "warn", count: 1, label: "staging: nginx failed" },
  { kind: "ok", label: "Fixed. Back to green." },
];

const DotSkeleton = () => {
  const [i, setI] = useState(0);
  useEffect(() => {
    const t = setInterval(() => setI((x) => (x + 1) % states.length), 2000);
    return () => clearInterval(t);
  }, []);
  return (
    <div className="flex h-full flex-col items-center justify-center gap-5 p-6">
      <div className="shadow-aceternity w-full max-w-[360px] overflow-hidden rounded-lg bg-white/80 backdrop-blur dark:bg-neutral-900/80">
        <MenuBar compact indicator={states[i]} />
      </div>
      <AnimatePresence mode="wait">
        <motion.p
          key={i}
          initial={{ opacity: 0, y: 4 }}
          animate={{ opacity: 1, y: 0 }}
          exit={{ opacity: 0, y: -4 }}
          className="font-mono text-xs text-neutral-500"
        >
          {states[i].label}
        </motion.p>
      </AnimatePresence>
    </div>
  );
};

const tabs = [
  {
    id: "add",
    title: "Add a server",
    description: "Host, user and the SSH key you already use. Pick the services and containers you care about.",
    icon: PlusIcon,
    skeleton: <AddServerSkeleton />,
  },
  {
    id: "poll",
    title: "It checks in over SSH",
    description: "Every 30 seconds it runs a handful of read-only commands. Nothing gets installed on the server.",
    icon: KeyIcon,
    skeleton: <PollSkeleton />,
  },
  {
    id: "dot",
    title: "The dot does the talking",
    description: "Green, amber or red: the worst status across every server, next to your clock.",
    icon: ServersIcon,
    skeleton: <DotSkeleton />,
  },
];

export const HowItWorks = () => {
  const [active, setActive] = useState(0);
  useEffect(() => {
    const t = setTimeout(() => setActive((a) => (a + 1) % tabs.length), DURATION);
    return () => clearTimeout(t);
  }, [active]);

  return (
    <Container id="how" className="border-divide scroll-mt-20 border-x">
      <div className="flex flex-col items-center px-4 pt-16">
        <Badge text="How it works" />
        <SectionHeading className="mt-4">Set up in a minute. Then forget it.</SectionHeading>
        <SubHeading className="mx-auto mt-6 max-w-lg">
          No agent, no account, no dashboard to babysit. If you can ssh in, ServerPulse can watch it.
        </SubHeading>
      </div>

      <div className="border-divide divide-divide mt-16 hidden grid-cols-2 divide-x border-t lg:grid">
        <div className="divide-divide divide-y">
          {tabs.map((tab, i) => (
            <button
              key={tab.id}
              onClick={() => setActive(i)}
              className={cn(
                "group relative flex w-full flex-col items-start overflow-hidden px-12 py-8 text-left transition-colors hover:bg-gray-100 dark:hover:bg-neutral-900",
                i === active && "bg-gray-100/60 dark:bg-neutral-900/60",
              )}
            >
              {i === active && (
                <motion.div
                  key={`loader-${active}`}
                  className="bg-brand absolute inset-x-0 bottom-0 h-0.5"
                  initial={{ width: 0 }}
                  animate={{ width: "100%" }}
                  transition={{ duration: DURATION / 1000, ease: "linear" }}
                />
              )}
              <div
                className={cn(
                  "text-charcoal-700 flex items-center gap-2 font-medium dark:text-neutral-100",
                  i !== active && "group-hover:text-brand-ink dark:group-hover:text-brand",
                )}
              >
                <span className="font-mono text-xs text-neutral-400">0{i + 1}</span>
                <tab.icon className="shrink-0" />
                {tab.title}
              </div>
              <p className="mt-2 text-sm text-gray-600 dark:text-neutral-400">{tab.description}</p>
            </button>
          ))}
        </div>
        <div className="relative min-h-[380px] overflow-hidden">
          <DotGrid className="mask-radial-from-40%" />
          <AnimatePresence mode="wait">
            <motion.div
              key={tabs[active].id}
              className="absolute inset-0"
              initial={{ filter: "blur(10px)", opacity: 0 }}
              animate={{ filter: "blur(0px)", opacity: 1 }}
              exit={{ filter: "blur(10px)", opacity: 0 }}
              transition={{ duration: 0.4 }}
            >
              {tabs[active].skeleton}
            </motion.div>
          </AnimatePresence>
        </div>
      </div>

      <div className="divide-divide border-divide mt-12 flex flex-col divide-y border-t lg:hidden">
        {tabs.map((tab, i) => (
          <div key={tab.id} className="px-4 py-6 md:px-12">
            <div className="text-charcoal-700 flex items-center gap-2 font-medium dark:text-neutral-100">
              <span className="font-mono text-xs text-neutral-400">0{i + 1}</span>
              <tab.icon className="shrink-0" /> {tab.title}
            </div>
            <p className="mt-2 text-sm text-gray-600 dark:text-neutral-400">{tab.description}</p>
            <div className="relative mt-4 h-80 overflow-hidden">
              <DotGrid className="mask-radial-from-40%" />
              {tab.skeleton}
            </div>
          </div>
        ))}
      </div>
    </Container>
  );
};
