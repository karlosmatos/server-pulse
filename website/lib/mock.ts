// One fictional fleet, reused by every illustration so the page reads as one product.
export type Status = "online" | "degraded" | "offline";

export const statusColor: Record<Status, string> = {
  online: "bg-brand",
  degraded: "bg-warn",
  offline: "bg-down",
};

export const statusLabel: Record<Status, string> = {
  online: "Online",
  degraded: "Degraded",
  offline: "Offline",
};

export const servers = [
  { name: "prod-api", host: "10.0.4.12", status: "online" as Status, uptime: "41d 6h" },
  { name: "n8n", host: "n8n.internal", status: "online" as Status, uptime: "12d 3h" },
  { name: "staging", host: "10.0.9.3", status: "degraded" as Status, uptime: "3d 19h" },
];

export const containers = [
  { name: "api", cpu: "4.2%", mem: "312 MB", state: "running" },
  { name: "postgres", cpu: "1.8%", mem: "1.1 GB", state: "running" },
  { name: "redis", cpu: "0.3%", mem: "48 MB", state: "running" },
];

export const services = [
  { name: "nginx", state: "active" },
  { name: "postgresql", state: "active" },
  { name: "fail2ban", state: "active" },
];

export const processes = [
  { pid: 1184, name: "node", cpu: 12.4, mem: 6.1 },
  { pid: 902, name: "postgres", cpu: 4.8, mem: 13.7 },
  { pid: 2231, name: "dockerd", cpu: 1.2, mem: 1.9 },
  { pid: 771, name: "nginx", cpu: 0.6, mem: 0.4 },
];

export const workflows = [
  { name: "Invoice sync", active: true, last: "success", ago: "2m ago" },
  { name: "Lead enrichment", active: true, last: "success", ago: "14m ago" },
  { name: "Nightly backup", active: true, last: "error", ago: "6h ago" },
];
