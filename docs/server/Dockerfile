FROM node:18-alpine

# Create app directory
WORKDIR /usr/src/app

# Use production environment by default
ENV NODE_ENV=production
ENV PORT=8080

# Install deps based on the lockfile for reproducible builds
COPY package*.json ./
RUN npm ci --only=production

# Copy source
COPY . .

# Expose the port the server listens on
EXPOSE 8080

# Start the server
CMD ["npm", "start"]
