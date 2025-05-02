FROM node:20-alpine

WORKDIR /app

# Copy package.json and install dependencies
COPY package*.json ./
RUN npm install --legacy-peer-deps

# Copy the rest of the application
COPY . .

# Create scripts directory
RUN mkdir -p scripts

# Expose port for Angular development server
EXPOSE 4200

# Default command (will be overridden by docker-compose)
CMD ["npm", "start"]