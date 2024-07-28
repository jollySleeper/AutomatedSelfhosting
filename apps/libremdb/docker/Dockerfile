# Dependency 
FROM node:lts-alpine AS deps

WORKDIR /opt/app

RUN apk add --no-cache wget
RUN wget 'https://raw.githubusercontent.com/zyachel/libremdb/main/package.json'
RUN wget 'https://raw.githubusercontent.com/zyachel/libremdb/main/pnpm-lock.yaml'

RUN npm install -g pnpm
RUN pnpm install --frozen-lockfile

RUN echo "Dependency Installed" && ls /opt/app

# Building
FROM node:lts-alpine AS builder

ENV NODE_ENV=production
WORKDIR /opt/app

RUN npm install -g pnpm

RUN apk add --no-cache wget
COPY scripts/getLatestRelease.sh .
RUN chmod +x getLatestRelease.sh && ./getLatestRelease.sh

COPY --from=deps /opt/app/node_modules ./node_modules
RUN corepack enable
RUN pnpm build


# Production image, copy all the files and run next
FROM node:lts-alpine AS runner
ARG X_TAG
ENV NODE_ENV=production
WORKDIR /opt/app

COPY --from=builder /opt/app/next.config.mjs ./
COPY --from=builder /opt/app/public ./public
COPY --from=builder /opt/app/.next ./.next
COPY --from=builder /opt/app/node_modules ./node_modules

ENV HOST=0.0.0.0
ENV PORT=3000
CMD ["./node_modules/next/dist/bin/next", "start"]
