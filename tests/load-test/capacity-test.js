// pod 최대값 측정 스크립트 

import http from 'k6/http';
import { check } from 'k6';

export let options = {
  // 단계별로 RPS를 올리며 한계점 탐색
  scenarios: {
    capacity: {
      executor: 'ramping-arrival-rate',  // VU가 아닌 RPS를 직접 제어
      startRate: 10,
      timeUnit: '1s',
      preAllocatedVUs: 50,
      maxVUs: 500,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '1m', target: 20 },
        { duration: '1m', target: 50 },
        { duration: '1m', target: 100 },
        { duration: '1m', target: 200 },
      ],
    },
  },
};

export default function () {
  const res = http.get('http://localhost:8001/health', { timeout: '10s' });
  check(res, { 'status 200': (r) => r.status === 200 });
}