import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate } from 'k6/metrics';

export const errorRate = new Rate('errors');

export const options = {
  vus: 10,
  duration: '30s',
  thresholds: {
    http_req_duration: ['p(95)<500'],
    errors: ['rate<0.05'],
  },
};

const BASE_URL = __ENV.BASE_URL || 'http://localhost';

export default function () {
  // Test /ping endpoint
  const pingRes = http.get(`${BASE_URL}/ping`);
  const pingOk = check(pingRes, {
    'ping status is 200': (r) => r.status === 200,
    'ping response has count': (r) => JSON.parse(r.body).count !== undefined,
    'ping response time < 500ms': (r) => r.timings.duration < 500,
  });
  errorRate.add(!pingOk);

  sleep(1);

  // Test /pong endpoint
  const pongRes = http.get(`${BASE_URL}/pong`);
  const pongOk = check(pongRes, {
    'pong status is 200 or 404': (r) => r.status === 200 || r.status === 404,
    'pong response time < 500ms': (r) => r.timings.duration < 500,
  });
  errorRate.add(!pongOk);

  sleep(1);
}
