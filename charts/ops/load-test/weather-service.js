// cloud-project-v3/load-test/weather-service.js

import http from 'k6/http';
import { check, sleep } from 'k6';

/**
 * KEDA 부하 테스트: weather-service
 * 
 * 목표:
 * - RPS를 0 → 50 → 100 → 150 → 200 → 250까지 점진적 증가
 * - KEDA가 Pod을 3개 → 10개로 자동 확장하는지 확인
 * 
 * KEDA 설정:
 * - threshold: 200 RPS
 * - minReplicaCount: 3
 * - maxReplicaCount: 10
 * 
 * 테스트 시간: 약 5분
 */

export let options = {
  // 단계별 부하 시나리오 (Virtual User 기반)
  stages: [
    // 워밍업: 1분동안 0 → 50 VU (약 50 RPS)
    { duration: '1m', target: 50, name: 'warmup' },
    
    // 단계 1: 1분동안 50 → 100 VU (약 100 RPS)
    { duration: '1m', target: 100, name: 'ramp-up-1' },
    
    // 단계 2: 1분동안 100 → 150 VU (약 150 RPS)
    { duration: '1m', target: 150, name: 'ramp-up-2' },
    
    // 단계 3: 1분동안 150 → 200 VU (약 200 RPS, 임계값)
    { duration: '1m', target: 200, name: 'ramp-up-3' },
    
    // 단계 4: 1분동안 200 → 250 VU (약 250 RPS, 초과)
    // 이 시점에서 KEDA가 Pod을 적극적으로 추가해야 함
    { duration: '1m', target: 250, name: 'peak-load' },
    
    // 안정화: 2분동안 peak 유지
    { duration: '2m', target: 250, name: 'sustained-peak' },
    
    // 쿨다운: 2분동안 250 → 0으로 감소
    // Pod이 줄어드는지도 확인
    { duration: '2m', target: 0, name: 'cooldown' },
  ],
  
  // Thresholds (선택사항: 테스트 실패 조건)
  thresholds: {
    'http_req_duration': ['p(95)<500'],  // 95% 요청이 500ms 이하
    'http_req_failed': ['rate<0.1'],      // 실패율 10% 이하
  },
  
  // 세부 설정
  timeout: '10s',
};

export default function () {
  // 로컬 테스트용 URL (kubectl port-forward로 노출된 서비스)
  const BASE_URL = 'http://localhost:8001';
  
  // 요청 URL
  const weatherUrl = `${BASE_URL}/api/weather`;
  
  // HTTP 요청 수행
  const res = http.get(weatherUrl, {
    timeout: '5s',
    tags: { name: 'GetWeather' },  // 메트릭 태깅
  });
  
  // 응답 검증
  check(res, {
    'status is 200': (r) => r.status === 200,
    'response time < 500ms': (r) => r.timings.duration < 500,
    'has weather data': (r) => r.body.includes('weather') || r.body.includes('temp'),
  });
  
  // 다음 요청 전 대기 (1~2초)
  // VU당 1~2초 간격으로 요청 → 약 50~100 RPS 생성
  sleep(1 + Math.random());
}

/**
 * 실행 명령어:
 * 
 * 1️⃣ 로컬 K8s 시작
 *    docker run -d --name k8s-local \
 *      -p 8080:8080 \
 *      -e KUBERNETES_SERVICE_HOST=kubernetes \
 *      kubernetes:latest
 *
 * 2️⃣ weather-service 배포
 *    kubectl apply -f weather-service.yaml
 *
 * 3️⃣ KEDA 설치
 *    helm install keda keda/keda --namespace keda
 *
 * 4️⃣ KEDA ScaledObject 적용
 *    kubectl apply -f weather-service-keda.yaml
 *
 * 5️⃣ 서비스 포트포워드
 *    kubectl port-forward svc/weather-service 8080:80
 *
 * 6️⃣ k6 부하 테스트 실행
 *    k6 run weather-service.js
 *
 * 테스트 중 다른 터미널에서 Pod 모니터링:
 * 
 *    kubectl get pods -w
 *    # 또는
 *    watch kubectl get pods
 */