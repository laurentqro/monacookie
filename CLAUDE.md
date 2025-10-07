# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Monacookie is a multi-tenant SaaS application built with Jumpstart Pro Rails, a commercial Rails 8 starter template. It provides subscription billing, team management, authentication, and modern Rails patterns for building subscription-based web applications.

## Development Commands

```bash
# Initial setup
bin/setup                    # Install dependencies and setup database

# Development server
bin/dev                      # Start development server with Overmind (from Procfile.dev)
bin/rails server            # Standard Rails server only

# Database
bin/rails db:prepare         # Setup database (creates, migrates, seeds)
bin/rails db:migrate         # Run migrations
bin/rails db:seed           # Seed database

# Testing
bin/rails test              # Run test suite (Minitest)
bin/rails test:system       # Run system tests (Capybara + Selenium)
bin/rails test test/models/user_test.rb  # Run single test file
bin/rails test test/models/user_test.rb:12  # Run single test at line

# Code quality
bin/rubocop                 # Run RuboCop linter
bin/rubocop -a              # Auto-fix RuboCop issues
bin/brakeman                # Security vulnerability scan
bin/bundler-audit           # Audit gems for security issues
bin/ci                      # Run full CI suite

# Background jobs
bin/jobs                    # Start SolidQueue worker (if configured)
bundle exec sidekiq         # Start Sidekiq worker (if configured)

# Deployment
bin/kamal deploy            # Deploy with Kamal
```

## Technology Stack

- **Rails 8.1** (beta) with Hotwire (Turbo + Stimulus)
- **PostgreSQL** as primary database
- **SolidQueue** for background jobs (alternative: Sidekiq)
- **SolidCache** for caching
- **SolidCable** for websockets
- **Import Maps** for JavaScript (no Node.js/npm required)
- **TailwindCSS v4** via tailwindcss-rails gem
- **Devise** for authentication with custom extensions
- **Pundit** for authorization
- **Minitest** for testing with fixtures
- **Pay gem (~11.0)** for unified payment processing
- **Propshaft** for asset pipeline

## Architecture

### Multi-Tenancy System
The application implements account-based multi-tenancy:
- **Account model**: Central tenant entity (can be personal or team)
- **AccountUser join model**: Manages user-account relationships with roles (admin, member, etc.)
- **Current account**: Users can switch between accounts via `switch_account(account)` helper
- **Authorization**: Pundit policies automatically scope data by `current_account`
- **Account types**: Configured via `config/jumpstart.yml` (personal, team, or both)

### Modular Model Pattern
Models use Ruby modules for organization instead of fat models:

```ruby
# app/models/user.rb
class User < ApplicationRecord
  include Accounts, Agreements, Authenticatable, Mentions, Notifiable, Searchable, Theme
end

# app/models/account.rb
class Account < ApplicationRecord
  include Billing, Domains, Transfer, Types
end
```

Module concerns are in `app/models/concerns/` and encapsulate specific functionality (billing, domains, authentication, etc.).

### Jumpstart Configuration System
Dynamic feature management via `config/jumpstart.yml`:
- **Feature toggles**: Payment processors, OAuth providers, integrations, background job processor
- **Runtime gem loading**: `Gemfile.jumpstart` conditionally loads gems based on config
- **Access pattern**: `Jumpstart.config.payment_processors`, `Jumpstart.config.stripe?`, etc.
- **Config attributes**: application_name, business_name, domain, support_email, account_types, etc.

Current configuration:
- Application: "Monacookie" / Business: "Monaco RGPD"
- Account types: both (personal and team)
- OAuth: google-oauth2 enabled
- Background jobs: not configured yet
- Payment processors: not configured yet

### Payment Architecture (Pay gem)
- **Unified interface**: Single API for Stripe, Paddle, Braintree, PayPal, Lemon Squeezy
- **Per-seat billing**: Team accounts with usage-based pricing
- **Subscription management**: In `app/models/account/billing.rb` module
- **Processor-agnostic**: Switch payment processors via configuration

### Routes Organization
Routes are modularized in `config/routes/`:
- `accounts.rb` - Account management, switching, invitations
- `billing.rb` - Subscription, payment, receipt routes
- `users.rb` - User profile, settings, authentication
- `api.rb` - API v1 endpoints with JWT authentication
- `madmin.rb` - Admin interface routes
- `hotwire_native.rb` - Mobile app routes

## Key Development Patterns

### Ruby/Rails Conventions
- **Ruby style**: 2 spaces, snake_case for variables/methods, SCREAMING_SNAKE_CASE for constants
- **Namespacing**: Use `class Module::ClassName` instead of nested `module/class/end`
- **Enums**: Use positional arguments: `enum status: [:draft, :published, :archived]`
- **Credentials**: Access via `Rails.application.credentials.dig(:service, :key)`
- **Jobs**: Pass models directly, not IDs (automatically serialized)
- **Prefixed IDs**: Models use `has_prefix_id :user` for UUIDs with prefixes (e.g., `user_abc123`)

### Controller Patterns
- **Method comments**: Include HTTP verb and full path (e.g., `# GET /accounts`)
- **Pagination**: Use pagy: `@pagy, @resources = pagy(Resource.sort_by_params(params[:sort], sort_direction))`
- **Status codes**: `:see_other` for DELETE redirects, `:unprocessable_content` for failed creates/updates
- **Strong parameters**: Use `params.expect(:resource)` instead of `params.require`
- **Format handling**: Use `respond_to` for HTML/JSON responses
- **Current account**: Available via `current_account` helper

### Model Patterns
- **Documentation**: Add YARD comments to all methods
- **Concerns**: Extract shared functionality into modules in `app/models/concerns/`
- **Store accessor**: For JSON columns: `store_accessor :details, :features`
- **Normalizes**: Use for attribute normalization: `normalizes :email, with: ->(email) { email.downcase }`
- **Strong typing**: Declare attributes: `attribute :currency, default: "usd"`
- **Validation**: Use `validates` with presence, format, inclusion, etc.

### Service Object Pattern
- **Location**: `app/services/`
- **Naming**: Verb + noun + "Service" (e.g., `CreateUserService`)
- **Class format**: `class Service::ClassName` (not nested modules)
- **Interface**: `initialize` for params, `run/call/perform` for execution
- **Documentation**: YARD comments with `@param`, `@return`, `@raise`
- **Single responsibility**: Keep focused on one action
- **Error handling**: Use exceptions or result objects

### Testing Patterns
- **Framework**: Minitest with fixtures in `test/fixtures/`
- **Test naming**: Use `test_` prefix with descriptive names
- **Setup/teardown**: Use for common setup code
- **Assertions**: Use specific assertions that match what you're testing
- **Independence**: Tests must be independent and idempotent
- **Coverage**: Test happy paths, sad paths, and edge cases
- **Note**: Never pipe test output to cat - use `bin/rails test` directly

### Frontend Patterns
- **Hotwire**: Use Turbo Frames and Streams for dynamic updates
- **Stimulus**: JavaScript controllers in `app/javascript/controllers/`
- **TailwindCSS**: All styling with utility classes
- **Responsive**: All UI components must be responsive
- **Dark mode**: All UI components must support dark mode
- **Accessibility**: Ensure semantic HTML and ARIA attributes

## Key Directories

```
app/
├── controllers/
│   ├── accounts/          # Account-scoped controllers
│   ├── api/v1/           # API controllers
│   └── users/            # User-scoped controllers
├── models/
│   ├── concerns/         # Shared model modules
│   ├── user/            # User-related modules
│   └── account/         # Account-related modules
├── policies/            # Pundit authorization policies
├── services/            # Service objects for business logic
├── views/
│   └── shared/          # Shared partials
├── javascript/
│   └── controllers/     # Stimulus controllers
└── components/          # View components

config/
├── routes/              # Modular route definitions
├── jumpstart.yml       # Jumpstart configuration
└── database.yml        # Multi-database setup

lib/
└── jumpstart/          # Core Jumpstart engine

test/
├── fixtures/           # Test data
├── models/            # Model tests
├── controllers/       # Controller tests
├── services/          # Service tests
└── system/           # System tests
```

## Merging Jumpstart Updates

```bash
# Fetch and merge updates from upstream
git fetch jumpstart-pro
git merge jumpstart-pro/main
```

The `jumpstart-pro` remote is the original Jumpstart Pro repository. Updates include bug fixes, new features, and security patches.

## Important Files

- `config/jumpstart.yml` - Feature configuration (payment processors, OAuth, integrations, account types)
- `Gemfile.jumpstart` - Conditionally loaded gems based on Jumpstart config
- `lib/jumpstart/lib/jumpstart/configuration.rb` - Configuration management logic
- `Procfile.dev` - Development process definitions for Overmind
- `.cursor/rules/*.mdc` - Cursor IDE rules for code standards
