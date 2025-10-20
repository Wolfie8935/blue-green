FROM node:18-alpine
# Or use any base image based on your application

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install --production

# Copy application code
COPY . .

# Expose application port
EXPOSE 3000

# Start the application
CMD ["npm", "start"]