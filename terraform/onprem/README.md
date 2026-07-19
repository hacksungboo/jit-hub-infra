01-onprem-platform 폴더에
terraform.tfvars 파일을 만든 후
cloudflare_api_token  = ""
cloudflare_zone_id    = ""
cloudflare_account_id = ""
domain_name           = ""
을 넣어주세요

- ubuntu01(172.16.8.203)에서 먼저 실행해주세요
  ./make-nfs.sh jithub-authdb
  ./make-nfs.sh jithub-weatherdb
  ./make-nfs.sh jithub-trafficdb
  ./make-nfs.sh jithub-touristdb