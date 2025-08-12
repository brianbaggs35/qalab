# QA Lab

A comprehensive Quality Assurance and Testing Management application built with Rails 8.0.2 and modern web technologies.

## Features

### 🔐 Authentication & Authorization
- **Invitation-Only Registration**: Secure sign-up system requiring valid invitation codes
- **Secure Authentication**: Implemented with Devise including confirmable, lockable, and trackable modules
- **Role-Based Access Control**: Pundit-powered authorization with hierarchical roles
- **Invitation Management**: Comprehensive invitation system with token-based security
- **Email Integration**: Professional invitation emails with organization branding
- **Password Security**: Minimum 12-character passwords with secure token generation
- **Account Security**: Automatic lockout after 5 failed attempts, unlock via email or time-based
- **Session Management**: 2-hour session timeout for enhanced security

### 👥 Multi-Tenant Organization Management
- **Organizations**: Multi-tenant architecture with organization-based separation
- **Role Hierarchy**: System Admin → Owner → Admin → Member
- **Invitation System**: Secure, token-based user invitation system
- **User Management**: Invite and manage users within organizations
- **UUID-based**: All primary keys use UUIDs for enhanced security and scalability

### 📧 Invitation System
- **Invitation-Only Registration**: All new users must be invited by existing organization members
- **Role-Based Invitations**: Owners can invite any role, Admins can invite Admins/Members
- **Secure Token System**: Cryptographically secure invitation tokens with expiration
- **Email Integration**: Professional invitation emails with accept links
- **Permission Control**: Comprehensive authorization for invitation management
- **Multi-Organization Support**: Users can be invited to multiple organizations with different roles

### 📊 Interactive Dashboard
- **Real-time Metrics**: User registrations, organization growth, role distribution
- **Data Visualization**: Charts and graphs powered by Chartkick
- **Responsive Design**: Modern UI built with Tailwind CSS and DaisyUI components
- **Quick Actions**: Easy access to common tasks and organization management

### 🎨 Modern User Interface
- **DaisyUI Components**: Consistent, accessible, and beautiful UI components
- **Responsive Design**: Works seamlessly across desktop, tablet, and mobile devices
- **Custom Theme**: Professional QA Lab branding with consistent color scheme
- **Form Validation**: Real-time validation with helpful error messages

## Tech Stack

- **Backend**: Ruby 3.4.5, Rails 8.0.2
- **Database**: PostgreSQL with UUID support
- **Authentication**: Devise with advanced security features
- **Authorization**: Pundit for policy-based access control
- **Frontend**: Turbo, Stimulus, Tailwind CSS, DaisyUI
- **Charts**: Chartkick with groupdate for data visualization
- **Testing**: RSpec with SimpleCov (90%+ coverage), Jest for JavaScript
- **Code Quality**: RuboCop, Brakeman security scanner

## Setup Instructions

### Prerequisites
- Ruby 3.4.5
- Rails 8.0.2
- PostgreSQL 12+
- Node.js 18+
- npm or yarn

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd qalab
   ```

2. **Install dependencies**
   ```bash
   bundle install
   npm install
   ```

3. **Database setup**
   ```bash
   bin/rails db:create
   bin/rails db:migrate
   bin/rails db:seed
   ```

4. **Start the development server**
   ```bash
   bin/dev
   ```

### SMTP Configuration for Email Features

QA Lab requires SMTP configuration for critical email features including:
- **User Confirmations**: Email verification for new accounts
- **Password Reset**: Secure password recovery emails
- **Invitations**: Organization member invitation emails (invitation-only registration)
- **Account Security**: Account lockout and unlock notifications

#### Configuration Methods

**Option 1: Environment Variables (Recommended for Development)**

Create a `.env` file in your project root:
```bash
# SMTP Configuration
SMTP_ADDRESS=smtp.gmail.com
SMTP_PORT=587
SMTP_DOMAIN=yourdomain.com
SMTP_USERNAME=your-email@gmail.com
SMTP_PASSWORD=your-app-password
SMTP_AUTHENTICATION=plain
SMTP_ENABLE_STARTTLS=true

# Application Settings
DEFAULT_FROM_EMAIL=noreply@yourdomain.com
DEFAULT_REPLY_TO=support@yourdomain.com
```

Then configure your environment file:

```ruby
# config/environments/development.rb
config.action_mailer.delivery_method = :smtp
config.action_mailer.default_url_options = { host: 'localhost', port: 3000 }
config.action_mailer.smtp_settings = {
  address: ENV['SMTP_ADDRESS'],
  port: ENV['SMTP_PORT'].to_i,
  domain: ENV['SMTP_DOMAIN'],
  user_name: ENV['SMTP_USERNAME'],
  password: ENV['SMTP_PASSWORD'],
  authentication: ENV['SMTP_AUTHENTICATION'],
  enable_starttls_auto: ENV['SMTP_ENABLE_STARTTLS'] == 'true'
}

# Set default from address
config.action_mailer.default_options = {
  from: ENV['DEFAULT_FROM_EMAIL'],
  reply_to: ENV['DEFAULT_REPLY_TO']
}
```

**Option 2: Rails Encrypted Credentials (Recommended for Production)**

Edit your encrypted credentials:
```bash
EDITOR=nano bin/rails credentials:edit
```

Add your SMTP configuration:
```yaml
smtp:
  address: smtp.gmail.com
  port: 587
  domain: yourdomain.com
  username: your-email@gmail.com
  password: your-app-password
  authentication: plain
  enable_starttls: true

email:
  default_from: noreply@yourdomain.com
  default_reply_to: support@yourdomain.com
```

Then configure production:
```ruby
# config/environments/production.rb
config.action_mailer.delivery_method = :smtp
config.action_mailer.default_url_options = { host: 'your-domain.com' }
config.action_mailer.smtp_settings = {
  address: Rails.application.credentials.smtp[:address],
  port: Rails.application.credentials.smtp[:port],
  domain: Rails.application.credentials.smtp[:domain],
  user_name: Rails.application.credentials.smtp[:username],
  password: Rails.application.credentials.smtp[:password],
  authentication: Rails.application.credentials.smtp[:authentication],
  enable_starttls_auto: Rails.application.credentials.smtp[:enable_starttls]
}

config.action_mailer.default_options = {
  from: Rails.application.credentials.email[:default_from],
  reply_to: Rails.application.credentials.email[:default_reply_to]
}
```

#### Popular SMTP Providers

**Gmail (Google Workspace)**
```bash
SMTP_ADDRESS=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your-email@gmail.com
SMTP_PASSWORD=your-app-password  # Generate at https://myaccount.google.com/apppasswords
```

**SendGrid**
```bash
SMTP_ADDRESS=smtp.sendgrid.net
SMTP_PORT=587
SMTP_USERNAME=apikey
SMTP_PASSWORD=your-sendgrid-api-key
```

**Amazon SES**
```bash
SMTP_ADDRESS=email-smtp.us-east-1.amazonaws.com
SMTP_PORT=587
SMTP_USERNAME=your-ses-access-key-id
SMTP_PASSWORD=your-ses-secret-access-key
```

**Mailgun**
```bash
SMTP_ADDRESS=smtp.mailgun.org
SMTP_PORT=587
SMTP_USERNAME=your-mailgun-smtp-username
SMTP_PASSWORD=your-mailgun-smtp-password
```

#### Testing Email Configuration

Test your email configuration with the Rails console:

```ruby
# Start Rails console
bin/rails console

# Test email delivery
UserMailer.test_email('test@example.com').deliver_now

# Test invitation email
org = Organization.first
user = User.first
invitation = Invitation.create!(
  email: 'test@example.com',
  organization: org,
  invited_by: user,
  role: 'member'
)
InvitationMailer.invite_user(invitation).deliver_now
```

#### Email Templates

QA Lab includes professional email templates for:
- **User Confirmation**: Welcome emails with account activation links
- **Password Reset**: Secure password recovery with token links  
- **Invitations**: Branded invitation emails with organization context
- **Account Lockout**: Security notification emails

All emails are responsive and include both HTML and plain text versions.

#### Troubleshooting Email Issues

**Common Issues and Solutions:**

1. **Authentication Failed**
   - Verify username/password credentials
   - Use app-specific passwords for Gmail
   - Check provider-specific authentication requirements

2. **Connection Refused**
   - Verify SMTP server address and port
   - Check firewall and network settings
   - Ensure STARTTLS is properly configured

3. **Emails Not Delivering**
   - Check spam/junk folders
   - Verify domain reputation and SPF records
   - Monitor delivery logs with your provider

4. **Development Testing**
   - Use MailCatcher for local email testing:
     ```bash
     gem install mailcatcher
     mailcatcher
     ```
   - Configure development to use MailCatcher:
     ```ruby
     config.action_mailer.delivery_method = :smtp
     config.action_mailer.smtp_settings = { address: '127.0.0.1', port: 1025 }
     config.action_mailer.default_url_options = { host: '127.0.0.1:3000' }
     ```

#### Security Considerations

- **Never commit SMTP credentials** to version control
- Use **app-specific passwords** for Gmail and similar providers
- Enable **two-factor authentication** on your email provider account
- Regularly **rotate SMTP credentials**
- Monitor **email delivery logs** for security issues
- Use **encrypted credentials** in production environments

### Security Configuration

The application includes several security best practices:

- **Password Requirements**: Minimum 12 characters
- **Account Lockout**: 5 failed attempts trigger lockout
- **Session Security**: 2-hour timeout, secure cookies
- **CSRF Protection**: Enabled by default
- **SQL Injection Prevention**: Using Rails built-in protections
- **XSS Protection**: All user input properly escaped

## User Roles

### System Admin
- Full platform access and management
- Can view all organizations and users
- System-wide configuration and monitoring
- Cannot create organizations (administrative role only)

### Owner
- Full organization management
- Can invite/remove users and set roles
- Can promote users to Admin (but not Owner)
- Can delete the organization

### Admin  
- Organization user management
- Can invite/remove members
- Cannot manage other Admins or Owners
- Full organization feature access

### Member
- Basic organization access
- Can use platform features
- Cannot manage users or organization settings
- Can view organization dashboard

## Development

### Running Tests
```bash
# RSpec tests
bundle exec rspec

# Jest tests  
npm test

# Code coverage
bundle exec rspec
open coverage/index.html
```

### Code Quality
```bash
# Run RuboCop
bundle exec rubocop

# Security scan with Brakeman
bundle exec brakeman

# Fix code style issues
bundle exec rubocop -a
```

### Database Operations
```bash
# Create migration
bin/rails generate migration MigrationName

# Run migrations
bin/rails db:migrate

# Rollback migration
bin/rails db:rollback

# Reset database
bin/rails db:reset
```

## Testing

The application maintains comprehensive test coverage:

- **Model Tests**: Validations, associations, and business logic
- **Controller Tests**: Authentication, authorization, and request handling
- **Integration Tests**: End-to-end user workflows
- **Policy Tests**: Authorization rules and edge cases
- **System Tests**: Full user interface testing

Current test coverage: **90.06%** (exceeds 80% requirement)

## Deployment

The application is ready for deployment with Docker support and includes:

- **Docker Configuration**: Multi-stage Dockerfile for production builds
- **Kamal Deployment**: Modern deployment with zero-downtime updates
- **Asset Pipeline**: Optimized asset compilation and delivery
- **Health Checks**: Built-in health check endpoints for monitoring

## API Documentation

Future versions will include comprehensive API documentation. The current version focuses on web interface functionality with RESTful endpoints.

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions:
- Create an issue in the GitHub repository
- Check the documentation and README
- Review the test suite for usage examples

---

Built with ❤️ for Quality Assurance professionals worldwide.
