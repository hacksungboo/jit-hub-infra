#!/bin/bash
# cloud-project-v3/load-test/run-all.sh

set -e

echo "================================"
echo "CCmall JIT-Hub 부하 테스트 시작"
echo "================================"

# 색상 정의
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Step 0: 필수 확인
echo -e "\n${YELLOW}[Step 0] 필수 요소 확인${NC}"
echo "✓ Kubernetes 클러스터 실행 중: $(kubectl cluster-info | grep 'Kubernetes master')"
echo "✓ KEDA 설치 확인: $(kubectl get deployment -n keda | grep 'keda-operator')"
echo "✓ Prometheus 실행 확인: $(kubectl get pod -A | grep prometheus | head -1)"

# Step 1: 서비스 포트포워드 (백그라운드)
echo -e "\n${YELLOW}[Step 1] 서비스 포트포워드 시작${NC}"

# 기존 포트포워드 프로세스 종료
pkill -f "kubectl port-forward" || true
sleep 1

# 포트포워드 실행 (백그라운드)
kubectl port-forward svc/weather-service 8080:8000 -n default &
kubectl port-forward svc/traffic-service 8081:8000 -n default &
kubectl port-forward svc/tourism-service 8082:8000 -n default &

sleep 3
echo "✓ 포트포워드 완료"

# Step 2: 부하 테스트 실행
echo -e "\n${YELLOW}[Step 2] weather-service 부하 테스트${NC}"
k6 run weather-service.js

echo -e "\n${YELLOW}[Step 3] traffic-service 부하 테스트${NC}"
k6 run traffic-service.js

echo -e "\n${YELLOW}[Step 4] tourism-service 부하 테스트${NC}"
k6 run tourism-service.js

# 정리
echo -e "\n${YELLOW}[Step 5] 정리${NC}"
pkill -f "kubectl port-forward" || true

echo -e "\n${GREEN}================================${NC}"
echo -e "${GREEN}부하 테스트 완료!${NC}"
echo -e "${GREEN}================================${NC}"

echo -e "\n${YELLOW}확인 사항:${NC}"
echo "✓ Pod이 3개에서 최대 10개까지 증가했는가?"
echo "✓ 트래픽 감소 후 Pod이 3개로 줄어들었는가?"
echo "✓ Prometheus에서 메트릭이 정상 수집됐는가?"