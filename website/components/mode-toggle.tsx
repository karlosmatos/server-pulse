"use client";
import { useTheme } from "next-themes";
import { MoonIcon, SunIcon } from "./icons";

export const ModeToggle = () => {
  const { resolvedTheme, setTheme } = useTheme();
  return (
    <button
      onClick={() => setTheme(resolvedTheme === "dark" ? "light" : "dark")}
      className="relative flex items-center justify-center rounded-xl p-2 text-gray-600 hover:bg-gray-200 dark:text-gray-300 dark:hover:bg-neutral-800"
    >
      <SunIcon className="size-4 scale-100 rotate-0 transition-all dark:scale-0 dark:-rotate-90" />
      <MoonIcon className="absolute size-4 scale-0 rotate-90 transition-all dark:scale-100 dark:rotate-0" />
      <span className="sr-only">Toggle theme</span>
    </button>
  );
};
