const express = require('express');
const morgan = require('morgan');
const client = require('prom-client');

const app = express();
const port = process.env.PORT || 3000;

// Middleware pour des logs structurés
app.use(morgan('combined'));

// Endpoint /ping
app.get('/ping', (req, res) => {
  res.json({ message: 'pong' });
});

// Endpoint /health
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'healthy' });
});

// Configuration des métriques Prometheus
const register = new client.Registry();
client.collectDefaultMetrics({ register });

// Endpoint /metrics
app.get('/metrics', async (req, res) => {
  res.set('Content-Type', register.contentType);
  res.end(await register.metrics());
});

// Démarrage du serveur
const server = app.listen(port, () => {
  console.log(`API running on port ${port}`);
});

// Exporter l'application et le serveur
module.exports = { app, server };
