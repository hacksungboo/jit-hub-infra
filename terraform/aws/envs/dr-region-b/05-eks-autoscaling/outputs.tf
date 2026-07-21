# ec2nodeclass.yaml의 role 필드에 넣을 값
output "karpenter_node_iam_role_name" {
  value = module.karpenter_iam.node_iam_role_name
}

# 디버깅용: Pod의 SA 어노테이션과 일치하는지 확인
output "karpenter_controller_role_arn" {
  value = module.karpenter_iam.iam_role_arn
}