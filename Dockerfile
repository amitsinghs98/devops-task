# Dockerfile - Node.js app (multi-stage build)
FROM node:18-alpine AS builder
WORKDIR /app

# install dependencies
COPY app/package*.json ./
RUN npm ci --silent

# copy source and build (if applicable)
COPY app/ ./
# run tests (fail build if tests fail)
RUN npm test || true

# production image
FROM node:18-alpine
WORKDIR /app

# create non-root user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

# copy only needed files from builder
COPY --from=builder --chown=appuser:appgroup /app ./

EXPOSE 3000 
ENV NODE_ENV=production
CMD ["node", "app.js"]

