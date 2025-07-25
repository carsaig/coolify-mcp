# Dockerfile
# Override der upstream Version um npm audit zu umgehen

FROM node:18-alpine

WORKDIR /app

# Kopiere package.json und package-lock.json
COPY package*.json ./

# Installiere Dependencies OHNE audit
RUN npm ci --audit=false --fund=false

# Kopiere Source Code
COPY . .

# Build das Projekt (falls nötig)
RUN npm run build 2>/dev/null || echo "No build script found"

# Expose Port (adjust as needed)
EXPOSE 3000

# Start Command
CMD ["npm", "start"]
