# Stage 1: Development/Build Stage
FROM node:20-alpine AS builder

# Set working directory
WORKDIR /app

# Install necessary build dependencies
RUN apk add --no-cache python3 make g++

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci

# Copy all project files
COPY . .

# Build the Next.js application
# Set a placeholder MONGODB_URI for the build step
RUN MONGODB_URI="mongodb://localhost:27017/dummy" npm run build


# Stage 2: Production Stage
FROM node:20-alpine AS runner

# Set working directory
WORKDIR /app

# Set environment variables
ENV NODE_ENV=production
ENV PORT=3000
ENV HOSTNAME="0.0.0.0"

# Fix 1: Alpine-native syntax to create a system group and user
RUN addgroup --system --gid 10001 appgroup && \
    adduser --system --uid 10001 --ingroup appgroup appuser

# Fix 2: Explicitly chown Next.js production files during the copy phase
# Fix 3: Removed the broken "COPY . ." line that overwrote these build outputs
COPY --from=builder --chown=appuser:appgroup /app/.next/standalone ./
COPY --from=builder --chown=appuser:appgroup /app/.next/static ./.next/static
COPY --from=builder --chown=appuser:appgroup /app/public ./public

# Switch context to the non-root user
USER appuser

# Expose the port the app runs on
EXPOSE 3000

# Command to run the application
CMD ["node", "server.js"]
