import express from 'express';

const app = express();
const PORT = process.env.PORT || 3000;

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
  });
});

// Root endpoint
app.get('/', (req, res) => {
  res.json({
    message: 'Azure OIDC Sample Application',
    environment: process.env.NODE_ENV || 'development',
    version: '1.0.0'
  });
});

// Info endpoint to show environment variables (for testing)
app.get('/info', (req, res) => {
  res.json({
    nodeVersion: process.version,
    platform: process.platform,
    env: process.env.NODE_ENV || 'development',
    // Only show Azure-related env vars for security
    azureEnvs: Object.keys(process.env)
      .filter(key => key.startsWith('AZURE_'))
      .reduce((acc, key) => {
        acc[key] = process.env[key] || '';
        return acc;
      }, {} as Record<string, string>)
  });
});

app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
  console.log(`Health check: http://localhost:${PORT}/health`);
});