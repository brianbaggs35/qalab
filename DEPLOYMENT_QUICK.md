# 🚀 Quick Deployment Guide

QALab includes a complete Capistrano deployment system that can transform a fresh AWS EC2 instance into a fully configured, secure production server with a single command.

## 📋 Prerequisites

- **AWS EC2 Instance**: Ubuntu 20.04+ with 2GB+ RAM
- **Domain Name**: Pointing to your EC2 instance (recommended)
- **SSH Access**: Key-based authentication configured

## ⚡ Quick Start

### 1. Configure Environment
```bash
# Copy and edit environment configuration
cp config/deploy/templates/.env.example .env
# Edit .env with your server details
```

### 2. Initial Deployment (New Server)
```bash
# Set required environment variables
export DEPLOY_SERVER=your-server.example.com
export QALAB_DATABASE_PASSWORD=your-secure-password
export USE_LETSENCRYPT=true
export LETSENCRYPT_EMAIL=admin@your-domain.com

# Deploy everything automatically
bundle exec cap production deploy:initial
```

This **single command** will:
- ✅ Install system dependencies and Ruby 3.3.7
- ✅ Set up PostgreSQL database
- ✅ Configure Nginx with security headers
- ✅ Generate Let's Encrypt SSL certificate
- ✅ Set up firewall and security hardening
- ✅ Deploy and start the application

### 3. Continuous Deployment
```bash
# For subsequent code updates
bundle exec cap production deploy
```

## 🛠️ Available Commands

```bash
# Deployment
bundle exec cap production deploy:initial      # Complete server setup
bundle exec cap production deploy              # Regular deployment

# SSL Management
bundle exec cap production ssl:generate_letsencrypt  # Generate Let's Encrypt cert
bundle exec cap production ssl:renew_letsencrypt     # Renew certificate

# Maintenance
bundle exec cap production maintenance:backup_database    # Create DB backup
bundle exec cap production maintenance:check_resources    # System health check
bundle exec cap production maintenance:enable             # Maintenance mode on
bundle exec cap production maintenance:disable            # Maintenance mode off

# Monitoring
bundle exec cap production logs:app                # Application logs
bundle exec cap production logs:nginx_access      # Web server access logs
bundle exec cap production maintenance:check_ssl  # SSL certificate status
```

## 🔒 Security Features

- **HTTPS Enforcement**: Automatic HTTP→HTTPS redirects
- **Modern SSL/TLS**: TLS 1.2/1.3 with secure ciphers
- **Security Headers**: HSTS, CSP, X-Frame-Options, etc.
- **Server Hardening**: UFW firewall, fail2ban, auto-updates
- **Let's Encrypt SSL**: Automatic certificate generation and renewal

## 📖 Full Documentation

See [DEPLOYMENT.md](DEPLOYMENT.md) for complete deployment guide with troubleshooting, configuration options, and advanced usage.

---

**Need help?** Check the [deployment tests](spec/deployment/capistrano_spec.rb) or run the [example deployment script](scripts/deploy_example.sh) for a guided setup.