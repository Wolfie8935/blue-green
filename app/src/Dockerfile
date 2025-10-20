# Use Node.js 18 Alpine as the base image
FROM node:18-alpine

# Set the working directory inside the container
WORKDIR /app

# Copy all application files to the container
COPY . .

# Expose the application port (change if your app uses a different one)
EXPOSE 3000

# Default command — run your main JS file directly
CMD ["node", "server.js"]
