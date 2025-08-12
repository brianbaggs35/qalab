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
