# Dockerfile
FROM node:18-alpine AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm install
COPY . .
RUN npm run build

FROM node:18-alpine AS runtime
WORKDIR /app
COPY --from=build /app/dist ./dist
RUN npm install --omit=dev
ENV COOLIFY_ACCESS_TOKEN="op://Private/Coolify/API_Token" \
    COOLIFY_BASE_URL="op://Private/Coolify/BASE_URL"
EXPOSE 3000
CMD ["node", "dist/index.js"]
