const express = require('express');
const morgan = require('morgan');
const client = require('prom-client');

const app = express();
const port = process.env.PORT || 3000;

// Middleware pour des logs structurés
app.use(morgan('combined'));

// Ajout instrumentation Prometheus pour requêtes HTTP
const register = new client.Registry();
client.collectDefaultMetrics({ register });

// Compteur total des requêtes HTTP
const httpRequestsTotal = new client.Counter({
  name: 'http_requests_total',
  help: 'Total des requêtes HTTP',
  labelNames: ['method', 'route', 'status'],
  registers: [register],
});

// Histogramme de la durée des requêtes HTTP (secondes)
const httpRequestDurationSeconds = new client.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Durée des requêtes HTTP en secondes',
  labelNames: ['method', 'route', 'status'],
  buckets: [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10],
  registers: [register],
});

// Middleware d'instrumentation (exclut /metrics)
app.use((req, res, next) => {
  if (req.path === '/metrics') return next();
  const start = process.hrtime();
  res.on('finish', () => {
    const diff = process.hrtime(start);
    const durationSeconds = diff[0] + diff[1] / 1e9;
    const labels = {
      method: req.method,
      route: req.path || 'unknown',
      status: String(res.statusCode),
    };
    httpRequestsTotal.inc(labels);
    httpRequestDurationSeconds.observe(labels, durationSeconds);
  });
  next();
});

// Endpoint /ping
app.get('/ping', (req, res) => {
  res.json({ message: 'pong' });
});

// Endpoint /health
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'healthy' });
});

// Endpoint /metrics
app.get('/metrics', async (req, res) => {
  res.set('Content-Type', register.contentType);
  res.end(await register.metrics());
});

// Démarrage du serveur seulement si pas en mode test
let server;
if (process.env.NODE_ENV !== 'test') {
  server = app.listen(port, () => {
    console.log(`API running on port ${port}`);
  });
}

// Exporter l'application et le serveur
module.exports = { app, server };
