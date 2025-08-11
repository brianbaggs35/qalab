# QA Lab

A comprehensive Quality Assurance and Testing Management application built with Rails 8.0.2 and modern web technologies.

## Features

### 🔐 Authentication & Authorization
- **Secure Authentication**: Implemented with Devise including confirmable, lockable, and trackable modules
- **Role-Based Access Control**: Pundit-powered authorization with hierarchical roles
- **Password Security**: Minimum 12-character passwords with secure token generation
- **Account Security**: Automatic lockout after 5 failed attempts, unlock via email or time-based
- **Session Management**: 2-hour session timeout for enhanced security

### 👥 Multi-Tenant Organization Management
- **Organizations**: Multi-tenant architecture with organization-based separation
- **Role Hierarchy**: System Admin → Owner → Admin → Member
- **User Management**: Invite and manage users within organizations
- **UUID-based**: All primary keys use UUIDs for enhanced security and scalability

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

The application requires SMTP configuration for email features (confirmation, password reset, etc.). Add the following to your environment variables or Rails credentials:

#### For Development (config/environments/development.rb):
```ruby
config.action_mailer.delivery_method = :smtp
config.action_mailer.smtp_settings = {
  address: 'your-smtp-server.com',
  port: 587,
  domain: 'yourdomain.com',
  user_name: ENV['SMTP_USERNAME'],
  password: ENV['SMTP_PASSWORD'],
  authentication: 'plain',
  enable_starttls_auto: true
}
```

#### Environment Variables:
```bash
# Add to .env or your environment
SMTP_USERNAME=your-smtp-username
SMTP_PASSWORD=your-smtp-password
SMTP_DOMAIN=yourdomain.com
```

#### For Production:
Use Rails encrypted credentials:
```bash
bin/rails credentials:edit
```

Add:
```yaml
smtp:
  username: your-smtp-username
  password: your-smtp-password
  domain: yourdomain.com
```

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
