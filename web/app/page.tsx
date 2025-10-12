import { Navigation } from "@/components/navigation";
import { Hero } from "@/components/hero";
import { Features } from "@/components/features";
import { Testimonials } from "@/components/testimonials";
import { CTA } from "@/components/cta";
import { Footer } from "@/components/footer";

export default function Home() {
  return (
    <>
      {/* Skip to main content link for accessibility */}
      <a href="#main-content" className="skip-link">
        Skip to main content
      </a>

      {/* Grain overlay for texture */}
      <div className="grain-overlay" aria-hidden="true" />

      {/* Navigation */}
      <Navigation />

      {/* Main Content */}
      <main id="main-content">
        <Hero />
        <Features />
        <Testimonials />
        <CTA />
      </main>

      {/* Footer */}
      <Footer />
    </>
  );
}
