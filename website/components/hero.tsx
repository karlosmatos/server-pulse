"use client";
import React, { useEffect, useRef, useState } from "react";
import { motion, useMotionValue, useSpring, useTransform } from "motion/react";
import { Container } from "./container";
import { Badge, Heading, SubHeading } from "./typography";
import { Button } from "./button";
import { AppleIcon, GithubIcon } from "./icons";
import { CornerDots } from "./dots";
import { Scale } from "./scale";
import { MenuBar, Notification, Popover } from "./mac";
import { site } from "@/lib/site";

export const Hero = () => (
  <Container id="top" className="border-divide flex flex-col items-center border-x px-4 pt-12 pb-12 md:pt-32 md:pb-20">
    <Badge text="A menu bar app for people who run their own servers" />
    <Heading className="mt-5">
      Your servers, <br className="hidden sm:block" />
      <span className="text-brand">one dot</span> away.
    </Heading>
    <SubHeading className="mx-auto mt-6 max-w-xl">
      ServerPulse watches your Linux boxes over SSH and folds them into a single dot next to your clock.
      Green means get back to work.
    </SubHeading>
    <div className="mt-8 flex flex-col items-stretch gap-3 sm:flex-row sm:items-center">
      <Button href={site.download}>
        <AppleIcon className="size-4" />
        Download for Mac
      </Button>
      <Button variant="secondary" href={site.repo}>
        <GithubIcon className="size-4" />
        View source
      </Button>
    </div>
    <p className="mt-6 font-mono text-xs text-gray-600 dark:text-neutral-500">
      Free · macOS 14 Sonoma+ · Notarized by Apple · Updates itself
    </p>
  </Container>
);

export const HeroImage = () => {
  const ref = useRef<HTMLDivElement>(null);
  const mx = useMotionValue(0);
  const my = useMotionValue(0);
  const sx = useSpring(mx, { stiffness: 300, damping: 30 });
  const sy = useSpring(my, { stiffness: 300, damping: 30 });
  const tx = useTransform(sx, [-0.5, 0.5], [-14, 14]);
  const ty = useTransform(sy, [-0.5, 0.5], [-10, 10]);
  // The notification and the menu bar tell the same story: staging degrades, the dot turns amber.
  const [alert, setAlert] = useState(false);
  useEffect(() => {
    const t = setTimeout(() => setAlert(true), 2200);
    return () => clearTimeout(t);
  }, []);

  const onMove = (e: React.MouseEvent<HTMLDivElement>) => {
    const r = ref.current?.getBoundingClientRect();
    if (!r) return;
    mx.set((e.clientX - r.left) / r.width - 0.5);
    my.set((e.clientY - r.top) / r.height - 0.5);
  };

  return (
    <Container className="border-divide relative border-x bg-gray-100 p-2 md:p-4 lg:p-8 dark:bg-neutral-900">
      <CornerDots />
      <div
        ref={ref}
        onMouseMove={onMove}
        onMouseLeave={() => {
          mx.set(0);
          my.set(0);
        }}
        className="relative overflow-hidden rounded-xl bg-white dark:bg-neutral-950"
      >
        <Scale className="rounded-xl" />
        <MenuBar
          indicator={alert ? { kind: "warn", count: 1 } : { kind: "ok" }}
          className="relative z-10 border-b border-black/5 bg-white/70 backdrop-blur-md dark:border-white/10 dark:bg-neutral-900/70"
        />
        <div className="relative h-[520px] lg:h-[500px]">
          <motion.div
            initial={{ opacity: 0, y: -8, scale: 0.98 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            transition={{ duration: 0.4, delay: 0.6, ease: "easeOut" }}
            style={{ x: tx, y: ty }}
            className="absolute top-2 right-1/2 translate-x-1/2 sm:right-[48px] sm:translate-x-0"
          >
            <Popover className="w-[min(340px,calc(100vw-48px))]" />
          </motion.div>

          <motion.div
            initial={{ opacity: 0, x: -24 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ duration: 0.5, delay: 2, ease: "easeOut" }}
            className="absolute bottom-8 left-8 hidden lg:block"
          >
            <Notification title="ServerPulse" body="staging: nginx failed. The dot turned amber." />
          </motion.div>

          <motion.pre
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ duration: 0.5, delay: 1.1 }}
            className="absolute top-10 left-8 hidden w-[360px] rounded-xl bg-[#0D1016] p-4 font-mono text-[12px] leading-relaxed text-neutral-400 shadow-2xl lg:block"
          >
            <span className="mb-3 flex gap-1.5">
              <span className="size-2.5 rounded-full bg-[#FF5F57]" />
              <span className="size-2.5 rounded-full bg-[#FEBC2E]" />
              <span className="size-2.5 rounded-full bg-[#28C840]" />
            </span>
            <span className="text-neutral-600"># opened from the popover</span>
            {"\n"}
            <span className="text-brand">karel@mac</span> ~ % ssh deploy@10.0.4.12
            {"\n"}Welcome to Ubuntu 24.04 LTS
            {"\n"}
            <span className="text-neutral-200">deploy@prod-api</span>:~$ <span className="animate-blink">▍</span>
          </motion.pre>
        </div>
      </div>
    </Container>
  );
};
