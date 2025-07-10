# Build stage
FROM node:24-alpine AS builder

# Set working directory
WORKDIR /build

# Copy package.json and lock
COPY app/package*.json ./

# Install deps
RUN npm install 

# Copy rest of the code
COPY app/ .

#App stage
FROM node:24-alpine AS runner

# Set working directory
WORKDIR /app

# Copy only needed files from builder
COPY --from=builder /build .


# Expose app port
EXPOSE 3000

# Start app
CMD ["npm", "start"]

