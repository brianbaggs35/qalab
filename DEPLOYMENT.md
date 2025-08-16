# QALab Capistrano Deployment Guide

This guide covers deploying the QALab application to AWS EC2 using Capistrano with complete automation for both initial setup and continuous deployment.

## 🚀 Overview

QALab includes a complete Capistrano deployment system that can:

- **Initial Deployment (`deploy:initial`)**: Transform a fresh EC2 instance into a fully configured, secure production server
- **Continuous Deployment (`deploy`)**: Deploy code changes, updates, and run migrations seamlessly

## Prerequisites

### Local Development Environment
- **Ruby 3.3.7+** installed via rbenv
- **Bundler** gem installed
- **Git** configured with SSH key access to the repository
- **AWS CLI** configured (optional, for RDS setup)

### AWS EC2 Instance
- **Ubuntu 20.04+ LTS** (recommended)
- **SSH access** with key-based authentication
- **Public IP or domain name**
- **Security Group** with ports 22 (SSH), 80 (HTTP), and 443 (HTTPS) open
- **Minimum 2GB RAM** recommended

### Domain Configuration (Optional but Recommended)
- Domain name pointing to your EC2 instance
- Required for Let's Encrypt SSL certificates

## 🔧 Quick Start

### 1. Environment Configuration

Copy and configure the environment template:

```bash
cp config/deploy/templates/.env.example .env
```

Edit `.env` with your server details:

```bash
# === REQUIRED SETTINGS ===
DEPLOY_SERVER=your-server.example.com
QALAB_DATABASE_PASSWORD=your-secure-database-password

# === SSL CONFIGURATION ===
USE_LETSENCRYPT=true
LETSENCRYPT_EMAIL=admin@your-server.example.com

# === EMAIL CONFIGURATION ===
SMTP_ADDRESS=smtp.gmail.com
SMTP_USERNAME=your-email@gmail.com
SMTP_PASSWORD=your-app-password
MAILER_HOST=your-server.example.com
```

### 2. Initial Deployment (New Server)

For a brand new EC2 instance:

```bash
# Load environment variables
source .env

# Run complete initial setup
bundle exec cap production deploy:initial
```

This **single command** will:
- ✅ Install system dependencies (Node.js, Nginx, build tools)
- ✅ Set up Ruby 3.3.7 via rbenv
- ✅ Create and configure deploy user
- ✅ Install and configure PostgreSQL (or connect to RDS)
- ✅ Set up Nginx with security headers
- ✅ Generate Let's Encrypt SSL certificate (or self-signed fallback)
- ✅ Configure firewall (UFW) and fail2ban
- ✅ Deploy application code
- ✅ Run database migrations and seed data
- ✅ Start all services

### 3. Continuous Deployment

For subsequent deployments after code changes:

```bash
bundle exec cap production deploy
```

This will:
- 🔄 Check and update Ruby version if needed
- 📦 Update gems and check for security vulnerabilities
- 🚢 Deploy the latest code from your repository
- 🗄️ Run database migrations if needed
- 🔄 Restart application services
- ✅ Verify deployment health

## 📋 Configuration Options

### Database Configuration

#### Option 1: Local PostgreSQL (Default)
Leave `DATABASE_HOST` empty. PostgreSQL will be installed and configured automatically.

#### Option 2: AWS RDS
Set the database host in your `.env` file:
```bash
DATABASE_HOST=your-rds-instance.amazonaws.com
DATABASE_USERNAME=qalab
DATABASE_NAME=qalab_production
```

### SSL Certificate Options

#### Let's Encrypt (Recommended for Production)
```bash
USE_LETSENCRYPT=true
LETSENCRYPT_EMAIL=admin@your-domain.com
```

#### Self-Signed (Development/Testing)
```bash
# Don't set USE_LETSENCRYPT or set to false
USE_LETSENCRYPT=false
```

## 🛠️ Available Deployment Tasks

### Core Deployment
```bash
# Complete initial setup for new server
bundle exec cap production deploy:initial

# Regular deployment
bundle exec cap production deploy

# Check deployment status
bundle exec cap production deploy:verify_deployment
```

### SSL Certificate Management
```bash
# Generate Let's Encrypt certificate
bundle exec cap production ssl:generate_letsencrypt

# Renew Let's Encrypt certificate
bundle exec cap production ssl:renew_letsencrypt

# Check certificate expiration
bundle exec cap production maintenance:check_ssl
```

### Database Management
```bash
# Create and migrate databases
bundle exec cap production database:create_and_migrate

# Create database backup
bundle exec cap production maintenance:backup_database
```

### System Maintenance
```bash
# Monitor system resources
bundle exec cap production maintenance:check_resources

# Update system packages
bundle exec cap production maintenance:update_system

# Restart all services
bundle exec cap production maintenance:restart_services
```

### Maintenance Mode
```bash
# Enable maintenance mode
bundle exec cap production maintenance:enable

# Disable maintenance mode
bundle exec cap production maintenance:disable
```

### Log Monitoring
```bash
# View application logs
bundle exec cap production logs:app

# View Nginx access logs
bundle exec cap production logs:nginx_access

# View Nginx error logs
bundle exec cap production logs:nginx_error

# View Puma logs
bundle exec cap production logs:puma
```

## 🔒 Security Features

The deployment automatically configures:

### Web Server Security
- **HTTPS enforcement** with automatic HTTP→HTTPS redirects
- **Modern TLS 1.2/1.3** configuration
- **Security headers**: HSTS, CSP, X-Frame-Options, X-Content-Type-Options
- **Gzip compression** for improved performance

### Server Security
- **UFW Firewall** configured to allow only SSH, HTTP, and HTTPS
- **Fail2ban** protection against SSH brute force attacks
- **Automatic security updates** enabled
- **Deploy user** with minimal required privileges

### Application Security
- **Force SSL** in Rails application
- **DNS rebinding protection**
- **Secure cookie settings**
- **CSRF protection**
- **SQL injection protection** via Rails ORM

## 🔍 Troubleshooting

### Common Issues

#### SSH Connection Problems
```bash
# Check SSH connection
ssh deploy@your-server.example.com

# Use specific SSH key
ssh -i ~/.ssh/your-key deploy@your-server.example.com
```

#### SSL Certificate Issues
```bash
# Check certificate status
bundle exec cap production maintenance:check_ssl

# Regenerate Let's Encrypt certificate
bundle exec cap production ssl:generate_letsencrypt
```

#### Application Not Starting
```bash
# Check system resources
bundle exec cap production maintenance:check_resources

# View application logs
bundle exec cap production logs:app

# Restart services
bundle exec cap production maintenance:restart_services
```

#### Database Connection Issues
```bash
# Check database configuration
bundle exec cap production database:setup

# Verify PostgreSQL is running
ssh deploy@your-server.example.com "sudo systemctl status postgresql"
```

### Getting Help

1. **Check application logs**: `bundle exec cap production logs:app`
2. **Monitor system resources**: `bundle exec cap production maintenance:check_resources`
3. **Verify deployment**: `bundle exec cap production deploy:verify_deployment`
4. **Check SSL status**: `bundle exec cap production maintenance:check_ssl`

## 📈 Post-Deployment

After successful deployment:

1. **DNS Configuration**: Point your domain to the EC2 instance
2. **Email Testing**: Verify SMTP settings work for user registration
3. **Backup Strategy**: Set up automated database backups
4. **Monitoring**: Configure application and server monitoring
5. **Log Management**: Set up log rotation and centralized logging

## 🎯 Production Checklist

- [ ] EC2 instance launched with Ubuntu 20.04+
- [ ] SSH key access configured
- [ ] Domain DNS pointing to server
- [ ] Environment variables configured in `.env`
- [ ] SMTP email settings tested
- [ ] Let's Encrypt email configured
- [ ] Initial deployment completed successfully
- [ ] Application accessible via HTTPS
- [ ] User registration flow tested
- [ ] Database backups configured
- [ ] Monitoring and alerts set up

## 🔄 Deployment Workflow

### Development to Production
1. **Develop features** locally
2. **Test thoroughly** in development
3. **Commit and push** to main branch
4. **Deploy**: `bundle exec cap production deploy`
5. **Verify**: Check application functionality
6. **Monitor**: Watch logs and performance

### Emergency Procedures
```bash
# Quick rollback to previous release
bundle exec cap production deploy:rollback

# Enable maintenance mode
bundle exec cap production maintenance:enable

# Check system health
bundle exec cap production maintenance:check_resources
```

This deployment system provides enterprise-grade automation and security for the QALab application, enabling reliable and secure production deployments with minimal manual intervention.