# MonacoCookie 🍪

**Monaco Law 1.565 Compliant Cookie Consent Management Platform**

MonacoCookie is a streamlined cookie consent management platform (CMP) designed specifically for compliance with Monaco's Law No. 1.565 (December 3, 2024). The platform provides Monaco-based businesses with an automated, legally compliant solution for managing website cookies and tracking technologies.

## Product Overview

MonacoCookie offers:
- **Automated Cookie Scanning**: Headless browser-based detection of all cookies, localStorage, and sessionStorage
- **Compliant Consent Banner**: Monaco Law 1.565 Article 6 compliant consent widget (French/English)
- **Cookie Blocking Engine**: Prevents non-consented cookies from loading
- **Consent Recording**: Audit-ready logs for APDP inspections
- **Admin Dashboard**: Manage cookies, customize banners, view analytics

### Target Market
- Monaco-based SMEs with websites
- Businesses subject to Monaco Law 1.565 (Articles 5, 6, 11)
- Companies requiring French-language compliance tools

See [PRD.md](PRD.md) for complete product requirements.

## Technology Stack

- **Backend**: Ruby on Rails 8.1 (beta) with Hotwire (Turbo + Stimulus)
- **Database**: PostgreSQL with SolidQueue, SolidCache, SolidCable
- **Frontend**: Import Maps (no Node.js required), TailwindCSS v4
- **Widget**: Vanilla JavaScript (<50KB, zero dependencies)
- **Authentication**: Devise with custom extensions
- **Authorization**: Pundit
- **Testing**: Minitest with fixtures
- **Payments**: Pay gem (~11.0) with Stripe integration

## Requirements

You'll need the following installed to run the application:

* Ruby 3.2+
* PostgreSQL 12+
* Libvips or Imagemagick (for image processing)
* Redis (for caching and background jobs)

Optional:
* [Stripe CLI](https://docs.stripe.com/stripe-cli) for webhook testing
* Docker (for Puppeteer-based cookie scanning)

## Initial Setup

1. **Clone the repository**
   ```bash
   git clone <repository-url> monacookie
   cd monacookie
   ```

2. **Configure database**

   Edit `config/database.yml` and set your PostgreSQL credentials if needed.

3. **Install dependencies and setup database**
   ```bash
   bin/setup
   ```

   This will:
   - Install Ruby and JavaScript dependencies
   - Create and migrate databases
   - Seed initial data

4. **Configure Jumpstart**

   Edit `config/jumpstart.yml` to configure:
   - Application name (default: "Monacookie")
   - Business details
   - Payment processors (Stripe)
   - Background job processor (SolidQueue or Sidekiq)
   - OAuth providers

## Running the Application

### Development Server

```bash
bin/dev
```

This starts Overmind with processes defined in `Procfile.dev` (Rails server, CSS, JS).

Alternatively, run just the Rails server:
```bash
bin/rails server
```

Access the application at `http://localhost:3000`

### Background Jobs

If using SolidQueue:
```bash
bin/jobs
```

If using Sidekiq (configured in `config/jumpstart.yml`):
```bash
bundle exec sidekiq
```

### Testing

Run the full test suite:
```bash
bin/rails test
```

Run system tests:
```bash
bin/rails test:system
```

Run a specific test file:
```bash
bin/rails test test/models/cookie_test.rb
```

Run a specific test:
```bash
bin/rails test test/models/cookie_test.rb:12
```

### Code Quality

Run RuboCop linter:
```bash
bin/rubocop
```

Auto-fix RuboCop issues:
```bash
bin/rubocop -a
```

Security scan:
```bash
bin/brakeman
```

Audit gems for vulnerabilities:
```bash
bin/bundler-audit
```

Run full CI suite:
```bash
bin/ci
```

## Project Structure

```
app/
├── controllers/
│   ├── api/v1/          # API endpoints (consent recording, config delivery)
│   ├── accounts/        # Account management
│   └── cookies/         # Cookie management controllers
├── models/
│   ├── cookie.rb        # Cookie definitions and categorization
│   ├── consent.rb       # Consent log records
│   ├── website.rb       # Customer websites
│   └── concerns/        # Shared model modules
├── services/
│   ├── cookie_scanner_service.rb    # Puppeteer-based scanning
│   └── consent_recorder_service.rb  # Consent logging
├── javascript/
│   ├── controllers/     # Stimulus controllers for dashboard
│   └── widget/          # Consent banner widget (vanilla JS)
└── views/
    ├── cookies/         # Cookie management UI
    ├── consents/        # Consent logs and analytics
    └── dashboard/       # Main dashboard

config/
├── jumpstart.yml        # Jumpstart feature configuration
└── routes/
    ├── api.rb          # API routes
    ├── accounts.rb     # Account management routes
    └── billing.rb      # Subscription management routes

public/
└── widget.js           # Compiled consent banner widget
```

## Monaco Law 1.565 Compliance

MonacoCookie implements the following requirements:

### Article 6 - Consent Requirements
- ✅ **Libre (Free)**: No pre-checked boxes, equal prominence for Accept/Reject
- ✅ **Spécifique (Specific)**: Granular consent per cookie category
- ✅ **Éclairé (Informed)**: Clear description of each category, privacy policy link
- ✅ **Univoque (Unambiguous)**: Requires explicit click (no implied consent)
- ✅ **Easy withdrawal**: One-click consent withdrawal, same interface as initial consent

### Article 11 - Transparency Requirements
- Banner clearly states purpose of cookies
- Link to privacy policy
- Cookie categories with descriptions
- Data retention period (12 months)
- Right to withdraw consent

### Cookie Categories
1. **Nécessaires** (Necessary): Essential for site function
2. **Préférences** (Preferences): User settings, language
3. **Statistiques** (Statistics): Analytics, non-personalized
4. **Marketing**: Advertising, tracking, personalized content

## Development Workflow

### Adding New Features

1. Create a feature branch:
   ```bash
   git checkout -b feature/new-feature
   ```

2. Write tests first (TDD approach):
   ```bash
   # Create test file in test/ directory
   bin/rails test test/models/new_feature_test.rb
   ```

3. Implement the feature following conventions in [CLAUDE.md](CLAUDE.md)

4. Run tests and linting:
   ```bash
   bin/rails test
   bin/rubocop
   ```

5. Commit and push:
   ```bash
   git add .
   git commit -m "Add new feature"
   git push origin feature/new-feature
   ```

### Service Objects

Business logic should be extracted into service objects in `app/services/`:

```ruby
class CookieScannerService
  def initialize(website)
    @website = website
  end

  def run
    # Scan logic here
  end
end
```

See `.cursor/rules/1005-service-objects.mdc` for detailed patterns.

### Testing Guidelines

- Use Minitest with fixtures
- Test files in `test/` mirror `app/` structure
- Fixtures in `test/fixtures/`
- Follow patterns in `.cursor/rules/1006-testing.mdc`

## Deployment

### With Kamal

```bash
bin/kamal deploy
```

See [Kamal documentation](https://kamal-deploy.org/) for configuration.

### Environment Variables

Required environment variables (set in production):

```bash
# Database
DATABASE_URL=postgresql://...

# Rails
RAILS_MASTER_KEY=...  # or use credentials

# Stripe (if payments enabled)
STRIPE_PUBLIC_KEY=...
STRIPE_SECRET_KEY=...
STRIPE_WEBHOOK_SECRET=...

# Email (if using Postmark)
POSTMARK_API_KEY=...

# CDN (for widget delivery)
CLOUDFLARE_API_KEY=...
```

## Merging Jumpstart Pro Updates

This application is built on Jumpstart Pro Rails. To merge updates:

```bash
git fetch jumpstart-pro
git merge jumpstart-pro/main
```

Review changes carefully, especially in:
- `app/models/user.rb`
- `app/models/account.rb`
- `config/routes/`
- `lib/jumpstart/`

## Contributing

### For Internal Team

1. Follow conventions in [CLAUDE.md](CLAUDE.md)
2. Follow Cursor rules in `.cursor/rules/`
3. Write tests for all new features
4. Use service objects for complex business logic
5. Keep controllers thin
6. Document with YARD comments

### Code Standards

- **Ruby Style**: 2 spaces, snake_case, RuboCop compliant
- **Rails Conventions**: RESTful routes, skinny controllers
- **Testing**: Minitest, fixtures, >80% coverage
- **Documentation**: YARD comments for public methods
- **Security**: Never commit secrets, use Rails credentials

## Resources

- **Product Requirements**: [PRD.md](PRD.md)
- **Development Guide**: [CLAUDE.md](CLAUDE.md)
- **Monaco Law 1.565**: See `docs/loi-rgpd-monaco.txt`
- **Jumpstart Pro Docs**: [https://jumpstartrails.com/docs](https://jumpstartrails.com/docs)

## License

Proprietary - Monaco RGPD © 2025

## Support

- **Technical Issues**: Create an issue in the repository
- **Product Questions**: Contact product team
- **Security Issues**: security@monacocookie.mc
