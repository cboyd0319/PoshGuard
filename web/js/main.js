// PoshGuard - Static HTML Main JavaScript
// Minimal vanilla JavaScript for interactive features

(function() {
    'use strict';

    // ===== Navigation Scroll Behavior =====
    function initNavigation() {
        const nav = document.querySelector('.navigation');
        let lastScroll = 0;

        window.addEventListener('scroll', function() {
            const currentScroll = window.pageYOffset;
            
            if (currentScroll > 20) {
                nav.classList.add('scrolled');
            } else {
                nav.classList.remove('scrolled');
            }
            
            lastScroll = currentScroll;
        }, { passive: true });
    }

    // ===== Testimonials Carousel =====
    function initTestimonialsCarousel() {
        const cards = document.querySelectorAll('.testimonial-card');
        const indicators = document.querySelectorAll('.indicator');
        const prevBtn = document.querySelector('.carousel-btn.prev');
        const nextBtn = document.querySelector('.carousel-btn.next');
        let currentIndex = 0;
        let autoplayInterval;

        function showSlide(index) {
            // Remove active class from all cards and indicators
            cards.forEach(card => card.classList.remove('active'));
            indicators.forEach(indicator => indicator.classList.remove('active'));

            // Add active class to current card and indicator
            if (cards[index]) {
                cards[index].classList.add('active');
            }
            if (indicators[index]) {
                indicators[index].classList.add('active');
            }

            currentIndex = index;
        }

        function nextSlide() {
            const next = (currentIndex + 1) % cards.length;
            showSlide(next);
        }

        function prevSlide() {
            const prev = (currentIndex - 1 + cards.length) % cards.length;
            showSlide(prev);
        }

        function startAutoplay() {
            // Only autoplay if user hasn't indicated preference for reduced motion
            const prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
            if (!prefersReducedMotion) {
                autoplayInterval = setInterval(nextSlide, 5000);
            }
        }

        function stopAutoplay() {
            if (autoplayInterval) {
                clearInterval(autoplayInterval);
            }
        }

        // Event listeners
        if (prevBtn) {
            prevBtn.addEventListener('click', function() {
                stopAutoplay();
                prevSlide();
                startAutoplay();
            });
        }

        if (nextBtn) {
            nextBtn.addEventListener('click', function() {
                stopAutoplay();
                nextSlide();
                startAutoplay();
            });
        }

        // Indicator click events
        indicators.forEach((indicator, index) => {
            indicator.addEventListener('click', function() {
                stopAutoplay();
                showSlide(index);
                startAutoplay();
            });
        });

        // Keyboard navigation
        document.addEventListener('keydown', function(e) {
            if (e.key === 'ArrowLeft') {
                stopAutoplay();
                prevSlide();
                startAutoplay();
            } else if (e.key === 'ArrowRight') {
                stopAutoplay();
                nextSlide();
                startAutoplay();
            }
        });

        // Pause autoplay on hover/focus
        const carouselContainer = document.querySelector('.testimonials-carousel');
        if (carouselContainer) {
            carouselContainer.addEventListener('mouseenter', stopAutoplay);
            carouselContainer.addEventListener('mouseleave', startAutoplay);
            carouselContainer.addEventListener('focusin', stopAutoplay);
            carouselContainer.addEventListener('focusout', startAutoplay);
        }

        // Initialize
        showSlide(0);
        startAutoplay();
    }

    // ===== Newsletter Form =====
    function initNewsletterForm() {
        const form = document.getElementById('newsletter-form');
        const messageEl = document.getElementById('newsletter-message');

        if (!form) return;

        form.addEventListener('submit', function(e) {
            e.preventDefault();

            const emailInput = form.querySelector('input[type="email"]');
            const email = emailInput.value.trim();

            // Simple email validation
            const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
            
            if (!emailRegex.test(email)) {
                messageEl.textContent = 'Please enter a valid email address';
                messageEl.className = 'newsletter-message error';
                return;
            }

            // Simulate success (in real implementation, this would call an API)
            emailInput.value = '';
            messageEl.textContent = '✓ Subscribed! Check your inbox for confirmation.';
            messageEl.className = 'newsletter-message success';

            // Create confetti effect (reduced for accessibility)
            const prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
            if (!prefersReducedMotion) {
                createConfetti();
            }

            // Reset message after 5 seconds
            setTimeout(function() {
                messageEl.textContent = '';
                messageEl.className = 'newsletter-message';
            }, 5000);
        });
    }

    // ===== Confetti Effect =====
    function createConfetti() {
        const colors = ['#6366F1', '#8B5CF6', '#EC4899', '#10B981', '#F59E0B'];
        const confettiCount = 30;

        for (let i = 0; i < confettiCount; i++) {
            const confetti = document.createElement('div');
            confetti.style.cssText = `
                position: fixed;
                width: 8px;
                height: 8px;
                background: ${colors[Math.floor(Math.random() * colors.length)]};
                top: 50%;
                left: 50%;
                border-radius: 50%;
                pointer-events: none;
                z-index: 9999;
                opacity: 1;
            `;

            document.body.appendChild(confetti);

            // Animate
            const angle = Math.random() * Math.PI * 2;
            const velocity = 100 + Math.random() * 100;
            const vx = Math.cos(angle) * velocity;
            const vy = Math.sin(angle) * velocity;

            let x = 0;
            let y = 0;
            let opacity = 1;
            const startTime = Date.now();
            const duration = 1000 + Math.random() * 500;

            function animate() {
                const elapsed = Date.now() - startTime;
                const progress = elapsed / duration;

                if (progress < 1) {
                    x += vx * 0.016;
                    y += (vy + 200 * progress) * 0.016; // Gravity effect
                    opacity = 1 - progress;

                    confetti.style.transform = `translate(${x}px, ${y}px)`;
                    confetti.style.opacity = opacity;

                    requestAnimationFrame(animate);
                } else {
                    confetti.remove();
                }
            }

            requestAnimationFrame(animate);
        }
    }

    // ===== Smooth Scroll for Anchor Links =====
    function initSmoothScroll() {
        const prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
        if (prefersReducedMotion) return; // Respect reduced motion preference

        document.querySelectorAll('a[href^="#"]').forEach(function(anchor) {
            anchor.addEventListener('click', function(e) {
                const href = this.getAttribute('href');
                if (href === '#' || href === '') return;

                const target = document.querySelector(href);
                if (target) {
                    e.preventDefault();
                    target.scrollIntoView({
                        behavior: 'smooth',
                        block: 'start'
                    });

                    // Update focus for accessibility
                    target.setAttribute('tabindex', '-1');
                    target.focus();
                }
            });
        });
    }

    // ===== Intersection Observer for Fade-in Animations =====
    function initScrollAnimations() {
        const prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
        if (prefersReducedMotion) return; // Respect reduced motion preference

        const observerOptions = {
            root: null,
            rootMargin: '0px',
            threshold: 0.1
        };

        const observer = new IntersectionObserver(function(entries) {
            entries.forEach(function(entry) {
                if (entry.isIntersecting) {
                    entry.target.style.opacity = '1';
                    entry.target.style.transform = 'translateY(0)';
                }
            });
        }, observerOptions);

        // Observe elements that should fade in
        document.querySelectorAll('.feature-card').forEach(function(element) {
            element.style.opacity = '0';
            element.style.transform = 'translateY(30px)';
            element.style.transition = 'opacity 0.6s ease-out, transform 0.6s ease-out';
            observer.observe(element);
        });
    }

    // ===== Initialize All Features =====
    function init() {
        // Wait for DOM to be ready
        if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', function() {
                initNavigation();
                initTestimonialsCarousel();
                initNewsletterForm();
                initSmoothScroll();
                initScrollAnimations();
            });
        } else {
            // DOM is already ready
            initNavigation();
            initTestimonialsCarousel();
            initNewsletterForm();
            initSmoothScroll();
            initScrollAnimations();
        }
    }

    // Start initialization
    init();

})();
