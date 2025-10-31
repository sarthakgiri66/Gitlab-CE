# External URL
external_url 'https://gitlab.example.com'


# SMTP Configuration (Zoho Mail)

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
gitlab_rails['smtp_ca_path'] = "/etc/ssl/certs"
gitlab_rails['smtp_ca_file'] = '/etc/ssl/certs/ca-bundle.crt'


# Object Storage (Google Cloud Storage)

gitlab_rails['object_store']['enabled'] = true
gitlab_rails['object_store']['proxy_download'] = false
gitlab_rails['uploads_object_store_enabled'] = true
gitlab_rails['uploads_object_store_remote_directory'] = 'gitlab-example'

gitlab_rails['object_store']['connection'] = {
  'provider' => 'Google',
  'google_project' => 'project-id',
  'google_application_default' => true
}


# Backup Configuration

gitlab_rails['manage_backup_path'] = true
gitlab_rails['backup_path'] = "/var/opt/gitlab/backups"
gitlab_rails['backup_gitaly_backup_path'] = "/opt/gitlab/embedded/bin/gitaly-backup"

# Container Registry Setup

registry_external_url 'https://registry.example.com'

# Registry Configuration
gitlab_rails['registry_enabled'] = true
gitlab_rails['registry_host'] = "registry.example.com"
gitlab_rails['registry_port'] = "80"
gitlab_rails['registry_api_url'] = "http://34.100.200.3:5000"
gitlab_rails['registry_path'] = "/var/opt/gitlab/gitlab-rails/shared/registry"

# Registry Storage (GCS)

registry['storage'] = {
  'gcs' => {
    'bucket' => 'gitlab-example',
    'project_id' => 'project-id',
    'implicit_credentials' => true
  }
}

# Registry NGINX Configuration

registry_nginx['enable'] = true
registry_nginx['listen_port'] = 443
registry_nginx['listen_https'] = true
registry_nginx['ssl_certificate'] = "/etc/gitlab/ssl/registry.example.com.crt"
registry_nginx['ssl_certificate_key'] = "/etc/gitlab/ssl/registry.example.com.key"
registry_nginx['client_max_body_size'] = '1500M'


# Database (Internal PostgreSQL)

registry['database'] = {
  'enabled' => true,
  'host' => '/var/opt/gitlab/postgresql',
  'port' => 5432,
  'user' => 'registry',
  'dbname' => 'registry',
  'sslmode' => 'disable'
}


# NGINX (GitLab Main Service)

nginx['listen_port'] = 443
nginx['listen_https'] = true
nginx['ssl_certificate'] = "/etc/gitlab/ssl/gitlab.example.com.crt"
nginx['ssl_certificate_key'] = "/etc/gitlab/ssl/gitlab.example.com.key"
nginx['client_max_body_size'] = '1024m'

# Gitlab pages
gitlab_pages['enable'] = true
pages_external_url "https://pages.example.com"
gitlab_pages['external_https'] = ["0.0.0.0:8443"]
#gitlab_pages['external_http'] = false
gitlab_pages['cert'] = "/etc/gitlab/ssl/gitlab-cf.crt"
gitlab_pages['key'] = "/etc/gitlab/ssl/gitlab-cf.key"
gitlab_pages['gitlab_server'] = "https://gitlab.example.com"
pages_nginx['enable'] = false


letsencrypt['enable'] = false

# Package repository
gitlab_rails['packages_enabled'] = true
gitlab_rails['packages_storage_path'] = "/var/opt/gitlab/gitlab-rails/shared/packages"


# SSO using Authentic
gitlab_rails['omniauth_allow_single_sign_on'] = ['openid_connect']
gitlab_rails['omniauth_sync_email_from_provider'] = 'openid_connect'
gitlab_rails['omniauth_sync_profile_from_provider'] = ['openid_connect']
gitlab_rails['omniauth_sync_profile_attributes'] = ['email']
gitlab_rails['omniauth_block_auto_created_users'] = false
gitlab_rails['omniauth_auto_link_user'] = ['openid_connect']
gitlab_rails['omniauth_providers'] = [

{
    name: 'openid_connect',
    label: 'Sign In With AD',
    args: {
      name: 'openid_connect',
      scope: ['openid','profile','email'],
      response_type: 'code',
      issuer: 'https://authentic.example.com/application/o/gitlab/',
      discovery: true,
      client_auth_method: 'query',
      uid_field: 'preferred_username',
      send_scope_to_token_endpoint: 'true',
      pkce: true,
      client_options: {
        identifier: '<identifier>',
        secret: '<secret>',
        redirect_uri: 'https://gitlab.example.com/users/auth/openid_connect/callback'
      }
    }
  }

]
