# Supported LTS Node.js version (node:14 is EOL and required for bcrypt >= 18)
FROM node:20-alpine

# Set working directory
WORKDIR /app

# Copy package files (including the lockfile for reproducible installs)
COPY package*.json ./

# Install production dependencies. bcrypt is a native addon, so build tools are
# required to compile it on Alpine; they are removed afterwards to keep the image small.
RUN apk add --no-cache --virtual .build-deps python3 make g++ \
    && npm ci --omit=dev \
    && apk del .build-deps

# Copy source code
COPY src/ ./src/

# Create a non-root user and hand over ownership of the app directory
RUN addgroup -g 1001 -S nodejs \
    && adduser -S nodejs -u 1001 \
    && chown -R nodejs:nodejs /app

# Switch to non-root user
USER nodejs

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', (res) => { process.exit(res.statusCode === 200 ? 0 : 1) })"

# Start the application
CMD ["npm", "start"] 