# QALab Capistrano Deployment Guide

This guide covers deploying the QALab application to AWS EC2 using Capistrano.

## Prerequisites

### Local Machine
- Ruby 3.3.7 installed
- Bundler installed
- SSH key pair for server access

### AWS EC2 Instance
- Ubuntu 20.04+ or similar Linux distribution
- SSH access with sudo privileges
- Port 80 and 443 open for HTTP/HTTPS traffic

## Quick Start

### 1. Configure Your Server

Set your server hostname/IP address:

```bash
export DEPLOY_SERVER=your-ec2-instance.amazonaws.com
```

### 2. Deploy to Production

```bash
# First deployment (includes system setup)
bundle exec cap production deploy:setup
bundle exec cap production deploy

# Subsequent deployments
bundle exec cap production deploy
```

## Configuration Options

### Database Options

#### Option 1: Local PostgreSQL (default)
Leave `DATABASE_HOST` empty or unset. PostgreSQL will be installed on the same EC2 instance.

#### Option 2: AWS RDS
Set the `DATABASE_HOST` environment variable to your RDS endpoint:

```bash
export DATABASE_HOST=your-rds-instance.amazonaws.com
```

### Environment Variables

Create a `.env` file on your server with the following variables:

```bash
# Required
DEPLOY_SERVER=your-server.example.com
QALAB_DATABASE_PASSWORD=your-secure-password

# Email configuration (required for user registration)
SMTP_ADDRESS=smtp.gmail.com
SMTP_USERNAME=your-email@gmail.com
SMTP_PASSWORD=your-app-password
MAILER_HOST=your-server.example.com

# Optional - Database (for RDS)
DATABASE_HOST=your-rds-endpoint.amazonaws.com
DATABASE_USERNAME=qalab
DATABASE_NAME=qalab_production

# Optional - SSH configuration
DEPLOY_USER=deploy
DEPLOY_SSH_KEY=~/.ssh/id_rsa
```

## Deployment Tasks

### System Setup
```bash
bundle exec cap production system:install
```

### Database Management
```bash
# Create and migrate databases
bundle exec cap production database:create_and_migrate

# Setup database configuration
bundle exec cap production database:setup
```

### Web Server Configuration
```bash
# Setup NGINX with SSL
bundle exec cap production nginx:setup
bundle exec cap production ssl:generate_self_signed
```

### PostgreSQL Management
```bash
# Install PostgreSQL (if using local database)
bundle exec cap production postgresql:install
bundle exec cap production postgresql:create_user
```

## Security Features

### SSL/HTTPS
- Automatic HTTP to HTTPS redirect
- Modern TLS 1.2/1.3 configuration
- Security headers (HSTS, CSP, etc.)
- Self-signed certificate generation

### Application Security
- Force SSL in Rails
- DNS rebinding protection
- Secure cookie settings
- CSRF protection
- Content Security Policy headers

## File Structure

```
/var/www/qalab/
├── current/           # Current release (symlink)
├── releases/          # Previous releases
└── shared/           # Shared files and directories
    ├── config/
    │   ├── database.yml
    │   └── master.key
    ├── log/
    ├── tmp/
    └── storage/
```

## Troubleshooting

### Check Application Status
```bash
# Check if Puma is running
bundle exec cap production puma:status

# Check NGINX configuration
bundle exec cap production nginx:test
```

### View Logs
```bash
# Application logs
tail -f /var/www/qalab/shared/log/production.log

# NGINX logs
tail -f /var/www/qalab/shared/log/nginx.access.log
tail -f /var/www/qalab/shared/log/nginx.error.log
```

### Database Connection Issues
```bash
# Test database connection
bundle exec cap production deploy:check
```

## Post-Deployment

After successful deployment:

1. **SSL Certificate**: Replace the self-signed certificate with a proper SSL certificate (Let's Encrypt recommended)
2. **DNS**: Point your domain to the EC2 instance
3. **Backup**: Set up database backups
4. **Monitoring**: Configure application and server monitoring

## User Registration Flow

Once deployed, users can:
1. Visit your application URL
2. Sign up with their email
3. Receive an email invitation
4. Complete the onboarding process
5. Create their organization (first user becomes owner)
6. Invite team members

The onboarding wizard provides a smooth UI/UX for organization setup and user management.