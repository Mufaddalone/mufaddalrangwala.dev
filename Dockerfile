FROM node:18-alpine AS build-stage

# Set the working directory inside the container
WORKDIR /app

# Install necessary dependencies for Puppeteer and Chromium
RUN apk add --no-cache \
    chromium \
    nss \
    freetype \
    freetype-dev \
    harfbuzz \
    ca-certificates \
    ttf-freefont

# Tell Puppeteer to skip downloading Chrome. We'll be using the installed package.
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true \
    PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium-browser

# Copy the package.json and package-lock.json files
COPY package*.json ./

# Install all dependencies
RUN npm install

# Copy the rest of the application code
COPY . .


# # Expose the port that your Astro app will run on (default is 3000)
# EXPOSE 3000

# # Set the command to start the Astro development server
# CMD ["npm", "start"]


EXPOSE 80

# # Build the Astro app
RUN npm run build

# # Production stage
FROM nginx:stable-alpine as production-stage

# Copy built assets from the build stage to the NGINX serve directory
COPY --from=build-stage /app/dist /usr/share/nginx/html
COPY default.conf /etc/nginx/conf.d/default.conf

# # Expose port 80 to the Docker host, so we can access it
# # from the outside.
# EXPOSE 443

# # Start NGINX
CMD ["nginx", "-g", "daemon off;"]
