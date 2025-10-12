# Deployment Guide

This guide covers deploying the PoshGuard marketing site to various platforms.

## Prerequisites

- Node.js 18+
- npm 10+
- Git

## Quick Deploy Options

### 1. Vercel (Recommended - One Click)

[![Deploy with Vercel](https://vercel.com/button)](https://vercel.com/new/clone?repository-url=https://github.com/cboyd0319/PoshGuard/tree/main/web)

**Steps**:
1. Click the deploy button above
2. Connect your GitHub account
3. Select repository
4. Configure environment variables (optional)
5. Deploy

**Benefits**:
- Automatic HTTPS
- Global CDN
- Instant cache invalidation
- Preview deployments for PRs
- Zero configuration

### 2. Netlify

**Steps**:
1. Install Netlify CLI: `npm install -g netlify-cli`
2. Build the site: `npm run build`
3. Deploy: `netlify deploy --prod --dir=.next`

**Configuration** (`netlify.toml`):
```toml
[build]
  command = "npm run build"
  publish = ".next"

[[redirects]]
  from = "/*"
  to = "/index.html"
  status = 200
```

### 3. Docker

**Dockerfile**:
```dockerfile
FROM node:20-alpine AS base

# Dependencies
FROM base AS deps
WORKDIR /app
COPY package*.json ./
RUN npm ci

# Build
FROM base AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN npm run build

# Production
FROM base AS runner
WORKDIR /app
ENV NODE_ENV=production

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

COPY --from=builder /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs
EXPOSE 3000
ENV PORT=3000

CMD ["node", "server.js"]
```

**Build and Run**:
```bash
docker build -t poshguard-web .
docker run -p 3000:3000 poshguard-web
```

### 4. Static Export (GitHub Pages, S3, etc.)

**Update `next.config.ts`**:
```typescript
const nextConfig = {
  output: 'export',
  images: {
    unoptimized: true,
  },
};
```

**Build**:
```bash
npm run build
```

This creates an `out/` directory with static files.

**Deploy to GitHub Pages**:
```bash
# Install gh-pages
npm install --save-dev gh-pages

# Add to package.json scripts
"deploy": "gh-pages -d out"

# Deploy
npm run deploy
```

### 5. AWS Amplify

**Steps**:
1. Connect repository to Amplify Console
2. Configure build settings:
   - Build command: `npm run build`
   - Output directory: `.next`
3. Deploy

## Environment Variables

Copy `.env.example` to `.env.local`:

```bash
cp .env.example .env.local
```

### Required Variables

None - the site works without any environment variables.

### Optional Variables

```env
# Analytics
NEXT_PUBLIC_GA_ID=G-XXXXXXXXXX

# API Integration
NEXT_PUBLIC_API_URL=https://api.poshguard.dev

# Newsletter Service (Mailchimp, ConvertKit, etc.)
NEWSLETTER_API_KEY=your-api-key
NEWSLETTER_LIST_ID=your-list-id
```

## Performance Optimization

### Image Optimization

Replace public images with optimized versions:

```bash
# Install sharp for image optimization
npm install sharp

# Images should be:
# - WebP format preferred
# - Multiple sizes for responsive images
# - Compressed (80-90% quality)
```

### Font Optimization

The site currently uses system fonts for optimal performance. To add custom fonts:

1. Use `next/font/google` for Google Fonts
2. Or self-host fonts in `/public/fonts`
3. Update `app/layout.tsx` and `globals.css`

### Analytics

Add Google Analytics:

```typescript
// app/layout.tsx
import Script from 'next/script'

// In layout
<Script
  src={`https://www.googletagmanager.com/gtag/js?id=${process.env.NEXT_PUBLIC_GA_ID}`}
  strategy="afterInteractive"
/>
```

## Post-Deployment Checklist

- [ ] Verify all pages load correctly
- [ ] Test navigation and links
- [ ] Check mobile responsiveness
- [ ] Verify form submissions (newsletter)
- [ ] Test dark mode toggle
- [ ] Run Lighthouse audit (target: Perf ≥90, A11y ≥95)
- [ ] Verify analytics tracking
- [ ] Test in multiple browsers
- [ ] Check keyboard navigation
- [ ] Verify screen reader compatibility

## Monitoring

### Recommended Tools

1. **Vercel Analytics** (if using Vercel)
2. **Google Analytics** - User behavior
3. **Sentry** - Error tracking
4. **Lighthouse CI** - Performance monitoring
5. **Web Vitals** - Core metrics

### Key Metrics to Track

- **LCP** (Largest Contentful Paint): < 2.5s
- **FID** (First Input Delay): < 100ms
- **CLS** (Cumulative Layout Shift): < 0.1
- **TTFB** (Time to First Byte): < 600ms
- **Bounce Rate**: Monitor and optimize
- **Conversion Rate**: Newsletter signups, CTA clicks

## Troubleshooting

### Build Fails

```bash
# Clear cache
rm -rf .next node_modules
npm install
npm run build
```

### Images Not Loading

- Verify image paths are correct
- Check `next.config.ts` image domains
- Ensure images are in `/public` directory

### Fonts Not Loading

- Check CDN availability
- Verify font URLs
- Consider self-hosting fonts

### CSS Not Applied

- Clear browser cache
- Rebuild: `npm run build`
- Check Tailwind config

## Rollback Strategy

### Vercel

1. Go to Deployments tab
2. Click "..." on previous deployment
3. Select "Promote to Production"

### Manual Rollback

```bash
git revert HEAD
git push origin main
```

## Support

- **Documentation**: See [README.md](./README.md)
- **Issues**: Create an issue on GitHub
- **Community**: Join discussions

## License

MIT - See [LICENSE](../LICENSE) for details.
