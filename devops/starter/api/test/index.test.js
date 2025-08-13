const request = require('supertest');
const { app, server } = require('../index');

afterAll(() => {
  // Arrêter le serveur après les tests
  server.close();
});

describe('API Endpoints', () => {
  it('should return pong on /ping', async () => {
    const res = await request(app).get('/ping');
    expect(res.statusCode).toEqual(200);
    expect(res.body).toEqual({ message: 'pong' });
  });

  it('should return healthy on /health', async () => {
    const res = await request(app).get('/health');
    expect(res.statusCode).toEqual(200);
    expect(res.body).toEqual({ status: 'healthy' });
  });

  it('should expose metrics on /metrics', async () => {
    const res = await request(app).get('/metrics');
    expect(res.statusCode).toEqual(200);
    expect(res.headers['content-type']).toContain('text/plain');
  });
});