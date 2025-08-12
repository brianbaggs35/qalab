namespace :qa_lab do
  namespace :admin do
    desc "Create a new system administrator"
    task create: :environment do
      puts "Creating new system administrator..."
      puts

      print "First Name: "
      first_name = STDIN.gets.chomp

      print "Last Name: "
      last_name = STDIN.gets.chomp

      print "Email: "
      email = STDIN.gets.chomp

      print "Password (leave blank to generate): "
      password = STDIN.gets.chomp

      if password.blank?
        password = SecureRandom.alphanumeric(12)
        puts "Generated password: #{password}"
      end

      begin
        user = User.create!(
          first_name: first_name,
          last_name: last_name,
          email: email,
          password: password,
          password_confirmation: password,
          role: "system_admin",
          confirmed_at: Time.current # Auto-confirm system admins
        )

        puts
        puts "✅ System administrator created successfully!"
        puts "   Name: #{user.full_name}"
        puts "   Email: #{user.email}"
        puts "   ID: #{user.id}"
        puts "   Password: #{password}"
        puts
        puts "The user can now sign in at /users/sign_in"

      rescue ActiveRecord::RecordInvalid => e
        puts
        puts "❌ Failed to create system administrator:"
        e.record.errors.full_messages.each do |message|
          puts "   - #{message}"
        end
        puts
        exit 1
      end
    end

    desc "List all system administrators"
    task list: :environment do
      admins = User.system_admins.order(:created_at)

      if admins.empty?
        puts "No system administrators found."
      else
        puts "System Administrators (#{admins.count}):"
        puts "=" * 50

        admins.each do |admin|
          puts "#{admin.full_name} (#{admin.email})"
          puts "  ID: #{admin.id}"
          puts "  Created: #{admin.created_at.strftime('%Y-%m-%d %H:%M:%S')}"
          puts "  Last Sign In: #{admin.last_sign_in_at&.strftime('%Y-%m-%d %H:%M:%S') || 'Never'}"
          puts "  Status: #{admin.confirmed? ? 'Confirmed' : 'Unconfirmed'}#{admin.access_locked? ? ', Locked' : ''}"
          puts
        end
      end
    end

    desc "Remove system administrator privileges (convert to regular user)"
    task demote: :environment do
      print "Enter the email of the system administrator to demote: "
      email = STDIN.gets.chomp

      user = User.find_by(email: email, role: "system_admin")

      if user.nil?
        puts "❌ System administrator with email '#{email}' not found."
        exit 1
      end

      puts "Found: #{user.full_name} (#{user.email})"
      print "Are you sure you want to remove system admin privileges? (yes/no): "
      confirmation = STDIN.gets.chomp.downcase

      if confirmation == "yes"
        user.update!(role: "member")
        puts "✅ #{user.full_name} has been converted to a regular user."
      else
        puts "Operation cancelled."
      end
    end

    desc "Promote a regular user to system administrator"
    task promote: :environment do
      print "Enter the email of the user to promote: "
      email = STDIN.gets.chomp

      user = User.find_by(email: email)

      if user.nil?
        puts "❌ User with email '#{email}' not found."
        exit 1
      end

      if user.system_admin?
        puts "❌ User '#{user.full_name}' is already a system administrator."
        exit 1
      end

      puts "Found: #{user.full_name} (#{user.email})"
      print "Are you sure you want to grant system admin privileges? (yes/no): "
      confirmation = STDIN.gets.chomp.downcase

      if confirmation == "yes"
        user.update!(role: "system_admin")
        puts "✅ #{user.full_name} has been promoted to system administrator."
      else
        puts "Operation cancelled."
      end
    end
  end
end
