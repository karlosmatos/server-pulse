import { Container } from "./container";
import { DivideX } from "./divide";
import { Eyebrow } from "./typography";

const stack = ["Ubuntu", "Debian", "Docker", "systemd", "nginx", "PostgreSQL", "n8n", "iTerm2"];

export const StackStrip = () => (
  <>
    <Container className="border-divide border-x">
      <Eyebrow className="py-8 md:py-10">Fluent in the stack you already run</Eyebrow>
    </Container>
    <DivideX />
    <Container className="border-divide divide-divide grid grid-cols-2 divide-x border-x sm:grid-cols-4 lg:grid-cols-8">
      {stack.map((name, i) => (
        <div
          key={name}
          className="border-divide flex h-20 items-center justify-center font-mono text-sm text-neutral-500 transition-colors hover:bg-gray-100 hover:text-neutral-900 max-lg:[&:nth-child(-n+4)]:border-b max-sm:[&:nth-child(-n+6)]:border-b dark:text-neutral-400 dark:hover:bg-neutral-900 dark:hover:text-white"
          style={{ transitionDelay: `${i * 10}ms` }}
        >
          {name}
        </div>
      ))}
    </Container>
  </>
);
