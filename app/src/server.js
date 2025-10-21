const express = require('express');
const path = require('path');
const app = express();
const port = 3000;

// Get environment from ENV variable (blue or green)
const environment = process.env.ENVIRONMENT || 'unknown';

// Serve static files
app.use(express.static(path.join(__dirname, 'public')));

// Health check endpoint (required by Kubernetes)
app.get('/health', (req, res) => {
  res.status(200).json({ 
    status: 'healthy', 
    environment: environment,
    timestamp: new Date().toISOString()
  });
});

// Readiness check endpoint (required by Kubernetes)
app.get('/ready', (req, res) => {
  res.status(200).json({ 
    status: 'ready',
    environment: environment
  });
});

// API endpoint to get environment info
app.get('/api/info', (req, res) => {
  res.json({
    environment: environment,
    version: '1.0.0',
    timestamp: new Date().toISOString(),
    hostname: require('os').hostname()
  });
});

// Main route - serve HTML based on environment
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

app.listen(port, () => {
  console.log(`🚀 ${environment.toUpperCase()} environment running on port ${port}`);
  console.log(`Environment: ${environment}`);
});