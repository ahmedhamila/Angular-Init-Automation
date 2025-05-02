FROM node:20-alpine

# Set working directory
WORKDIR /app

# Install bash
RUN apk add --no-cache bash
# Install global dependencies
RUN apk add --no-cache dos2unix && \
    npm install -g @angular/cli

# Copy package.json and package-lock.json
COPY package*.json ./

# Install app dependencies
RUN npm install --legacy-peer-deps

# Copy the rest of the application code
COPY . /app/

# Expose port
EXPOSE 4200

# Command to run when the container starts
CMD ["ng", "serve", "--host", "0.0.0.0", "--disable-host-check"]