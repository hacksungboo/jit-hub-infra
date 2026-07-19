// cloud-project-v3/load-test/tourist-service.js

import http from 'k6/http';
import { check, sleep } from 'k6';

/**
 * KEDA 부하 테스트: tourist-service
 * 
 * KEDA 설정:
 * - threshold: 150 RPS
 * - minReplicaCount: 3
 * - maxReplicaCount: 10
 */

export let options = {
  stages: [
    { duration: '1m', target: 40, name: 'warmup' },
    { duration: '1m', target: 80, name: 'ramp-up-1' },
    { duration: '1m', target: 120, name: 'ramp-up-2' },
    { duration: '1m', target: 150, name: 'ramp-up-3' },
    { duration: '1m', target: 180, name: 'peak-load' },
    { duration: '2m', target: 180, name: 'sustained-peak' },
    { duration: '2m', target: 0, name: 'cooldown' },
  ],
  
  thresholds: {
    'http_req_duration': ['p(95)<500'],
    'http_req_failed': ['rate<0.1'],
  },
};

export default function () {
  const BASE_URL = 'http://localhost:8003';
  const touristUrl = `${BASE_URL}/api/tourist`;
  
  const res = http.get(touristUrl, {
    timeout: '5s',
    tags: { name: 'Gettourist' },
  });
  
  check(res, {
    'status is 200': (r) => r.status === 200,
    'response time < 500ms': (r) => r.timings.duration < 500,
    'has tourist data': (r) => r.body.includes('tourist') || r.body.includes('attractions'),
  });
  
  sleep(1 + Math.random());
}

/**
 * 포트포워드:
 * kubectl port-forward svc/tourist-service 8082:80
 *
 * 실행:
 * k6 run tourist-service.js
 */