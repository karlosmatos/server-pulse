import React from "react";

type P = React.SVGProps<SVGSVGElement>;
const base = {
  viewBox: "0 0 16 16",
  fill: "none",
  stroke: "currentColor",
  strokeWidth: 1.33,
  strokeLinecap: "round" as const,
  strokeLinejoin: "round" as const,
  width: 16,
  height: 16,
};

export const GaugeIcon = (p: P) => (<svg {...base} {...p}><path d="M2.5 11.5a5.5 5.5 0 1 1 11 0" /><path d="M8 11.5l2.5-3" /></svg>);
export const ListIcon = (p: P) => (<svg {...base} {...p}><path d="M2.5 4h11M2.5 8h11M2.5 12h7" /></svg>);
export const CubeIcon = (p: P) => (<svg {...base} {...p}><path d="M2 5l6-3 6 3v6l-6 3-6-3z" /><path d="M2 5l6 3 6-3M8 8v6" /></svg>);
export const CogIcon = (p: P) => (<svg {...base} {...p}><circle cx="8" cy="8" r="2" /><path d="M8 1.5v2M8 12.5v2M1.5 8h2M12.5 8h2M3.4 3.4l1.4 1.4M11.2 11.2l1.4 1.4M3.4 12.6l1.4-1.4M11.2 4.8l1.4-1.4" /></svg>);
export const FlowIcon = (p: P) => (<svg {...base} {...p}><circle cx="3.5" cy="8" r="1.75" /><circle cx="12.5" cy="4" r="1.75" /><circle cx="12.5" cy="12" r="1.75" /><path d="M5.25 8H8l2.8-3.3M8 8l2.8 3.3" /></svg>);
export const TerminalIcon = (p: P) => (<svg {...base} {...p}><path d="M3 5l3 3-3 3M8.5 11.5h4.5" /></svg>);
export const BellIcon = (p: P) => (<svg {...base} {...p}><path d="M4 6a4 4 0 1 1 8 0c0 4.5 2 6 2 6H2s2-1.5 2-6M6.9 14a1.3 1.3 0 0 0 2.2 0" /></svg>);
export const ServersIcon = (p: P) => (<svg {...base} {...p}><rect x="2" y="2.5" width="12" height="4.5" rx="1.2" /><rect x="2" y="9" width="12" height="4.5" rx="1.2" /><path d="M4.5 4.75h.01M4.5 11.25h.01" /></svg>);
export const KeyIcon = (p: P) => (<svg {...base} {...p}><circle cx="5" cy="11" r="2.75" /><path d="M7 9l6-6M11 5l1.5 1.5M9.5 6.5L11 8" /></svg>);
export const ShieldIcon = (p: P) => (<svg {...base} {...p}><path d="M8 1.75l5 2v4c0 3.1-2.1 5.4-5 6.5-2.9-1.1-5-3.4-5-6.5v-4z" /><path d="M5.75 8l1.5 1.5 3-3" /></svg>);
export const RefreshIcon = (p: P) => (<svg {...base} {...p}><path d="M13.5 8A5.5 5.5 0 0 1 3.6 11.3M2.5 8a5.5 5.5 0 0 1 9.9-3.3" /><path d="M12.5 2v2.75H9.75M3.5 14v-2.75h2.75" /></svg>);
export const PlusIcon = (p: P) => (<svg {...base} {...p}><path d="M8 3v10M3 8h10" /></svg>);
export const ClockIcon = (p: P) => (<svg {...base} {...p}><circle cx="8" cy="8" r="5.75" /><path d="M8 5v3l2 1.25" /></svg>);
export const ChevronDown = (p: P) => (<svg {...base} {...p}><path d="M4 6.25l4 4 4-4" /></svg>);
export const ArrowRight = (p: P) => (<svg {...base} {...p}><path d="M3 8h10M9 4l4 4-4 4" /></svg>);
export const MenuIcon = (p: P) => (<svg {...base} {...p}><path d="M2.5 5h11M2.5 11h11" /></svg>);
export const CloseIcon = (p: P) => (<svg {...base} {...p}><path d="M4 4l8 8M12 4l-8 8" /></svg>);
export const SunIcon = (p: P) => (<svg {...base} {...p}><circle cx="8" cy="8" r="2.75" /><path d="M8 1.5v1.25M8 13.25v1.25M1.5 8h1.25M13.25 8h1.25M3.4 3.4l.9.9M11.7 11.7l.9.9M3.4 12.6l.9-.9M11.7 4.3l.9-.9" /></svg>);
export const MoonIcon = (p: P) => (<svg {...base} {...p}><path d="M13.5 9.5A5.75 5.75 0 1 1 6.5 2.5a4.5 4.5 0 0 0 7 7z" /></svg>);
export const GithubIcon = (p: P) => (
  <svg viewBox="0 0 16 16" width={16} height={16} fill="currentColor" {...p}>
    <path d="M8 .2a8 8 0 0 0-2.5 15.6c.4 0 .5-.2.5-.4v-1.5c-2.2.5-2.7-1-2.7-1-.4-.9-.9-1.2-.9-1.2-.7-.5.1-.5.1-.5.8.1 1.2.8 1.2.8.7 1.3 1.9.9 2.4.7 0-.5.3-.9.5-1.1-1.8-.2-3.6-.9-3.6-4 0-.9.3-1.6.8-2.1 0-.2-.4-1 .1-2.1 0 0 .7-.2 2.2.8a7.4 7.4 0 0 1 4 0c1.5-1 2.2-.8 2.2-.8.4 1.1.2 1.9.1 2.1.5.6.8 1.3.8 2.1 0 3.1-1.9 3.8-3.6 4 .3.3.6.8.6 1.5v2.2c0 .2.1.5.6.4A8 8 0 0 0 8 .2z" />
  </svg>
);
export const AppleIcon = (p: P) => (
  <svg viewBox="0 0 24 24" width={16} height={16} fill="currentColor" {...p}>
    <path d="M16.4 12.6c0-2.6 2.1-3.8 2.2-3.9-1.2-1.8-3.1-2-3.7-2-1.6-.2-3.1.9-3.9.9s-2-.9-3.4-.9c-1.7 0-3.3 1-4.2 2.6-1.8 3.1-.5 7.7 1.3 10.2.9 1.2 1.9 2.6 3.2 2.6 1.3-.1 1.8-.8 3.3-.8s2 .8 3.4.8c1.4 0 2.3-1.3 3.1-2.5 1-1.4 1.4-2.8 1.4-2.9-.1 0-2.7-1-2.7-4.1zM13.9 5c.7-.9 1.2-2 1-3.2-1 0-2.3.7-3 1.6-.7.8-1.2 2-1.1 3.1 1.2.1 2.3-.6 3.1-1.5z" />
  </svg>
);
export const WarnTriangle = (p: P) => (
  <svg viewBox="0 0 16 16" width={16} height={16} fill="currentColor" {...p}>
    <path d="M8 1.5L.75 14.5h14.5zM7.25 6h1.5v4.25h-1.5zm0 5.5h1.5V13h-1.5z" />
  </svg>
);
