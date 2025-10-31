
🧰 GitLab CE Container Registry — Troubleshooting Guide

------------------------------------------------------------------------

📘 Overview

This document provides a complete troubleshooting guide for issues
encountered during the GitLab CE Container Registry configuration,
especially in setups involving Cloudflare proxy and Omnibus GitLab
installations.

It addresses common errors such as: - HTTP/2 401 Unauthorized -
ActionController::RoutingError (No route matches [POST] "/v2/...") -
bind() to 0.0.0.0:80 failed (98: Address already in use) - Cloudflare
SSL/proxy misconfiguration

------------------------------------------------------------------------

⚙️ Environment Setup

Host: gitlab-vm
Domain: example.com
Registry URL: https://registry.example.com
GitLab URL: https://gitlab.example.com
Proxy/CDN: Cloudflare
Platform: GitLab CE (Omnibus)

------------------------------------------------------------------------

🧾 1. Error Logs

❌ 401 Unauthorized while curling the registry

    curl -I https://registry.example.com/v2/
    HTTP/2 401
    www-authenticate: Bearer realm="https://gitlab.example.com/jwt/auth"

✅ Reason: The 401 response is expected when querying /v2/ without
authentication.

------------------------------------------------------------------------

❌ 404 Not Found while pushing to registry

    docker push registry.example.com/project/app:latest
    unknown: ActionController::RoutingError (No route matches [POST] "/v2/.../blobs/uploads")

✅ Reason: Registry traffic is reaching GitLab Rails instead of Registry
backend.

------------------------------------------------------------------------

❌ NGINX Port Bind Conflict

    bind() to 0.0.0.0:80 failed (98: Address already in use)

✅ Reason: Another service is already using port 80.

------------------------------------------------------------------------

🧩 2. Root Causes & Fixes

✅ Verify Registry Reachability

    curl -vk https://registry.example.com/v2/

Expected:

-   401 Unauthorized → ✅ Registry is accessible
-   Timeout → ❌ Check NGINX or firewall

------------------------------------------------------------------------

✅ Fix GitLab ↔ Registry Mapping

    registry_external_url 'https://registry.example.com'
    gitlab_rails['registry_enabled'] = true
    gitlab_rails['registry_host'] = "registry.example.com"
    registry['enable'] = true
    registry['registry_http_addr'] = "localhost:5000"

------------------------------------------------------------------------

✅ Cloudflare Settings

  Setting       Value
  ------------- ----------------------------------------------
  Proxy Mode    DNS only
  SSL/TLS       Full (Strict)
  Upload Size   Cloudflare limits apply (100 MB on free/pro)

Cloudflare should not proxy Docker /v2/ endpoints.

------------------------------------------------------------------------

✅ Fix SSL Certificate Issues

Ensure wildcard cert matches:

    *.example.com

------------------------------------------------------------------------

✅ Fix Port Conflicts

    sudo lsof -i :80

Stop conflicting service or reassign ports.

------------------------------------------------------------------------

🧰 3. Final Verification

    docker login registry.example.com
    docker push registry.example.com/project/app:latest

✅ Push should succeed.

------------------------------------------------------------------------

✅ Summary Table

  Issue              Cause                            Fix
  ------------------ -------------------------------- ------------------
  401                Expected                         None
  404                Registry traffic goes to Rails   Fix registry URL
  Port 80 conflict   Another service                  Stop it
  Upload failures    Cloudflare                       DNS Only

------------------------------------------------------------------------

✅ Working Configuration

    external_url 'https://gitlab.example.com'

    gitlab_rails['registry_enabled'] = true
    gitlab_rails['registry_host'] = "registry.example.com"
    gitlab_rails['registry_port'] = "80"
    gitlab_rails['registry_api_url'] = "http://<registry-ip>:5000"
    gitlab_rails['registry_path'] = "/var/opt/gitlab/gitlab-rails/shared/registry"

    registry['storage'] = {
      'gcs' => {
        'bucket' => 'gitlab-example',
        'project_id' => 'project-id',
        'implicit_credentials' => true
      }
    }

    registry_nginx['enable'] = true
    registry_nginx['listen_port'] = 443
    registry_nginx['client_max_body_size'] = '1500M'
    registry_nginx['listen_https'] = true
    registry_nginx['ssl_certificate'] = "/etc/gitlab/ssl/registry.example.com.crt"
    registry_nginx['ssl_certificate_key'] = "/etc/gitlab/ssl/registry.example.com.key"

    registry['enable'] = true
    registry['registry_http_addr'] = "0.0.0.0:5000"
    registry['debug_addr'] = "localhost:5001"
    registry['health_storagedriver_enabled'] = true
    registry['log_level'] = 'info'
    registry['log_formatter'] = 'json'

    nginx['listen_port'] = 443
    nginx['listen_https'] = true
    nginx['enable'] = true
    nginx['client_max_body_size'] = '1500M'
    nginx['ssl_certificate'] = "/etc/gitlab/ssl/registry.example.com.crt"
    nginx['ssl_certificate_key'] = "/etc/gitlab/ssl/registry.example.com.key"

------------------------------------------------------------------------

✅ References

-   GitLab Registry Docs
-   Cloudflare Edge SSL Docs
-   GitLab Omnibus Admin Guide
