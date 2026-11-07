"use client";
import React, { useState } from "react";
import Link from "next/link";
import { AnimatePresence, motion, useScroll, useSpring, useTransform } from "motion/react";
import { Container } from "./container";
import { Logo } from "./brand-marks";
import { Button } from "./button";
import { ModeToggle } from "./mode-toggle";
import { AppleIcon, CloseIcon, MenuIcon } from "./icons";
import { site } from "@/lib/site";

const items = [
  { title: "Features", href: "/#features" },
  { title: "How it works", href: "/#how" },
  { title: "FAQ", href: "/#faq" },
  { title: "Brand", href: "/brand" },
];

const NavLinks = () => (
  <div className="flex items-center gap-8">
    {items.map((item) => (
      <Link
        key={item.title}
        href={item.href}
        className="font-medium text-gray-600 transition duration-200 hover:text-neutral-900 dark:text-gray-300 dark:hover:text-white"
      >
        {item.title}
      </Link>
    ))}
  </div>
);

const Actions = () => (
  <div className="flex items-center gap-2">
    <ModeToggle />
    <Button href={site.download}>
      <AppleIcon className="size-4" />
      Download
    </Button>
  </div>
);

export const Navbar = () => {
  const { scrollY } = useScroll();
  const y = useSpring(useTransform(scrollY, [100, 120], [-100, 10]), { stiffness: 300, damping: 30 });
  const [open, setOpen] = useState(false);

  return (
    <Container as="nav">
      <motion.div
        style={{ y }}
        className="shadow-aceternity fixed inset-x-0 top-0 z-50 mx-auto hidden max-w-[calc(80rem-4rem)] items-center justify-between bg-white/80 px-3 py-2 backdrop-blur-sm md:flex xl:rounded-2xl dark:bg-neutral-900/80 dark:shadow-[0px_2px_0px_0px_var(--color-neutral-800),0px_-2px_0px_0px_var(--color-neutral-800)]"
      >
        <Logo />
        <NavLinks />
        <Actions />
      </motion.div>

      <div className="hidden items-center justify-between px-4 py-4 md:flex">
        <Logo />
        <NavLinks />
        <Actions />
      </div>

      <div className="flex items-center justify-between p-3 md:hidden">
        <Logo />
        <button
          onClick={() => setOpen(true)}
          className="shadow-aceternity flex size-8 items-center justify-center rounded-md"
          aria-label="Open menu"
        >
          <MenuIcon className="size-4 text-gray-600 dark:text-gray-300" />
        </button>
        <AnimatePresence>
          {open && (
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              transition={{ duration: 0.2 }}
              className="fixed inset-0 z-[60] bg-white dark:bg-neutral-950"
            >
              <div className="flex items-center justify-between p-3">
                <Logo />
                <button
                  onClick={() => setOpen(false)}
                  className="shadow-aceternity flex size-8 items-center justify-center rounded-md"
                  aria-label="Close menu"
                >
                  <CloseIcon className="size-4 text-gray-600 dark:text-gray-300" />
                </button>
              </div>
              <div className="divide-divide border-divide mt-6 flex flex-col divide-y border-t">
                {items.map((item, i) => (
                  <Link
                    key={item.title}
                    href={item.href}
                    onClick={() => setOpen(false)}
                    className="px-4 py-3 font-medium text-gray-600 dark:text-gray-300"
                  >
                    <motion.span
                      className="block"
                      initial={{ opacity: 0, y: 10 }}
                      animate={{ opacity: 1, y: 0 }}
                      transition={{ duration: 0.2, delay: i * 0.06 }}
                    >
                      {item.title}
                    </motion.span>
                  </Link>
                ))}
              </div>
              <div className="p-4">
                <Button href={site.download} className="w-full">
                  <AppleIcon className="size-4" />
                  Download for Mac
                </Button>
              </div>
              <div className="absolute right-4 bottom-4">
                <ModeToggle />
              </div>
            </motion.div>
          )}
        </AnimatePresence>
      </div>
    </Container>
  );
};
