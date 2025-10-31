# Gitlab-CE
Setup self managed gitlab
# 🧩 GitLab CE Setup Guide

This document provides a **step-by-step setup guide** for deploying **Omnibus GitLab CE** based on the active `gitlab.rb` configuration used in production (`gitlab.example.com`).

---

## 📑 Table of Contents
1. Basic GitLab Configuration
2. SMTP Configuration (Zoho Mail)
3. Object Storage (Google Cloud Storage)
4. Backup Configuration
5. Container Registry Setup
6. Database (Internal PostgreSQL)
7. NGINX (GitLab Main Service)
8. GitLab Pages (Optional)
9. Verification Commands
10. Troubleshooting Notes
11. Summary
12. References

---

## 1️⃣ Basic GitLab Configuration

### **External URL**
```ruby
external_url 'https://gitlab.example.com'
```

- Defines the main GitLab access URL.
- Uses HTTPS and Cloudflare DNS for secure public access.
- SSL certificates are managed manually via `/etc/gitlab/ssl/`.

---

## 2️⃣ SMTP Configuration (Zoho Mail)

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "smtppro.zoho.in"
gitlab_rails['smtp_port'] = 465
gitlab_rails['smtp_user_name'] = "devops-git@example.in"
gitlab_rails['smtp_password'] = "********"
gitlab_rails['smtp_domain'] = "example.in"
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_enable_starttls_auto'] = false
gitlab_rails['smtp_tls'] = true
gitlab_rails['smtp_openssl_verify_mode'] = 'none'
gitlab_rails['gitlab_email_from'] = 'devops-git@example.in'
gitlab_rails['gitlab_email_display_name'] = 'GitLabAdmin'
```

📧 **Purpose:** Enables GitLab to send notifications and system emails via Zoho's SMTP service.  
✅ Uses SSL/TLS for secure communication.

---

## 3️⃣ Object Storage (Google Cloud Storage)

GitLab uses **GCS** instead of local disk storage for artifacts, uploads, and registry data.

```ruby
gitlab_rails['object_store']['enabled'] = true
gitlab_rails['object_store']['proxy_download'] = false
gitlab_rails['uploads_object_store_enabled'] = true
gitlab_rails['uploads_object_store_remote_directory'] = 'gitlab-example'

gitlab_rails['object_store']['connection'] = {
  'provider' => 'Google',
  'google_project' => 'project-id',
  'google_application_default' => true
}
```

📦 **Buckets Used:**  
All GitLab objects are stored in the single bucket **`gitlab-example`**.

🧠 **Why:**
- Centralized storage across instances.
- Reduces VM disk load and improves backup efficiency.

---

## 4️⃣ Backup Configuration

```ruby
gitlab_rails['manage_backup_path'] = true
gitlab_rails['backup_path'] = "/var/opt/gitlab/backups"
gitlab_rails['backup_gitaly_backup_path'] = "/opt/gitlab/embedded/bin/gitaly-backup"
```

💾 **Purpose:**  
Stores local GitLab backups under `/var/opt/gitlab/backups` and Gitaly backups via the embedded binary.

---

## 5️⃣ Container Registry Setup

### **Registry URL**
```ruby
registry_external_url 'https://registry.example.com'
```

💡 Enables GitLab's built-in **Container Registry**, accessible via `registry.example.com`.

### **Registry Configuration**
```ruby
gitlab_rails['registry_enabled'] = true
gitlab_rails['registry_host'] = "registry.example.com"
gitlab_rails['registry_port'] = "80"
gitlab_rails['registry_api_url'] = "http://34.100.200.3:5000"
gitlab_rails['registry_path'] = "/var/opt/gitlab/gitlab-rails/shared/registry"
```

- The registry API communicates over internal port **5000**.
- GCS is used as backend storage.

### **Registry Storage (GCS)**
```ruby
registry['storage'] = {
  'gcs' => {
    'bucket' => 'gitlab-example',
    'project_id' => 'project-id',
    'implicit_credentials' => true
  }
}
```

🧰 All container images are stored in the **same GCS bucket** `gitlab-example`.

### **Registry NGINX Configuration**
```ruby
registry_nginx['enable'] = true
registry_nginx['listen_port'] = 443
registry_nginx['listen_https'] = true
registry_nginx['ssl_certificate'] = "/etc/gitlab/ssl/registry.example.com.crt"
registry_nginx['ssl_certificate_key'] = "/etc/gitlab/ssl/registry.example.com.key"
registry_nginx['client_max_body_size'] = '1500M'
```

- Supports large image uploads (up to **1.5 GB**).  
- Uses SSL via wildcard certificate.  
- Works with Cloudflare (Proxied mode disabled to avoid upload limits).

---

## 6️⃣ Database (Internal PostgreSQL)

```ruby
registry['database'] = {
  'enabled' = true,
  'host' = '/var/opt/gitlab/postgresql',
  'port' = 5432,
  'user' = 'registry',
  'dbname' = 'registry',
  'sslmode' = 'disable'
}
```

💾 Uses the internal PostgreSQL database that ships with Omnibus GitLab.

---

## 7️⃣ NGINX (GitLab Main Service)

```ruby
nginx['listen_port'] = 443
nginx['listen_https'] = true
nginx['ssl_certificate'] = "/etc/gitlab/ssl/gitlab.example.com.crt"
nginx['ssl_certificate_key'] = "/etc/gitlab/ssl/gitlab.example.com.key"
nginx['client_max_body_size'] = '1024m'
```

🌐 Handles HTTPS for GitLab Web UI and API.  
📦 Increased upload size limit for large repositories and artifacts.

---

## 8️⃣ GitLab Pages (Optional)

Configured to use object storage (disabled by default but integrated into bucket `gitlab-example` for future enablement).

---

## 9️⃣ Verification Commands

After editing `/etc/gitlab/gitlab.rb`, run:

```bash
sudo gitlab-ctl reconfigure
sudo gitlab-ctl restart
sudo gitlab-rake gitlab:check SANITIZE=true
```

To verify registry connectivity:

```bash
curl -k https://registry.example.com/v2/
```

---

## 🔟 Troubleshooting Notes

| Issue | Cause | Fix |
|-------|--------|-----|
| **Large Docker push fails** | Cloudflare proxy upload limit | Set DNS Only mode or upgrade plan |
| **SSL handshake failure** | Mismatched certificate | Verify `.crt` and `.key` paths |
| **Cannot authenticate registry** | Invalid JWT token or state | Re-login via GitLab UI and retry push |

---

## ✅ Summary

| Component | Service URL | Backend | Notes |
|------------|--------------|----------|--------|
| **GitLab Web** | `https://gitlab.example.com` | Omnibus NGINX | Wildcard SSL |
| **Registry** | `https://registry.example.com` | GCS | Large uploads supported |
| **Object Store** | `gitlab-example` | GCS | Shared for all GitLab objects |
| **SMTP** | Zoho Mail | SSL | Used for notifications |

---

## 📚 References
- Omnibus GitLab Configuration Docs
- GitLab Container Registry Setup
- Object Storage Integration (GCS)
