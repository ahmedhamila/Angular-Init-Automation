FROM node:20-alpine

# Install git and other dependencies
RUN apk add --no-cache git bash

WORKDIR /app

# Create necessary directories
RUN mkdir -p /app/scripts

# Install Angular CLI globally to handle project creation and commands
RUN npm install -g @angular/cli@latest

# Create a basic package.json if it doesn't exist
RUN echo '{"name":"angular-app","version":"0.0.0","scripts":{"start":"ng serve"}}' > package.json

# Install base packages needed for an Angular app
RUN npm install --save-dev --legacy-peer-deps @angular/cli@latest @angular/core@latest @angular/common@latest @angular/platform-browser@latest @angular/platform-browser-dynamic@latest @angular/forms@latest @angular/router@latest rxjs@latest tslib@latest zone.js@latest

# Expose port for Angular development server
EXPOSE 4200

# Create a new Angular project if it doesn't exist
CMD [ -d "src" ] || ng new temp-project --skip-install && \
    [ -d "src" ] || cp -R temp-project/* . && \
    [ -d "src" ] || cp -R temp-project/.* . && \
    [ -d "src" ] || rm -rf temp-project && \
    npm start