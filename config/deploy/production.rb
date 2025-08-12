# server-based syntax
# ======================
# Define a single server's IP or domain name
# server "example.com", user: "deploy", roles: %w{app db web}, my_property: :my_value

# role-based syntax
# ==================
# Defines a role with one or multiple servers. The primary server in each
# group is considered to be the first unless any hosts have the primary
# property set. Specify the username and a domain or IP for the server.
# Don't use `:all`, it's a meta role.

# Configuration for AWS EC2 deployment
set :stage, :production
set :rails_env, "production"

# Server configuration - set via environment variables or directly
set :deploy_server, ENV["DEPLOY_SERVER"] || ask("Enter your server hostname/IP:", "example.com")

server fetch(:deploy_server),
  user: ENV["DEPLOY_USER"] || "deploy",
  roles: %w[app web db],
  ssh_options: {
    keys: [ ENV["DEPLOY_SSH_KEY"] || "~/.ssh/id_rsa" ],
    forward_agent: true,
    auth_methods: %w[publickey],
    port: ENV["DEPLOY_SSH_PORT"] || 22
  }

# Database configuration
set :database_host, ENV["DATABASE_HOST"] || fetch(:deploy_server)
set :database_name, ENV["DATABASE_NAME"] || "#{fetch(:application)}_production"
set :database_username, ENV["DATABASE_USERNAME"] || fetch(:application)
set :database_password, ENV["DATABASE_PASSWORD"] || ENV["QALAB_DATABASE_PASSWORD"]

# SSL configuration
set :nginx_use_ssl, true
set :nginx_ssl_cert, "/etc/ssl/certs/#{fetch(:application)}.crt"
set :nginx_ssl_key, "/etc/ssl/private/#{fetch(:application)}.key"

# Application specific settings
set :puma_workers, 2
set :puma_threads, [ 2, 16 ]
set :puma_preload_app, true

# Custom deployment hooks
namespace :deploy do
  before :starting, :check_database_configuration
  after :finishing, :notify_deployment

  desc "Check database configuration"
  task :check_database_configuration do
    on roles(:db) do
      if fetch(:database_host) == fetch(:deploy_server)
        info "Using local PostgreSQL on #{fetch(:deploy_server)}"
        # invoke 'postgresql:ensure_installed'
      else
        info "Using remote database at #{fetch(:database_host)}"
      end
    end
  end

  desc "Notify deployment completion"
  task :notify_deployment do
    info "Deployment to #{fetch(:stage)} completed successfully!"
  end
end
