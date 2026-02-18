# Deploy Gitlab
A unified Terraform configuration for deploying a complete Kubernetes cluster on Hetzner Cloud with staged commands.
1. Deploy the server
2. Deploy gitlab

```bash
export TF_VAR_hcloud_token="TOKEN"
export TF_VAR_letsencrypt_email="MAIL"
export TF_VAR_cloudflare_api_token="CLOUDFLARE_TOKEN"
export TF_VAR_gitlab_root_password="GITLAB_PW"
export TF_VAR_gitlab_server_root_password="GITLAB_SERVER_PW"
```

```
tofu apply -target=module.gitlab_server
tofu apply -target=module.gitlab_deploy
```