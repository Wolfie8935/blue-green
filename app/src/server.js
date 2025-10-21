const express = require('express');
const path = require('path');
const app = express();
const port = 3000;

const environment = process.env.ENVIRONMENT || 'unknown';

app.use(express.static(path.join(__dirname, 'public')));

app.get('/health', (req, res) => {
  res.status(200).json({ 
    status: 'healthy', 
    environment: environment,
    timestamp: new Date().toISOString()
  });
});

app.get('/ready', (req, res) => {
  res.status(200).json({ 
    status: 'ready',
    environment: environment
  });
});

app.get('/api/info', (req, res) => {
  res.json({
    environment: environment,
    version: '1.0.0',
    timestamp: new Date().toISOString(),
    hostname: require('os').hostname()
  });
});

app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

app.listen(port, () => {
  console.log(`🚀 ${environment.toUpperCase()} environment running on port ${port}`);
});