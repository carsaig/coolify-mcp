# Dockerfile for Coolify MCP Server
FROM node:18-alpine

# Install required system dependencies
RUN apk add --no-cache git

WORKDIR /app

# Copy package files first for better Docker layer caching
COPY package*.json ./
COPY tsconfig.json ./

# Install all dependencies (including dev dependencies needed for build)
RUN npm ci --audit=false --fund=false

# Copy source code
COPY src/ ./src/

# Build the TypeScript project
RUN npm run build

# Verify the build output exists
RUN ls -la dist/ && test -f dist/index.js

# Remove dev dependencies to reduce image size (after build)
RUN npm prune --production

# MCP servers use stdio transport, no ports needed
# EXPOSE is removed as it's not applicable for MCP servers

# Health check to verify the container can start
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD node -e "console.log('Health check: Node.js is working')" || exit 1

# Start the MCP server
CMD ["node", "dist/index.js"]
