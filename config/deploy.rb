# config valid for current version and patch releases of Capistrano
lock "~> 3.19.2"

set :application, "qalab"
set :repo_url, "git@github.com:brianbaggs35/qalab.git"

# Default branch is :main
ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default deploy_to directory is /var/www/my_app_name
set :deploy_to, "/var/www/qalab"

# Default value for :format is :airbrussh
set :format, :airbrussh

# You can configure the Airbrussh format using :format_options.
# These are the defaults:
set :format_options, command_output: true, log_file: "log/capistrano.log", color: :auto, truncate: :auto

# Default value for :pty is false
set :pty, true

# Default value for :linked_files is []
append :linked_files, "config/database.yml", "config/master.key", ".env"

# Default value for linked_dirs is []
append :linked_dirs, "log", "tmp/pids", "tmp/cache", "tmp/sockets", "tmp/webpacker", "public/system", "vendor", "storage"

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for local_repository_cache is true
set :local_repository_cache, ".git_cache"

# Default value for keep_releases is 5
set :keep_releases, 5

# Uncomment the following to require manually verifying the host key before first deploy.
# set :ssh_options, verify_host_key: :secure

# Ruby version and rbenv
set :rbenv_type, :user
set :rbenv_ruby, "3.3.7"

# Puma configuration
set :puma_rackup, -> { File.join(current_path, "config.ru") }
set :puma_state, -> { File.join(shared_path, "tmp/pids/puma.state") }
set :puma_pid, -> { File.join(shared_path, "tmp/pids/puma.pid") }
set :puma_bind, -> { "unix://#{shared_path}/tmp/sockets/puma.sock" }
set :puma_conf, -> { File.join(shared_path, "puma.rb") }
set :puma_access_log, -> { File.join(shared_path, "log/puma_access.log") }
set :puma_error_log, -> { File.join(shared_path, "log/puma_error.log") }
set :puma_role, :app
set :puma_env, fetch(:stage)
set :puma_threads, [ 0, 8 ]
set :puma_workers, 0
set :puma_worker_timeout, nil
set :puma_init_active_record, true
set :puma_preload_app, false

namespace :puma do
  desc "Setup puma configuration"
  task :setup do
    on roles(:app) do
      template("puma.rb.erb", "#{shared_path}/puma.rb")
    end
  end
end

namespace :deploy do
  desc "Check and update Ruby version if needed"
  task :check_ruby_version do
    on roles(:app) do
      current_ruby = capture("export PATH=\"$HOME/.rbenv/bin:$PATH\" && eval \"$(rbenv init -)\" && ruby -v")
      required_ruby = fetch(:rbenv_ruby)

      unless current_ruby.include?(required_ruby)
        puts "🔄 Updating Ruby from #{current_ruby.strip} to #{required_ruby}..."
        execute "export PATH=\"$HOME/.rbenv/bin:$PATH\" && eval \"$(rbenv init -)\" && rbenv install #{required_ruby}"
        execute "export PATH=\"$HOME/.rbenv/bin:$PATH\" && eval \"$(rbenv init -)\" && rbenv global #{required_ruby}"
        execute "export PATH=\"$HOME/.rbenv/bin:$PATH\" && eval \"$(rbenv init -)\" && rbenv rehash"
        execute "export PATH=\"$HOME/.rbenv/bin:$PATH\" && eval \"$(rbenv init -)\" && gem install bundler"
      end
    end
  end

  desc "Check for gem updates and security vulnerabilities"
  task :check_gems do
    on roles(:app) do
      within release_path do
        # Check for security vulnerabilities
        execute :bundle, :exec, "bundler-audit", :check, "--update" rescue nil

        # Check for outdated gems
        outdated = capture(:bundle, :outdated) rescue ""
        if outdated.length > 0
          puts "📦 Found outdated gems:\n#{outdated}"
          puts "💡 Run 'bundle update' locally and commit to update gems"
        end
      end
    end
  end

  desc "Restart application"
  task :restart do
    on roles(:app), in: :sequence, wait: 10 do
      if test("[ -f #{shared_path}/tmp/pids/puma.pid ]")
        execute "kill -USR2 `cat #{shared_path}/tmp/pids/puma.pid`"
      else
        within current_path do
          execute :bundle, :exec, :puma, "-C", "#{shared_path}/puma.rb", "-d"
        end
      end
    end
  end

  desc "Create database"
  task :create_database do
    on roles(:db) do
      within release_path do
        with rails_env: fetch(:stage) do
          execute :bundle, :exec, :rake, "db:create"
        end
      end
    end
  end

  desc "Verify deployment health"
  task :verify_deployment do
    on roles(:web) do
      within current_path do
        # Check if the application is responding
        execute :curl, "-f", "-s", "http://localhost/up" rescue begin
          puts "⚠️  Health check failed - application may not be responding"
        end

        # Check nginx status
        execute :sudo, :systemctl, :status, :nginx

        # Check puma process
        if test("[ -f #{shared_path}/tmp/pids/puma.pid ]")
          pid = capture("cat #{shared_path}/tmp/pids/puma.pid")
          execute :ps, "-p", pid rescue begin
            puts "⚠️  Puma process not found - may need manual restart"
          end
        end
      end
    end
  end

  # Enhanced deployment hooks
  before :updating, :check_ruby_version
  after :updated, :check_gems
  after :publishing, :restart
  after :restart, :verify_deployment

  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      # Here we can do anything such as:
      # within release_path do
      #   execute :rake, 'cache:clear'
      # end
    end
  end
end

# Custom tasks
namespace :nginx do
  desc "Generate nginx configuration"
  task :setup do
    on roles(:web) do
      template("nginx_site.erb", "/tmp/nginx_site")
      execute :sudo, :mv, "/tmp/nginx_site", "/etc/nginx/sites-available/#{fetch(:application)}"
      execute :sudo, :ln, "-fs", "/etc/nginx/sites-available/#{fetch(:application)}", "/etc/nginx/sites-enabled/"
      execute :sudo, :nginx, "-t"
      execute :sudo, :service, :nginx, :reload
    end
  end
end

namespace :postgresql do
  desc "Install PostgreSQL"
  task :install do
    on roles(:db) do
      execute :sudo, :apt, :update
      execute :sudo, "apt-get", "install", "-y", "postgresql", "postgresql-contrib", "libpq-dev"
    end
  end

  desc "Create PostgreSQL user and database"
  task :create_user do
    on roles(:db) do
      execute :sudo, "-u", "postgres", "createuser", "-s", fetch(:application)
      execute :sudo, "-u", "postgres", "psql", "-c", "\"ALTER USER #{fetch(:application)} PASSWORD '#{ENV['QALAB_DATABASE_PASSWORD'] || 'changeme'}'\""
    end
  end
end

def template(template_name, target)
  template_path = File.expand_path("../deploy/templates/#{template_name}", __FILE__)
  erb = File.read(template_path)
  upload! StringIO.new(ERB.new(erb).result(binding)), target
end
