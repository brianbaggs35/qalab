namespace :maintenance do
  desc "Create database backup"
  task :backup_database do
    on roles(:db) do
      backup_file = "#{fetch(:application)}_#{Time.now.strftime('%Y%m%d_%H%M%S')}.sql"
      backup_path = "#{shared_path}/backups"
      
      execute :mkdir, "-p", backup_path
      execute :sudo, "-u", "postgres", "pg_dump", fetch(:database_name), ">", "#{backup_path}/#{backup_file}"
      
      # Keep only last 7 backups
      execute "ls -t #{backup_path}/*.sql | tail -n +8 | xargs rm -f" rescue nil
      
      puts "✅ Database backup created: #{backup_file}"
    end
  end

  desc "Monitor system resources"
  task :check_resources do
    on roles(:app) do
      puts "📊 System Resource Usage:"
      
      # Memory usage
      memory = capture("free -h | grep Mem")
      puts "Memory: #{memory}"
      
      # Disk usage
      disk = capture("df -h / | tail -1")
      puts "Disk: #{disk}"
      
      # Load average
      load = capture("uptime")
      puts "Load: #{load}"
      
      # Application logs (last 10 lines)
      puts "\n📋 Recent Application Logs:"
      logs = capture("tail -10 #{shared_path}/log/production.log") rescue "No logs found"
      puts logs
    end
  end

  desc "Update system packages"
  task :update_system do
    on roles(:app) do
      execute :sudo, :apt, :update
      execute :sudo, :apt, :upgrade, "-y"
      execute :sudo, :apt, :autoremove, "-y"
      execute :sudo, :apt, :autoclean
      
      puts "✅ System packages updated"
    end
  end

  desc "Check SSL certificate expiration"
  task :check_ssl do
    on roles(:web) do
      domain = fetch(:deploy_server)
      
      # Check certificate expiration
      cert_info = capture("echo | openssl s_client -connect #{domain}:443 -servername #{domain} 2>/dev/null | openssl x509 -noout -dates") rescue "Certificate check failed"
      puts "🔒 SSL Certificate Info for #{domain}:"
      puts cert_info
      
      # Check if Let's Encrypt certificate
      issuer = capture("echo | openssl s_client -connect #{domain}:443 -servername #{domain} 2>/dev/null | openssl x509 -noout -issuer") rescue ""
      if issuer.include?("Let's Encrypt")
        puts "✅ Using Let's Encrypt certificate"
      else
        puts "⚠️  Not using Let's Encrypt certificate"
      end
    end
  end

  desc "Restart all services"
  task :restart_services do
    on roles(:app) do
      execute :sudo, :systemctl, :restart, :nginx
      invoke "deploy:restart"
      
      puts "✅ All services restarted"
    end
  end

  desc "Enable maintenance mode"
  task :enable do
    on roles(:web) do
      maintenance_page = <<~HTML
        <!DOCTYPE html>
        <html>
        <head>
          <title>Maintenance Mode</title>
          <style>
            body { font-family: Arial, sans-serif; text-align: center; padding: 100px; }
            h1 { color: #333; }
            p { color: #666; }
          </style>
        </head>
        <body>
          <h1>🔧 Maintenance Mode</h1>
          <p>We're temporarily down for maintenance. Please check back soon!</p>
          <p>If you need immediate assistance, please contact support.</p>
        </body>
        </html>
      HTML
      
      upload! StringIO.new(maintenance_page), "/tmp/maintenance.html"
      execute :sudo, :mv, "/tmp/maintenance.html", "#{current_path}/public/maintenance.html"
      
      puts "🔧 Maintenance mode enabled"
    end
  end

  desc "Disable maintenance mode"
  task :disable do
    on roles(:web) do
      execute :sudo, :rm, "-f", "#{current_path}/public/maintenance.html"
      
      puts "✅ Maintenance mode disabled"
    end
  end
end

namespace :logs do
  desc "Show application logs"
  task :app do
    on roles(:app) do
      execute :tail, "-f", "#{shared_path}/log/production.log"
    end
  end

  desc "Show nginx access logs"
  task :nginx_access do
    on roles(:web) do
      execute :sudo, :tail, "-f", "/var/log/nginx/access.log"
    end
  end

  desc "Show nginx error logs"
  task :nginx_error do
    on roles(:web) do
      execute :sudo, :tail, "-f", "/var/log/nginx/error.log"
    end
  end

  desc "Show puma logs"
  task :puma do
    on roles(:app) do
      execute :tail, "-f", "#{shared_path}/log/puma.stdout.log"
    end
  end
end