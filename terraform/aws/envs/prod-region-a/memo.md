# Terraform 가이드

### 요구사항

terraform/onprem/01-onprem-platform
terraform/onprem/02-onprem-workloads 
테라폼 코드를  미리 실행해주세요 

EKS 클러스터를 온프레미스 Argo CD에 자동으로 등록하기 위해, 실행 주체인 **mgmt 서버에 Argo CD CLI가 미리 설치**되어 있어야합니다.                                                                                                       
                                                                                                                                
* **Argo CD CLI 설치 명령어:**                                                                                                     
```bash                                                                                                                          
      curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64

      sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd

      rm argocd-linux-amd64
```

### 설정파일 추가 (tailscale_auth_key)
```
# 경로
> jit-hub-infra/terraform/aws/envs/prod-region-a/03-platform/terraform.tfvars
```
```
# 03-platform/terraform.tfvars
tailscale_auth_key = ""
```

### terraform 실행 스크립트 권한부여
```
# 경로
jit-hub-infra/terraform/aws/envs/prod-region-a

> chmod +x deploy.sh
> chmod +x destroy.sh
```

### terraform 실행
```
# 경로
> jit-hub-infra/terraform/aws/envs/prod-region-a

# apply 스크립트 실행
> ./deply.sh

    01-network > 02-eks > 03-platform

# destroy 스크립트 실행
> ./destroy.sh

    03-platform > 02-eks > 01-network
    역순으로 destroy
```







