namespace :database do
  desc "Generate database configuration"
  task :setup do
    on roles(:app) do
      template("database.yml.erb", "#{shared_path}/config/database.yml")
    end
  end

  desc "Create and setup databases"
  task :create_and_migrate do
    on roles(:db) do
      within release_path do
        with rails_env: fetch(:stage) do
          execute :bundle, :exec, :rake, "db:create"
          execute :bundle, :exec, :rake, "db:migrate"
          execute :bundle, :exec, :rake, "db:seed"
        end
      end
    end
  end
end

namespace :system do
  desc "Install system dependencies"
  task :install do
    on roles(:app) do
      execute :sudo, :apt, :update
      execute :sudo, "apt-get", "install", "-y", "nodejs", "npm", "nginx", "curl", "gnupg2", "software-properties-common"
      execute :sudo, "apt-get", "install", "-y", "build-essential", "libssl-dev", "libreadline-dev", "zlib1g-dev", "libyaml-dev", "libxml2-dev", "libxslt1-dev"
      execute :sudo, "apt-get", "install", "-y", "git", "autoconf", "bison", "libffi-dev", "libgdbm-dev", "libncurses5-dev", "libsqlite3-dev", "libtool"

      # Install rbenv if not present
      unless test("[ -d ~/.rbenv ]")
        execute "curl -fsSL https://github.com/rbenv/rbenv-installer/raw/HEAD/bin/rbenv-installer | bash"
        execute "echo 'export PATH=\"$HOME/.rbenv/bin:$PATH\"' >> ~/.bashrc"
        execute "echo 'eval \"$(rbenv init -)\"' >> ~/.bashrc"

        # Source rbenv for current session
        execute "export PATH=\"$HOME/.rbenv/bin:$PATH\" && eval \"$(rbenv init -)\""
      end

      # Install specified Ruby version if not already installed
      ruby_version = fetch(:rbenv_ruby)
      unless test("[ -d ~/.rbenv/versions/#{ruby_version} ]")
        execute "export PATH=\"$HOME/.rbenv/bin:$PATH\" && eval \"$(rbenv init -)\" && rbenv install #{ruby_version}"
        execute "export PATH=\"$HOME/.rbenv/bin:$PATH\" && eval \"$(rbenv init -)\" && rbenv global #{ruby_version}"
        execute "export PATH=\"$HOME/.rbenv/bin:$PATH\" && eval \"$(rbenv init -)\" && rbenv rehash"
      end

      # Install bundler
      execute "export PATH=\"$HOME/.rbenv/bin:$PATH\" && eval \"$(rbenv init -)\" && gem install bundler"
    end
  end

  desc "Setup deploy user"
  task :setup_deploy_user do
    on roles(:app) do
      # Create deploy user if not exists
      execute :sudo, "useradd", "-m", "-s", "/bin/bash", "deploy" rescue nil
      execute :sudo, "mkdir", "-p", "/home/deploy/.ssh"
      execute :sudo, "chown", "deploy:deploy", "/home/deploy/.ssh"
      execute :sudo, "chmod", "700", "/home/deploy/.ssh"

      # Add deploy user to sudo group for deployment tasks
      execute :sudo, "usermod", "-a", "-G", "sudo", "deploy"

      # Setup SSH key for deploy user if provided
      if ENV["DEPLOY_SSH_KEY"]
        ssh_key = File.read(File.expand_path(ENV["DEPLOY_SSH_KEY"]))
        execute :sudo, "bash", "-c", "echo '#{ssh_key}' > /home/deploy/.ssh/authorized_keys"
        execute :sudo, "chown", "deploy:deploy", "/home/deploy/.ssh/authorized_keys"
        execute :sudo, "chmod", "600", "/home/deploy/.ssh/authorized_keys"
      end
    end
  end

  desc "Setup server security (firewall, etc.)"
  task :setup_security do
    on roles(:app) do
      # Install and configure UFW firewall
      execute :sudo, "apt-get", "install", "-y", "ufw"
      execute :sudo, "ufw", "default", "deny", "incoming"
      execute :sudo, "ufw", "default", "allow", "outgoing"
      execute :sudo, "ufw", "allow", "ssh"
      execute :sudo, "ufw", "allow", "80"
      execute :sudo, "ufw", "allow", "443"
      execute :sudo, "ufw", "--force", "enable"

      # Install fail2ban for SSH protection
      execute :sudo, "apt-get", "install", "-y", "fail2ban"
      execute :sudo, "systemctl", "enable", "fail2ban"
      execute :sudo, "systemctl", "start", "fail2ban"

      # Configure automatic security updates
      execute :sudo, "apt-get", "install", "-y", "unattended-upgrades"
      execute :sudo, "dpkg-reconfigure", "-plow", "unattended-upgrades"
    end
  end
end

namespace :ssl do
  desc "Generate self-signed SSL certificate"
  task :generate_self_signed do
    on roles(:web) do
      execute :sudo, "mkdir", "-p", "/etc/ssl/certs", "/etc/ssl/private"
      execute :sudo, "openssl", "req", "-x509", "-nodes", "-days", "365",
              "-newkey", "rsa:2048",
              "-keyout", "/etc/ssl/private/#{fetch(:application)}.key",
              "-out", "/etc/ssl/certs/#{fetch(:application)}.crt",
              "-subj", "/C=US/ST=State/L=City/O=Organization/CN=#{fetch(:deploy_server)}"
      execute :sudo, "chmod", "600", "/etc/ssl/private/#{fetch(:application)}.key"
    end
  end

  desc "Install certbot and generate Let's Encrypt SSL certificate"
  task :generate_letsencrypt do
    on roles(:web) do
      # Install certbot
      execute :sudo, "apt-get", "update"
      execute :sudo, "apt-get", "install", "-y", "certbot", "python3-certbot-nginx"

      # Stop nginx temporarily to allow certbot to bind to port 80
      execute :sudo, "systemctl", "stop", "nginx"

      # Generate certificate
      domain = fetch(:deploy_server)
      email = ENV["LETSENCRYPT_EMAIL"] || ask("Enter email for Let's Encrypt:", "admin@#{domain}")

      execute :sudo, "certbot", "certonly", "--standalone",
              "--non-interactive", "--agree-tos",
              "--email", email,
              "-d", domain

      # Update nginx SSL paths to use Let's Encrypt certificates
      set :nginx_ssl_cert, "/etc/letsencrypt/live/#{domain}/fullchain.pem"
      set :nginx_ssl_key, "/etc/letsencrypt/live/#{domain}/privkey.pem"

      # Start nginx back up
      execute :sudo, "systemctl", "start", "nginx"

      # Setup auto-renewal cron job
      cron_job = "0 2 * * * /usr/bin/certbot renew --quiet --post-hook 'systemctl reload nginx'"
      execute :sudo, "bash", "-c", "echo '#{cron_job}' | crontab -"
    end
  end

  desc "Renew Let's Encrypt SSL certificate"
  task :renew_letsencrypt do
    on roles(:web) do
      execute :sudo, "certbot", "renew", "--quiet", "--post-hook", "systemctl reload nginx"
    end
  end
end

# Hook tasks
# before 'deploy:check:directories', 'system:install'
# before 'deploy:check:linked_files', 'database:setup'
# before 'nginx:setup', 'ssl:generate_self_signed'

namespace :deploy do
  desc "Initial deployment setup - installs all dependencies and configures the server"
  task :initial do
    puts "🚀 Starting initial deployment setup for #{fetch(:application)} on #{fetch(:deploy_server)}"

    # Step 1: Install system dependencies and setup deploy user
    puts "📦 Installing system dependencies..."
    invoke "system:install"

    puts "👤 Setting up deploy user..."
    invoke "system:setup_deploy_user"

    puts "🔒 Setting up server security..."
    invoke "system:setup_security"

    # Step 2: Setup database (install PostgreSQL if using local database)
    if fetch(:database_host) == fetch(:deploy_server) || fetch(:database_host).nil?
      puts "🗄️  Installing local PostgreSQL..."
      invoke "postgresql:install"
      invoke "postgresql:create_user"
    else
      puts "🌐 Using remote database at #{fetch(:database_host)}"
    end

    # Step 3: Setup database configuration
    puts "⚙️  Setting up database configuration..."
    invoke "database:setup"

    # Step 4: Setup puma configuration
    puts "🦁 Setting up Puma configuration..."
    invoke "puma:setup"

    # Step 5: Generate SSL certificate - prefer Let's Encrypt if domain is provided
    if ENV["USE_LETSENCRYPT"] == "true" || ENV["LETSENCRYPT_EMAIL"]
      puts "🔒 Generating Let's Encrypt SSL certificate..."
      invoke "ssl:generate_letsencrypt"
    else
      puts "🔒 Generating self-signed SSL certificate..."
      invoke "ssl:generate_self_signed"
      puts "⚠️  Using self-signed certificate. Set USE_LETSENCRYPT=true for production."
    end

    puts "🌐 Setting up NGINX configuration..."
    invoke "nginx:setup"

    # Step 6: Run the actual deployment
    puts "🚢 Running initial deployment..."
    invoke "deploy"

    # Step 7: Create and migrate databases
    puts "🗄️  Creating and migrating databases..."
    invoke "database:create_and_migrate"

    puts "✅ Initial deployment completed successfully!"
    puts "🌍 Your application should now be available at: https://#{fetch(:deploy_server)}"
    puts "📝 Next steps:"
    if ENV["USE_LETSENCRYPT"] != "true" && !ENV["LETSENCRYPT_EMAIL"]
      puts "   1. For production, run: USE_LETSENCRYPT=true bundle exec cap production ssl:generate_letsencrypt"
    end
    puts "   2. Point your domain DNS to this EC2 instance"
    puts "   3. Configure email settings in your .env file"
    puts "   4. Set up regular database backups"
    puts "   5. Configure monitoring and log aggregation"
  end
end
