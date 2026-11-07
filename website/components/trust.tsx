import { Container } from "./container";
import { DivideX } from "./divide";
import { Eyebrow, SectionHeading, SubHeading } from "./typography";
import { Button } from "./button";
import { GithubIcon, KeyIcon, RefreshIcon, ServersIcon, ShieldIcon } from "./icons";
import { site } from "@/lib/site";

const points = [
  { icon: ServersIcon, title: "No agent, no daemon", body: "It runs a few read-only commands over SSH and reads the output." },
  { icon: KeyIcon, title: "Your keys, your config", body: "Uses the SSH keys and hosts you already have. Key-based auth only." },
  { icon: ShieldIcon, title: "No cloud, no account", body: "Data goes straight from your server to your Mac. Nothing is sent anywhere else." },
];

export const Trust = () => (
  <>
    <Container className="border-divide border-x">
      <Eyebrow className="pt-10 pb-6 md:pt-20 md:pb-10">No agent · No cloud · No account</Eyebrow>
    </Container>
    <DivideX />
    <Container className="border-divide grid grid-cols-1 gap-10 border-x bg-gray-100 px-6 py-12 md:grid-cols-2 md:px-8 md:py-16 dark:bg-neutral-900">
      <div>
        <SectionHeading className="text-left">Nothing to install on your servers</SectionHeading>
        <SubHeading className="mt-4 max-w-md text-left">
          ServerPulse is a small native Mac app written in Swift. Every line is on GitHub, so you can read exactly
          which commands it runs.
        </SubHeading>
        <Button variant="secondary" href={site.repo} className="mt-6">
          <GithubIcon className="size-4" />
          Read the source
        </Button>
      </div>
      <div className="grid gap-6">
        {points.map((p) => (
          <div key={p.title} className="flex gap-4">
            <span className="shadow-aceternity flex size-10 shrink-0 items-center justify-center rounded-lg bg-white dark:bg-neutral-950">
              <p.icon className="text-brand-ink dark:text-brand size-4" />
            </span>
            <div>
              <p className="font-medium text-neutral-900 dark:text-white">{p.title}</p>
              <p className="text-sm text-gray-600 dark:text-neutral-400">{p.body}</p>
            </div>
          </div>
        ))}
      </div>
    </Container>
  </>
);

const steps = [
  { title: "Download the DMG", body: "Signed with a Developer ID and notarized by Apple, so it opens without warnings." },
  { title: "Drag it to Applications", body: "Launch it, add your first server, and the dot appears next to your clock." },
  { title: "It keeps itself current", body: "New versions arrive through signed, verified updates. You can also check from the popover." },
];

export const Install = () => (
  <Container className="border-divide border-x">
    <div className="divide-divide grid grid-cols-1 divide-y md:grid-cols-3 md:divide-x md:divide-y-0">
      {steps.map((s, i) => (
        <div key={s.title} className="p-6 md:p-8">
          <span className="text-brand-ink dark:text-brand font-mono text-sm">0{i + 1}</span>
          <p className="text-charcoal-700 mt-3 flex items-center gap-2 text-lg font-medium dark:text-neutral-100">
            {s.title}
            {i === 2 && <RefreshIcon className="text-neutral-400" />}
          </p>
          <p className="mt-2 text-gray-600 dark:text-neutral-400">{s.body}</p>
        </div>
      ))}
    </div>
  </Container>
);
