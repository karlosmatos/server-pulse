"use client";
import React, { useState } from "react";
import { AnimatePresence, motion } from "motion/react";
import useMeasure from "react-use-measure";
import { Container } from "./container";
import { DivideX } from "./divide";
import { Badge, SectionHeading, SubHeading } from "./typography";
import { Button } from "./button";
import { ChevronDown } from "./icons";
import { site } from "@/lib/site";

const faqs = [
  {
    q: "Do I need to install anything on my servers?",
    a: "No. ServerPulse connects over plain SSH and runs standard commands like uptime, free, df, docker stats and systemctl. If you can ssh in with a key, it works.",
  },
  {
    q: "Which servers does it support?",
    a: "Any Linux machine you can reach over SSH: a VPS, a home lab box or a Raspberry Pi. Docker, systemd and n8n monitoring are optional, per server.",
  },
  {
    q: "Can I use password login?",
    a: "No. ServerPulse uses key-based SSH only, so it never has to store or type a password.",
  },
  {
    q: "Where are my credentials stored?",
    a: "Server settings stay on your Mac. API keys, such as the one for n8n, are stored in the macOS Keychain.",
  },
  {
    q: "How do updates work?",
    a: "The app checks for new versions in the background and installs signed updates. You can also choose Check for Updates… in the popover.",
  },
  {
    q: "What does it cost?",
    a: "Nothing. ServerPulse is free, and the source code is on GitHub.",
  },
];

const Item = ({ q, a, open, onToggle, i }: { q: string; a: string; open: boolean; onToggle: () => void; i: number }) => {
  const [ref, { height }] = useMeasure();
  return (
    <div>
      <button
        type="button"
        aria-expanded={open}
        aria-controls={`faq-${i}`}
        onClick={onToggle}
        className="flex w-full items-center justify-between gap-4 px-6 py-6 text-left md:px-8"
      >
        <span className="text-charcoal-700 font-medium dark:text-neutral-100">{q}</span>
        <motion.span
          className="text-charcoal-700 shadow-aceternity inline-flex size-6 shrink-0 items-center justify-center rounded-md bg-white dark:bg-neutral-950 dark:text-neutral-100"
          initial={false}
          animate={{ rotate: open ? 180 : 0 }}
          transition={{ duration: 0.25 }}
        >
          <ChevronDown />
        </motion.span>
      </button>
      <motion.div
        id={`faq-${i}`}
        role="region"
        initial={false}
        animate={{ height: open ? height : 0, opacity: open ? 1 : 0 }}
        transition={{ height: { duration: 0.35 }, opacity: { duration: 0.2 } }}
        className="overflow-hidden px-6 md:px-8"
      >
        <div ref={ref} className="pb-6">
          <AnimatePresence mode="popLayout">
            {open && (
              <motion.p
                initial={{ y: -6, opacity: 0 }}
                animate={{ y: 0, opacity: 1 }}
                exit={{ y: -6, opacity: 0 }}
                className="max-w-2xl text-gray-600 dark:text-neutral-400"
              >
                {a}
              </motion.p>
            )}
          </AnimatePresence>
        </div>
      </motion.div>
    </div>
  );
};

export const FAQs = () => {
  const [open, setOpen] = useState<Set<number>>(new Set([0]));
  const toggle = (i: number) =>
    setOpen((prev) => {
      const next = new Set(prev);
      if (next.has(i)) next.delete(i);
      else next.add(i);
      return next;
    });
  return (
    <Container id="faq" className="border-divide flex scroll-mt-20 flex-col items-center border-x pt-16">
      <Badge text="FAQ" />
      <SectionHeading className="mt-4">Questions, answered</SectionHeading>
      <SubHeading className="mx-auto mt-6 max-w-lg px-4">
        Something missing? Open an issue on GitHub and it will get an answer.
      </SubHeading>
      <Button variant="secondary" href={site.issues} className="mt-8 mb-12">
        Ask on GitHub
      </Button>
      <DivideX />
      <div className="divide-divide w-full divide-y">
        {faqs.map((f, i) => (
          <Item key={f.q} {...f} i={i} open={open.has(i)} onToggle={() => toggle(i)} />
        ))}
      </div>
    </Container>
  );
};
