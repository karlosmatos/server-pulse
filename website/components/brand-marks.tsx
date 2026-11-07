import React, { useId } from "react";

type SvgProps = React.SVGProps<SVGSVGElement>;

/** Flat mark for the navbar and footer: the status dot with a heartbeat cut out. */
export const BeaconMark = (props: SvgProps) => (
  <svg viewBox="0 0 32 32" fill="none" aria-hidden {...props}>
    <circle cx="16" cy="16" r="14.5" stroke="currentColor" strokeOpacity=".22" strokeWidth="2" />
    <circle cx="16" cy="16" r="9.5" className="fill-brand" />
    <path
      d="M8.6 16h3.3l1.5-3.9 2.4 8 1.7-5.6 1 1.5h4.9"
      stroke="white"
      strokeWidth="1.9"
      strokeLinecap="round"
      strokeLinejoin="round"
    />
  </svg>
);

const IconBase = ({ id, children, ...props }: SvgProps & { id: string }) => (
  <svg viewBox="100 100 824 824" aria-hidden {...props}>
    <defs>
      <linearGradient id={`${id}-bg`} x1="0" y1="0" x2="0" y2="1">
        <stop offset="0" stopColor="#1B2131" />
        <stop offset="1" stopColor="#0A0D13" />
      </linearGradient>
    </defs>
    <rect x="100" y="100" width="824" height="824" rx="185" fill={`url(#${id}-bg)`} />
    <rect
      x="101.5"
      y="101.5"
      width="821"
      height="821"
      rx="183.5"
      fill="none"
      stroke="#fff"
      strokeOpacity=".08"
      strokeWidth="3"
    />
    {children}
  </svg>
);

/** A · Beacon: the recommended app icon. */
export const BeaconIcon = (props: SvgProps) => {
  const id = useId().replace(/:/g, "");
  return (
    <IconBase id={id} {...props}>
      <defs>
        <radialGradient id={`${id}-core`} cx="0.4" cy="0.35" r="0.75">
          <stop offset="0" stopColor="#6CF5AE" />
          <stop offset="1" stopColor="#16B866" />
        </radialGradient>
      </defs>
      <circle cx="512" cy="512" r="300" fill="none" stroke="#34E08A" strokeOpacity=".12" strokeWidth="14" />
      <circle cx="512" cy="512" r="215" fill="none" stroke="#34E08A" strokeOpacity=".26" strokeWidth="16" />
      <circle cx="512" cy="512" r="150" fill="#34E08A" opacity=".18" />
      <circle cx="512" cy="512" r="135" fill={`url(#${id}-core)`} />
      <path
        d="M398 512h58l26-66 40 136 28-96 17 26h59"
        fill="none"
        stroke="#0A0D13"
        strokeWidth="26"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </IconBase>
  );
};

/** B · Stack: three rack units, each with its own status light. */
export const StackIcon = (props: SvgProps) => {
  const id = useId().replace(/:/g, "");
  return (
    <IconBase id={id} {...props}>
      <g fill="#232B3C" stroke="#fff" strokeOpacity=".07" strokeWidth="3">
        <rect x="232" y="262" width="560" height="130" rx="40" />
        <rect x="232" y="447" width="560" height="130" rx="40" />
        <rect x="232" y="632" width="560" height="130" rx="40" />
      </g>
      <path d="M292 327h120M292 697h120" stroke="#566179" strokeWidth="18" strokeLinecap="round" />
      <path
        d="M286 512h92l26-50 34 96 30-74 16 28h112"
        fill="none"
        stroke="#34E08A"
        strokeWidth="20"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <circle cx="722" cy="327" r="24" fill="#34E08A" />
      <circle cx="722" cy="512" r="24" fill="#34E08A" />
      <circle cx="722" cy="697" r="24" fill="#F5B841" />
    </IconBase>
  );
};

/** C · Prompt: a shell prompt whose cursor is a heartbeat. */
export const PromptIcon = (props: SvgProps) => {
  const id = useId().replace(/:/g, "");
  return (
    <IconBase id={id} {...props}>
      <path
        d="M290 360l130 100-130 100"
        fill="none"
        stroke="#E8ECF2"
        strokeWidth="50"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <path
        d="M470 640h96l36-90 46 160 40-110 20 40h66"
        fill="none"
        stroke="#34E08A"
        strokeWidth="46"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </IconBase>
  );
};

export const Logo = () => (
  <a href="#top" className="flex items-center gap-2 text-black dark:text-white">
    <BeaconMark className="size-7" />
    <span className="text-xl font-medium tracking-tight">ServerPulse</span>
  </a>
);
