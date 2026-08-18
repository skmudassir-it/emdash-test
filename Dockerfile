# Build stage: compile Astro SSR (node adapter) with pnpm
FROM node:20-alpine AS builder
RUN corepack enable && corepack prepare pnpm@9 --activate
WORKDIR /app
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
RUN pnpm install --frozen-lockfile --no-audit
COPY . .
RUN pnpm run build

# Runtime: node serving the Astro standalone output
FROM node:20-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production
ENV HOST=0.0.0.0
ENV PORT=3000
RUN addgroup --system --gid 1001 nodejs \
    && adduser --system --uid 1001 nodejs
COPY --from=builder --chown=nodejs:nodejs /app/dist ./dist
COPY --from=builder --chown=nodejs:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=nodejs:nodejs /app/package.json ./package.json
USER nodejs
EXPOSE 3000
CMD ["node", "dist/server/entry.mjs"]
