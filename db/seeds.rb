# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Create a system admin user if none exists
if User.system_admins.empty?
  system_admin = User.create!(
    email: "admin@qalab.local",
    password: "AdminPassword123!",
    password_confirmation: "AdminPassword123!",
    first_name: "System",
    last_name: "Administrator",
    role: "system_admin",
    confirmed_at: Time.current
  )

  puts "Created system admin: #{system_admin.email}"
end

# Create a sample organization with users for development
if Rails.env.development? && Organization.count == 0
  # Create sample organization
  org = Organization.create!(
    name: "Sample QA Team",
    settings: {
      timezone: "UTC",
      notification_settings: {
        email_notifications: true,
        slack_notifications: false
      }
    }
  )

  # Create sample users
  owner = User.create!(
    email: "owner@qalab.local",
    password: "Password123!",
    password_confirmation: "Password123!",
    first_name: "John",
    last_name: "Doe",
    role: "member",
    confirmed_at: Time.current
  )

  admin_user = User.create!(
    email: "admin.user@qalab.local",
    password: "Password123!",
    password_confirmation: "Password123!",
    first_name: "Jane",
    last_name: "Smith",
    role: "member",
    confirmed_at: Time.current
  )

  member = User.create!(
    email: "member@qalab.local",
    password: "Password123!",
    password_confirmation: "Password123!",
    first_name: "Bob",
    last_name: "Johnson",
    role: "member",
    confirmed_at: Time.current
  )

  # Create organization relationships
  OrganizationUser.create!(organization: org, user: owner, role: "owner")
  OrganizationUser.create!(organization: org, user: admin_user, role: "admin")
  OrganizationUser.create!(organization: org, user: member, role: "member")

  # Create sample test runs
  3.times do |i|
    test_run = TestRun.create!(
      name: "Sample Test Run #{i + 1}",
      description: "This is a sample test run for development purposes",
      environment: [ "development", "staging", "production" ].sample,
      test_suite: "smoke_tests",
      xml_file: "<testsuites><testsuite name='SampleTest' tests='10' failures='#{rand(3)}' skipped='0' time='#{rand(10) + 1}.#{rand(9)}'></testsuite></testsuites>",
      status: [ "completed", "failed", "pending" ].sample,
      organization: org,
      user: [ owner, admin_user, member ].sample
    )

    # Process the test run to generate results summary
    test_run.process_xml_file if test_run.xml_file.present?
  end

  puts "Created sample organization '#{org.name}' with #{org.users.count} users and #{org.test_runs.count} test runs"
end
