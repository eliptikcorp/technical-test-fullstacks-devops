# syntax=docker/dockerfile:1

# ---- Base stage: install dependencies (prod only) ----
FROM node:20-alpine AS deps
WORKDIR /app
COPY package*.json ./
# Install only production dependencies for a smaller image
RUN npm ci --omit=dev

# ---- Runner stage ----
FROM node:20-alpine AS runner
ENV NODE_ENV=production
WORKDIR /app
# Copy node user and run as non-root for security
USER node
# Copy application from deps stage (including node_modules)
COPY --chown=node:node --from=deps /app /app
# Copy the rest of the source code
COPY --chown=node:node . .

EXPOSE 3000
CMD ["node", "index.js"]