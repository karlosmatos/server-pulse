import { DivideX } from "@/components/divide";
import { Hero, HeroImage } from "@/components/hero";
import { StackStrip } from "@/components/stack-strip";
import { HowItWorks } from "@/components/how-it-works";
import { Features } from "@/components/features";
import { Trust, Install } from "@/components/trust";
import { FAQs } from "@/components/faqs";
import { CTA } from "@/components/cta";

export default function Home() {
  return (
    <main className="overflow-x-clip">
      <DivideX />
      <Hero />
      <DivideX />
      <HeroImage />
      <DivideX />
      <StackStrip />
      <DivideX />
      <HowItWorks />
      <DivideX />
      <Features />
      <DivideX />
      <Trust />
      <DivideX />
      <Install />
      <DivideX />
      <FAQs />
      <DivideX />
      <CTA />
      <DivideX />
    </main>
  );
}
