import type { Metadata } from "next";
import type React from "react";
import { Container } from "@/components/container";
import { DivideX } from "@/components/divide";
import { Badge, Eyebrow, Heading, SubHeading } from "@/components/typography";
import {
  BeaconIcon,
  BeaconMark,
  PromptIcon,
  StackDuoIcon,
  StackIcon,
  StackLightsIcon,
  StackSignalIcon,
} from "@/components/brand-marks";
import { MenuBar } from "@/components/mac";
import { Scale } from "@/components/scale";
import { CornerDots } from "@/components/dots";
import { cn } from "@/lib/utils";

export const metadata: Metadata = { title: "ServerPulse · Brand" };

type Concept = {
  key: string;
  name: string;
  Icon: (p: React.SVGProps<SVGSVGElement>) => React.JSX.Element;
  body: string;
};

const simplified: Concept[] = [
  {
    key: "S1",
    name: "Lights",
    Icon: StackLightsIcon,
    body: "Three rack units, one status light each: two green, one amber. Nothing else. It reads as “servers” at any size, and the amber light hints at what the app is for.",
  },
  {
    key: "S2",
    name: "Duo",
    Icon: StackDuoIcon,
    body: "Two taller units with big lights. The boldest of the three at 16 px, but “two” says less about many servers than “three”.",
  },
  {
    key: "S3",
    name: "Signal",
    Icon: StackSignalIcon,
    body: "One unit lit and pinging, the others idle. Calmer, and the lit light is the same green dot you see in the menu bar.",
  },
];

const earlier: Concept[] = [
  {
    key: "A",
    name: "Beacon",
    Icon: BeaconIcon,
    body: "The menu bar dot with a heartbeat cut out. Ties to the indicator, but the heartbeat reads as health rather than servers.",
  },
  {
    key: "B",
    name: "Stack",
    Icon: StackIcon,
    body: "The original rack with a pulse line and vents. Accurate, but the detail turns to mush below 32 px.",
  },
  {
    key: "C",
    name: "Prompt",
    Icon: PromptIcon,
    body: "A shell prompt whose cursor is a heartbeat. It nods to SSH, but it looks like many terminal apps.",
  },
];

const ConceptRow = ({ c, highlight }: { c: Concept; highlight?: boolean }) => (
  <>
    <Container className="border-divide divide-divide grid grid-cols-1 border-x md:grid-cols-[minmax(0,5fr)_minmax(0,7fr)] md:divide-x">
      <div className="relative flex items-center justify-center bg-gray-100 p-10 md:p-14 dark:bg-neutral-900">
        {highlight && <CornerDots />}
        <Scale />
        <c.Icon className="relative size-48 drop-shadow-2xl md:size-56" />
      </div>
      <div className="flex flex-col justify-center p-6 md:p-10">
        <div className="flex items-center gap-3">
          <span className="font-mono text-sm text-neutral-400">{c.key}</span>
          <h2 className="text-charcoal-700 text-3xl font-medium tracking-tight dark:text-neutral-100">{c.name}</h2>
        </div>
        <p className="mt-3 max-w-lg text-gray-600 dark:text-neutral-400">{c.body}</p>
        <div className="mt-8 flex flex-wrap items-end gap-6">
          {[128, 64, 32, 16].map((s) => (
            <figure key={s} className="flex flex-col items-center gap-2">
              <c.Icon style={{ width: s, height: s }} />
              <figcaption className="font-mono text-[11px] text-neutral-400">{s}</figcaption>
            </figure>
          ))}
          <figure className="flex flex-col items-center gap-2">
            <div className="flex items-end gap-2 rounded-2xl bg-black/5 px-3 py-2 dark:bg-white/10">
              <span className="size-11 rounded-[11px] bg-black/10 dark:bg-white/10" />
              <c.Icon className="size-14" />
              <span className="size-11 rounded-[11px] bg-black/10 dark:bg-white/10" />
            </div>
            <figcaption className="font-mono text-[11px] text-neutral-400">Dock</figcaption>
          </figure>
        </div>
      </div>
    </Container>
    <DivideX />
  </>
);

const SectionLabel = ({ children }: { children: React.ReactNode }) => (
  <>
    <Container className="border-divide border-x">
      <Eyebrow className="py-8 md:py-10">{children}</Eyebrow>
    </Container>
    <DivideX />
  </>
);

const palette = [
  { name: "Signal", hex: "#12B76A", note: "Online, brand" },
  { name: "Warn", hex: "#F5A524", note: "Degraded" },
  { name: "Down", hex: "#F04438", note: "Offline" },
  { name: "Ink", hex: "#0A0D13", note: "Icon ground" },
  { name: "Slate", hex: "#1B2131", note: "Icon ground" },
  { name: "Charcoal", hex: "#202020", note: "Text, buttons" },
];

export default function Brand() {
  return (
    <main className="overflow-x-clip">
      <DivideX />
      <Container className="border-divide flex flex-col items-center border-x px-4 pt-12 pb-12 md:pt-24 md:pb-16">
        <Badge text="Brand proposal" />
        <Heading className="mt-5">Logo concepts</Heading>
        <SubHeading className="mx-auto mt-6 max-w-lg">
          The rack won: it says servers, not health. Here it is stripped down to units and status lights, in three
          variants, with the earlier directions below for comparison.
        </SubHeading>
      </Container>
      <DivideX />

      <SectionLabel>Stack, simplified</SectionLabel>
      <Container className="border-divide divide-divide grid grid-cols-3 divide-x border-x">
        {simplified.map((c) => (
          <div key={c.key} className="flex flex-col items-center gap-3 p-6 md:p-10">
            <c.Icon className="size-20 md:size-32" />
            <span className="font-mono text-xs text-neutral-500">
              {c.key} · {c.name}
            </span>
          </div>
        ))}
      </Container>
      <DivideX />
      {simplified.map((c, i) => (
        <ConceptRow key={c.key} c={c} highlight={i === 0} />
      ))}

      <SectionLabel>Earlier directions</SectionLabel>
      {earlier.map((c) => (
        <ConceptRow key={c.key} c={c} />
      ))}

      <Container className="border-divide border-x">
        <Eyebrow className="py-8 md:py-10">The mark in use</Eyebrow>
      </Container>
      <DivideX />
      <Container className="border-divide divide-divide grid grid-cols-1 border-x md:grid-cols-3 md:divide-x">
        <div className="flex items-center justify-center gap-3 bg-white p-10 text-black">
          <BeaconMark className="size-10" />
          <span className="text-3xl font-medium tracking-tight">ServerPulse</span>
        </div>
        <div className="flex items-center justify-center gap-3 bg-[#0A0D13] p-10 text-white">
          <BeaconMark className="size-10" />
          <span className="text-3xl font-medium tracking-tight">ServerPulse</span>
        </div>
        <div className="flex flex-col items-center justify-center gap-3 bg-gray-100 p-10 dark:bg-neutral-900">
          <div className="shadow-aceternity w-full max-w-[260px] overflow-hidden rounded-lg bg-white/80 dark:bg-neutral-950/80">
            <MenuBar compact indicator={{ kind: "ok" }} />
          </div>
          <div className="shadow-aceternity w-full max-w-[260px] overflow-hidden rounded-lg bg-white/80 dark:bg-neutral-950/80">
            <MenuBar compact indicator={{ kind: "warn", count: 1 }} />
          </div>
          <p className="font-mono text-[11px] text-neutral-400">Menu bar indicator</p>
        </div>
      </Container>
      <DivideX />

      <Container className="border-divide border-x">
        <Eyebrow className="py-8 md:py-10">Colour</Eyebrow>
      </Container>
      <DivideX />
      <Container className="border-divide divide-divide grid grid-cols-2 border-x md:grid-cols-6 md:divide-x">
        {palette.map((c, i) => (
          <div key={c.name} className={cn("p-4 md:p-6", i < 4 && "max-md:border-divide max-md:border-b")}>
            <div className="shadow-aceternity h-20 rounded-lg" style={{ background: c.hex }} />
            <p className="mt-3 font-medium text-neutral-900 dark:text-white">{c.name}</p>
            <p className="font-mono text-xs text-neutral-500">{c.hex}</p>
            <p className="text-xs text-neutral-400">{c.note}</p>
          </div>
        ))}
      </Container>
      <DivideX />
    </main>
  );
}
