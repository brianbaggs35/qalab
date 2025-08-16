require 'rails_helper'

RSpec.describe "Capistrano deployment configuration" do
  describe "deployment tasks" do
    it "loads all required capistrano tasks" do
      # Test that all our custom tasks are loaded properly
      expect(system("cd #{Rails.root} && bundle exec cap -T")).to be true
    end

    it "includes all expected deployment tasks" do
      task_output = `cd #{Rails.root} && bundle exec cap -T`
      
      # Core deployment tasks
      expect(task_output).to include("deploy:initial")
      expect(task_output).to include("deploy:check_ruby_version")
      expect(task_output).to include("deploy:check_gems")
      expect(task_output).to include("deploy:verify_deployment")
      
      # SSL tasks
      expect(task_output).to include("ssl:generate_letsencrypt")
      expect(task_output).to include("ssl:renew_letsencrypt")
      expect(task_output).to include("ssl:generate_self_signed")
      
      # Maintenance tasks
      expect(task_output).to include("maintenance:backup_database")
      expect(task_output).to include("maintenance:check_resources")
      expect(task_output).to include("maintenance:check_ssl")
      expect(task_output).to include("maintenance:enable")
      expect(task_output).to include("maintenance:disable")
      
      # System tasks
      expect(task_output).to include("system:install")
      expect(task_output).to include("system:setup_deploy_user")
      expect(task_output).to include("system:setup_security")
      
      # Log monitoring tasks
      expect(task_output).to include("logs:app")
      expect(task_output).to include("logs:nginx_access")
      expect(task_output).to include("logs:puma")
    end
  end

  describe "deployment configuration files" do
    it "has all required configuration files" do
      expect(File.exist?(Rails.root.join("Capfile"))).to be true
      expect(File.exist?(Rails.root.join("config/deploy.rb"))).to be true
      expect(File.exist?(Rails.root.join("config/deploy/production.rb"))).to be true
    end

    it "has all required template files" do
      expect(File.exist?(Rails.root.join("config/deploy/templates/nginx_site.erb"))).to be true
      expect(File.exist?(Rails.root.join("config/deploy/templates/puma.rb.erb"))).to be true
      expect(File.exist?(Rails.root.join("config/deploy/templates/database.yml.erb"))).to be true
      expect(File.exist?(Rails.root.join("config/deploy/templates/.env.example"))).to be true
    end

    it "has all required task files" do
      expect(File.exist?(Rails.root.join("lib/capistrano/tasks/setup.rake"))).to be true
      expect(File.exist?(Rails.root.join("lib/capistrano/tasks/maintenance.rake"))).to be true
    end
  end

  describe "nginx configuration template" do
    let(:nginx_template) { File.read(Rails.root.join("config/deploy/templates/nginx_site.erb")) }

    it "includes security headers" do
      expect(nginx_template).to include("Strict-Transport-Security")
      expect(nginx_template).to include("X-Frame-Options")
      expect(nginx_template).to include("X-Content-Type-Options")
      expect(nginx_template).to include("Content-Security-Policy")
    end

    it "configures SSL properly" do
      expect(nginx_template).to include("ssl_protocols TLSv1.2 TLSv1.3")
      expect(nginx_template).to include("ssl_certificate")
      expect(nginx_template).to include("ssl_certificate_key")
    end

    it "includes performance optimizations" do
      expect(nginx_template).to include("gzip on")
      expect(nginx_template).to include("expires 1y")
    end

    it "redirects HTTP to HTTPS" do
      expect(nginx_template).to include("return 301 https://")
    end
  end

  describe "puma configuration template" do
    let(:puma_template) { File.read(Rails.root.join("config/deploy/templates/puma.rb.erb")) }

    it "configures proper environment" do
      expect(puma_template).to include("environment 'production'")
    end

    it "includes worker configuration" do
      expect(puma_template).to include("workers")
      expect(puma_template).to include("threads")
    end

    it "includes proper restart handling" do
      expect(puma_template).to include("preload_app!")
      expect(puma_template).to include("on_worker_boot")
    end
  end

  describe "environment template" do
    let(:env_template) { File.read(Rails.root.join("config/deploy/templates/.env.example")) }

    it "includes all required environment variables" do
      expect(env_template).to include("DEPLOY_SERVER=")
      expect(env_template).to include("QALAB_DATABASE_PASSWORD=")
      expect(env_template).to include("USE_LETSENCRYPT=")
      expect(env_template).to include("LETSENCRYPT_EMAIL=")
      expect(env_template).to include("SMTP_ADDRESS=")
      expect(env_template).to include("MAILER_HOST=")
    end

    it "includes database configuration options" do
      expect(env_template).to include("DATABASE_HOST=")
      expect(env_template).to include("DATABASE_USERNAME=")
      expect(env_template).to include("DATABASE_NAME=")
    end

    it "includes helpful comments and documentation" do
      expect(env_template).to include("# === REQUIRED DEPLOYMENT SETTINGS ===")
      expect(env_template).to include("# === SSL CERTIFICATE CONFIGURATION ===")
      expect(env_template).to include("# === EMAIL CONFIGURATION")
    end
  end
end