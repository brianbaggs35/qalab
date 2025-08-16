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
      # Install rbenv if not present
      unless test("[ -d ~/.rbenv ]")
        execute "curl -fsSL https://github.com/rbenv/rbenv-installer/raw/HEAD/bin/rbenv-installer | bash"
        execute "echo 'export PATH=\"$HOME/.rbenv/bin:$PATH\"' >> ~/.bashrc"
        execute "echo 'eval \"$(rbenv init -)\"' >> ~/.bashrc"
      end
    end
  end

  desc "Setup deploy user"
  task :setup_deploy_user do
    on roles(:app) do
      execute :sudo, "useradd", "-m", "-s", "/bin/bash", "deploy" rescue nil
      execute :sudo, "mkdir", "-p", "/home/deploy/.ssh"
      execute :sudo, "chown", "deploy:deploy", "/home/deploy/.ssh"
      execute :sudo, "chmod", "700", "/home/deploy/.ssh"
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
    invoke 'system:install'
    
    puts "👤 Setting up deploy user..."
    invoke 'system:setup_deploy_user'
    
    # Step 2: Setup database (install PostgreSQL if using local database)
    if fetch(:database_host) == fetch(:deploy_server) || fetch(:database_host).nil?
      puts "🗄️  Installing local PostgreSQL..."
      invoke 'postgresql:install'
      invoke 'postgresql:create_user'
    else
      puts "🌐 Using remote database at #{fetch(:database_host)}"
    end
    
    # Step 3: Setup database configuration
    puts "⚙️  Setting up database configuration..."
    invoke 'database:setup'
    
    # Step 4: Setup puma configuration
    puts "🦁 Setting up Puma configuration..."
    invoke 'puma:setup'
    
    # Step 5: Generate SSL certificate and setup NGINX
    puts "🔒 Generating SSL certificate..."
    invoke 'ssl:generate_self_signed'
    
    puts "🌐 Setting up NGINX configuration..."
    invoke 'nginx:setup'
    
    # Step 6: Run the actual deployment
    puts "🚢 Running initial deployment..."
    invoke 'deploy'
    
    # Step 7: Create and migrate databases
    puts "🗄️  Creating and migrating databases..."
    invoke 'database:create_and_migrate'
    
    puts "✅ Initial deployment completed successfully!"
    puts "🌍 Your application should now be available at: https://#{fetch(:deploy_server)}"
    puts "📝 Remember to:"
    puts "   1. Replace the self-signed SSL certificate with a proper one (Let's Encrypt recommended)"
    puts "   2. Point your domain DNS to this EC2 instance"
    puts "   3. Configure email settings in your .env file"
    puts "   4. Set up regular database backups"
  end
end
