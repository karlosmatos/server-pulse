import Link from "next/link";
import { Container } from "./container";
import { Logo } from "./brand-marks";
import { Button } from "./button";
import { AppleIcon, GithubIcon } from "./icons";
import { site } from "@/lib/site";

const columns = [
  {
    title: "Product",
    links: [
      { title: "Features", href: "/#features" },
      { title: "How it works", href: "/#how" },
      { title: "FAQ", href: "/#faq" },
      { title: "Brand", href: "/brand" },
    ],
  },
  {
    title: "Resources",
    links: [
      { title: "Source code", href: site.repo },
      { title: "Releases", href: site.releases },
      { title: "Report an issue", href: site.issues },
    ],
  },
];

export const Footer = () => (
  <Container>
    <div className="grid grid-cols-2 gap-y-10 px-4 py-16 md:grid-cols-6 md:py-20">
      <div className="col-span-2 md:col-span-4">
        <Logo />
        <p className="mt-4 max-w-sm text-sm text-gray-600 dark:text-neutral-400">
          Your Linux servers, folded into one dot in the macOS menu bar.
        </p>
        <Button href={site.download} className="mt-5">
          <AppleIcon className="size-4" />
          Download for Mac
        </Button>
      </div>
      {columns.map((col) => (
        <div key={col.title} className="flex flex-col gap-3">
          <p className="text-sm font-medium text-gray-600">{col.title}</p>
          {col.links.map((l) =>
            l.href.startsWith("http") ? (
              <a key={l.title} href={l.href} className="text-footer-link text-sm font-medium hover:text-black dark:hover:text-white">
                {l.title}
              </a>
            ) : (
              <Link key={l.title} href={l.href} className="text-footer-link text-sm font-medium hover:text-black dark:hover:text-white">
                {l.title}
              </Link>
            ),
          )}
        </div>
      ))}
    </div>
    <div className="flex flex-col items-center justify-between gap-4 px-4 pb-10 md:flex-row">
      <p className="text-footer-link text-sm">© 2026 Karel Malý. Made for people who run their own servers.</p>
      <a href={site.repo} className="text-footer-link hover:text-black dark:hover:text-white" aria-label="GitHub">
        <GithubIcon className="size-5" />
      </a>
    </div>
  </Container>
);
