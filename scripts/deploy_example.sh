#!/bin/bash
# QALab Deployment Example Script
# This script demonstrates the complete deployment workflow

set -e

echo "🚀 QALab Deployment Example"
echo "=========================="

# Check required environment variables
if [ -z "$DEPLOY_SERVER" ]; then
    echo "❌ Error: DEPLOY_SERVER environment variable is required"
    echo "Example: export DEPLOY_SERVER=your-server.example.com"
    exit 1
fi

if [ -z "$QALAB_DATABASE_PASSWORD" ]; then
    echo "❌ Error: QALAB_DATABASE_PASSWORD environment variable is required"
    echo "Example: export QALAB_DATABASE_PASSWORD=your-secure-password"
    exit 1
fi

echo "📋 Configuration:"
echo "  Server: $DEPLOY_SERVER"
echo "  Database: ${DATABASE_HOST:-Local PostgreSQL}"
echo "  SSL: ${USE_LETSENCRYPT:-Self-signed}"
echo ""

# Ask for confirmation
read -p "🤔 Continue with deployment? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Deployment cancelled"
    exit 1
fi

echo "📦 Installing bundle dependencies..."
bundle install --quiet

echo "🔍 Running deployment configuration tests..."
bundle exec rspec spec/deployment/capistrano_spec.rb --format progress

echo "🔧 Checking capistrano configuration..."
bundle exec cap production doctor:environment --dry-run

echo ""
echo "🚀 Starting deployment..."
echo "This will:"
echo "  ✅ Install system dependencies (Node.js, Nginx, build tools)"
echo "  ✅ Set up Ruby 3.3.7 via rbenv"
echo "  ✅ Create and configure deploy user"
echo "  ✅ Install PostgreSQL (or connect to RDS)"
echo "  ✅ Configure Nginx with security headers"
echo "  ✅ Generate SSL certificate (Let's Encrypt or self-signed)"
echo "  ✅ Set up firewall and security (UFW, fail2ban)"
echo "  ✅ Deploy application code"
echo "  ✅ Run database migrations"
echo "  ✅ Start all services"
echo ""

read -p "🚀 Ready to deploy? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Deployment cancelled"
    exit 1
fi

echo "🚢 Running initial deployment..."
bundle exec cap production deploy:initial

echo ""
echo "✅ Deployment completed successfully!"
echo "🌍 Your application should be available at: https://$DEPLOY_SERVER"
echo ""
echo "📋 Next steps:"
echo "  1. Test the application in your browser"
echo "  2. Register the first user (will become organization owner)"
echo "  3. Configure email settings if not done already"
echo "  4. Set up regular database backups"
echo ""
echo "🔧 Useful commands:"
echo "  bundle exec cap production deploy                    # Regular deployment"
echo "  bundle exec cap production maintenance:check_ssl    # Check SSL status"
echo "  bundle exec cap production logs:app                 # View application logs"
echo "  bundle exec cap production maintenance:enable       # Enable maintenance mode"
echo ""