FROM node:18-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install --production

# Copy application code
COPY . .

# Create public directory if it doesn't exist
RUN mkdir -p public

EXPOSE 3000

CMD ["node", "server.js"]