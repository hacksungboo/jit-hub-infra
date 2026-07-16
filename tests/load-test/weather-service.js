import http from 'k6/http';
import { check, sleep } from 'k6';

/**
 * KEDA + Karpenter 연계 부하 테스트: weather-service
 *
 * threshold: 10 RPS
 * sleep 0.1 → VU 50이면 이론상 500 RPS (실제는 port-forward 한계로 더 낮음)
 */
export let options = {
  stages: [
    { duration: '30s', target: 50, name: 'ramp-up' },
    { duration: '2m',  target: 50, name: 'peak' },
    { duration: '30s', target: 0,  name: 'cooldown' },
  ],
};

export default function () {
  const res = http.get('http://localhost:8001/health', { timeout: '5s' });

  check(res, {
    'status is 200': (r) => r.status === 200,
  });

  sleep(0.1);
}
