import React, { useId } from "react";

type SvgProps = React.SVGProps<SVGSVGElement>;

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

/** The ServerPulse icon: three rack units with status lights, the middle one live. */
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

export const Logo = () => (
  <a href="#top" className="flex items-center gap-2 text-black dark:text-white">
    <StackIcon className="size-7" />
    <span className="text-xl font-medium tracking-tight">ServerPulse</span>
  </a>
);
