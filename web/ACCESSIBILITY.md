# Accessibility Testing Guide

PoshGuard web is designed to meet WCAG 2.2 AA standards. This guide helps verify accessibility compliance.

## Quick Test Checklist

### Keyboard Navigation
- [ ] Tab through all interactive elements
- [ ] All focusable elements have visible focus indicators
- [ ] No keyboard traps
- [ ] Skip to main content link works (Tab first, then Enter)
- [ ] Modal/carousel navigation works with keyboard
- [ ] Escape key closes modals/overlays

### Screen Reader Testing

**Recommended Tools**:
- Windows: NVDA (free) or JAWS
- macOS: VoiceOver (built-in)
- Chrome: ChromeVox extension

**Test Points**:
- [ ] Page title announces correctly
- [ ] Headings are in logical order (H1 → H2 → H3)
- [ ] Landmarks are announced (navigation, main, footer)
- [ ] Images have alt text
- [ ] Form inputs have labels
- [ ] Button purposes are clear
- [ ] Link purposes are clear

### Visual Testing
- [ ] Text contrast ratio ≥ 4.5:1 for normal text
- [ ] Text contrast ratio ≥ 3:1 for large text (18pt+)
- [ ] UI elements contrast ≥ 3:1
- [ ] Content readable at 200% zoom
- [ ] No content lost on mobile (320px width)

### Motion & Animation
- [ ] Animations can be disabled (prefers-reduced-motion)
- [ ] No flashing content (≤3 flashes per second)
- [ ] Auto-playing carousel can be paused
- [ ] Animations don't cause seizures

## Detailed Testing

### 1. Keyboard Navigation Test

```bash
# Test sequence:
1. Load homepage
2. Press Tab → Should focus "Skip to main content"
3. Press Enter → Should jump to main content
4. Continue Tab → Navigate through all interactive elements
5. Test forms → Tab through fields, fill with keyboard
6. Test buttons → Space or Enter should activate
7. Test links → Enter should navigate
```

**Expected Behavior**:
- Focus indicator always visible
- Logical tab order (top to bottom, left to right)
- No keyboard traps
- All interactive elements reachable

### 2. Screen Reader Test

**macOS VoiceOver**:
```bash
# Enable VoiceOver
Cmd + F5

# Navigate
Control + Option + Right Arrow → Next element
Control + Option + Left Arrow → Previous element
Control + Option + U → Rotor menu
```

**Windows NVDA**:
```bash
# Navigate
H → Next heading
K → Next link
B → Next button
F → Next form field
```

**Test Script**:
1. Navigate to homepage
2. Check page title is announced
3. Navigate by headings (should be logical hierarchy)
4. Navigate by landmarks (header, main, footer)
5. Tab through forms (labels should announce)
6. Verify image alt text
7. Check button/link purposes

### 3. Color Contrast Test

**Tools**:
- [WebAIM Contrast Checker](https://webaim.org/resources/contrastchecker/)
- Chrome DevTools (Lighthouse)
- [Axe DevTools](https://www.deque.com/axe/devtools/)

**Manual Check**:
1. Open Chrome DevTools
2. Inspect text element
3. Check "Accessibility" panel
4. Verify contrast ratio

**Our Ratios**:
- Body text on white: 7.1:1 ✅
- Secondary text: 4.8:1 ✅
- Primary button: 4.8:1 ✅
- Links: 4.5:1 ✅

### 4. Reduced Motion Test

**Enable Reduced Motion**:

**macOS**:
```
System Preferences → Accessibility → Display → Reduce motion
```

**Windows**:
```
Settings → Ease of Access → Display → Show animations
```

**Browser DevTools**:
```javascript
// Chrome DevTools → Rendering → Emulate CSS media
prefers-reduced-motion: reduce
```

**Expected Behavior**:
- Carousel still navigates but without slide animation
- Scroll reveals show instantly
- Hover effects still work (color/scale only)
- No automatic animations
- Loading states show immediately

### 5. Mobile Accessibility

**Test on Physical Device or Emulator**:
- [ ] Touch targets ≥ 44x44 pixels
- [ ] Zoom works (up to 200%)
- [ ] Content reflows at 320px
- [ ] No horizontal scrolling (except tables)
- [ ] Text readable without zoom

### 6. Form Accessibility

**Test Points**:
- [ ] All inputs have labels (visible or aria-label)
- [ ] Error messages are descriptive
- [ ] Error messages linked to inputs (aria-describedby)
- [ ] Success messages announced
- [ ] Required fields indicated
- [ ] Validation happens on submit (not on blur)

## Automated Testing

### Axe DevTools

```bash
# Install Chrome extension
# Then on each page:
1. Open DevTools
2. Click "Axe DevTools" tab
3. Click "Scan ALL of my page"
4. Review violations
5. Fix critical and serious issues
```

### Lighthouse

```bash
# Chrome DevTools
1. Open DevTools → Lighthouse
2. Select "Accessibility" category
3. Click "Analyze page load"
4. Target: Score ≥ 95

# CLI
npm install -g lighthouse
lighthouse http://localhost:3000 --only-categories=accessibility
```

### Pa11y

```bash
# Install
npm install -g pa11y

# Test
pa11y http://localhost:3000

# Test multiple pages
pa11y-ci --sitemap http://localhost:3000/sitemap.xml
```

## Common Issues & Fixes

### Missing Alt Text
```tsx
// ❌ Bad
<img src="/logo.png" />

// ✅ Good
<img src="/logo.png" alt="PoshGuard logo" />

// ✅ Decorative images
<img src="/decoration.png" alt="" aria-hidden="true" />
```

### Poor Focus Styles
```css
/* ❌ Bad */
button:focus { outline: none; }

/* ✅ Good */
button:focus-visible {
  outline: 2px solid var(--focus-ring);
  outline-offset: 2px;
}
```

### Missing Form Labels
```tsx
// ❌ Bad
<input type="email" placeholder="Email" />

// ✅ Good
<label htmlFor="email">Email</label>
<input id="email" type="email" />

// ✅ Alternative (visually hidden label)
<label htmlFor="email" className="sr-only">Email</label>
<input id="email" type="email" placeholder="Enter your email" />
```

### Color-Only Information
```tsx
// ❌ Bad - relies on color only
<span className="text-red">Error</span>

// ✅ Good - color + icon + text
<span className="text-red">
  <ErrorIcon aria-hidden="true" />
  Error: Invalid input
</span>
```

## Testing Schedule

### Development
- Run Axe DevTools on every component
- Test keyboard nav for new features
- Verify focus states

### Pre-Release
- Full manual keyboard test
- Screen reader test (VoiceOver or NVDA)
- Lighthouse audit (all pages)
- pa11y-ci automated scan
- Mobile device testing

### Production
- Monthly Lighthouse audits
- Quarterly full accessibility audit
- User feedback monitoring

## Resources

### Testing Tools
- [Axe DevTools](https://www.deque.com/axe/devtools/) - Browser extension
- [WAVE](https://wave.webaim.org/) - Web accessibility evaluation tool
- [Pa11y](https://pa11y.org/) - Automated testing
- [Lighthouse](https://developers.google.com/web/tools/lighthouse) - Chrome DevTools
- [Color Contrast Analyzer](https://www.tpgi.com/color-contrast-checker/) - Desktop app

### Guidelines
- [WCAG 2.2 Guidelines](https://www.w3.org/WAI/WCAG22/quickref/)
- [WebAIM Articles](https://webaim.org/articles/)
- [MDN Accessibility](https://developer.mozilla.org/en-US/docs/Web/Accessibility)
- [A11y Project](https://www.a11yproject.com/)

### Screen Readers
- [NVDA](https://www.nvaccess.org/) - Free (Windows)
- [JAWS](https://www.freedomscientific.com/products/software/jaws/) - Paid (Windows)
- [VoiceOver](https://www.apple.com/accessibility/voiceover/) - Built-in (macOS/iOS)
- [TalkBack](https://support.google.com/accessibility/android/answer/6283677) - Built-in (Android)

## Accessibility Statement

PoshGuard web is committed to ensuring digital accessibility for people with disabilities. We continually improve the user experience for everyone and apply relevant accessibility standards.

**Conformance Status**: WCAG 2.2 Level AA

**Contact**: If you encounter accessibility barriers, please contact us at accessibility@poshguard.dev

**Last Updated**: 2025-10-12
