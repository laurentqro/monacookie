# Product Requirements Document: MonacoCookie
## Monaco Law 1.565 Compliant Cookie Consent Management Platform

**Version**: 1.0
**Date**: October 7, 2025
**Status**: Planning Phase

---

## 1. Executive Summary

MonacoCookie is a streamlined cookie consent management platform (CMP) designed specifically for compliance with Monaco's Law No. 1.565 (December 3, 2024). The product provides Monaco-based businesses with an automated, legally compliant solution for managing website cookies and tracking technologies.

### Target Market
- Monaco-based SMEs with websites (2,000+ potential customers)
- Businesses subject to Monaco Law 1.565 (Articles 5, 6, 11)
- Companies requiring French-language compliance tools
- Initial focus: 10-50 employee companies

### Product Positioning
"The Monaco-native alternative to Cookiebot - built specifically for Law 1.565 compliance"

---

## 2. Core Problem Statement

Monaco businesses face challenges implementing cookie consent:
1. **Legal Complexity**: Monaco Law 1.565 has specific consent requirements (Article 6) that differ from EU GDPR
2. **Manual Effort**: Identifying and categorizing cookies requires technical expertise
3. **Language Requirements**: French is mandatory for Monaco residents (loi-rgpd-monaco.txt:122-124)
4. **Proof of Compliance**: Need audit-ready consent logs for APDP inspections
5. **Cost**: International solutions (Cookiebot) charge premium prices for features Monaco SMEs don't need

---

## 3. Product Goals

### MVP Goals (Phase 1: Months 1-3)
- Launch functional cookie consent solution for Monaco market
- Achieve 10 paying customers (€2,000 MRR target)
- Provide legally compliant consent collection per Articles 5 & 6
- French-first user experience

### Success Metrics
- Time to implementation: <15 minutes
- Consent rate: >40% (industry benchmark)
- Cookie detection accuracy: >95%
- Customer satisfaction: NPS >50
- Zero APDP compliance violations

---

## 4. Technical Architecture

### 4.1 Technology Stack

**Backend**:
- Ruby on Rails 7 (consistent with broader MonacoGDPR platform)
- PostgreSQL (cookie definitions, consent logs, customer data)
- Redis (caching, rate limiting)
- Sidekiq (background jobs for scanning)

**Frontend - Admin Portal**:
- Hotwire (Turbo + Stimulus)
- Tailwind CSS
- No build step required

**Frontend - Widget (Customer Websites)**:
- Vanilla JavaScript (zero dependencies)
- <50KB compressed
- Supports all modern browsers + IE11
- Loads asynchronously (no impact on page speed)

**Infrastructure**:
- Hosted in Monaco/France (OVH preferred for data residency)
- CDN: Cloudflare (with Monaco edge nodes)
- SSL required (Let's Encrypt)

### 4.2 System Components

```
┌─────────────────────────────────────────────────────────┐
│                  Customer Website                       │
│  ┌──────────────────────────────────────────────────┐  │
│  │  MonacoCookie JS Widget                          │  │
│  │  - Displays consent banner                       │  │
│  │  - Blocks cookies until consent                  │  │
│  │  - Sends consent to API                          │  │
│  └──────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│              MonacoCookie Platform                      │
│  ┌──────────────────────────────────────────────────┐  │
│  │  Rails API                                       │  │
│  │  - Consent recording                             │  │
│  │  - Configuration delivery                        │  │
│  │  - Cookie scanning                               │  │
│  └──────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────┐  │
│  │  Admin Dashboard                                 │  │
│  │  - Account management                            │  │
│  │  - Cookie configuration                          │  │
│  │  - Consent analytics                             │  │
│  │  - Audit logs                                    │  │
│  └──────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

---

## 5. MVP Features (Essential Only)

### 5.1 Automated Cookie Scanning

**Purpose**: Automatically detect cookies on customer websites

**Functionality**:
- Headless browser scan (Puppeteer via Docker container)
- Identifies all cookies, localStorage, sessionStorage
- Categorizes cookies into 4 categories per Monaco law:
  - **Nécessaires** (Necessary): Essential for site function
  - **Préférences** (Preferences): User settings, language
  - **Statistiques** (Statistics): Analytics, non-personalized
  - **Marketing**: Advertising, tracking, personalized content
- Automatic re-scan: Monthly
- Manual scan: On-demand from dashboard

**Technical Notes**:
- Scan job: Sidekiq background worker
- Timeout: 2 minutes per site
- Store: Cookie name, domain, expiry, category, description
- Cookie database: Seed with common Monaco/French cookies (Google Analytics, Facebook Pixel, Matomo, etc.)

**MVP Simplifications**:
- Single page scan only (homepage)
- No deep crawling (save for Phase 2)
- Manual categorization override in dashboard

### 5.2 Consent Banner Widget

**Purpose**: Display legally compliant consent banner on customer websites

**Functionality**:
- **Position**: Bottom banner (default) or modal popup
- **Language**: French (primary), English (secondary)
- **Content** (per Article 6, Article 11):
  - Clear description of cookie usage
  - Cookie categories with granular opt-in checkboxes
  - Links to privacy policy (customer-provided URL)
  - "Accepter tout" (Accept all) button
  - "Refuser tout" (Reject all) button
  - "Personnaliser" (Customize) button → opens category selection
  - Easy withdrawal mechanism (small footer icon)
- **Behavior**:
  - Blocks all non-necessary cookies until consent given
  - Records consent choices to MonacoCookie API
  - Stores consent decision in browser (365-day cookie)
  - Shows re-consent banner after 12 months (Monaco standard)

**Compliance Features** (Article 6 requirements):
- ✅ Clear positive action required (no pre-checked boxes)
- ✅ Distinguished from other content (banner/modal design)
- ✅ Granular control (category-level consent)
- ✅ Easy to withdraw as to give (footer widget always visible)
- ✅ No "cookie wall" (can refuse without losing access)

**Customization Options**:
- Primary color (brand color)
- Banner position (bottom/top/modal)
- Logo upload
- Privacy policy URL
- Custom intro text (140 char limit)

**Technical Specs**:
- Single `<script>` tag integration
- Lazy load (no render blocking)
- Respects "Do Not Track" browser signal
- WCAG 2.1 AA accessible

**MVP Simplifications**:
- 2 languages only (French, English)
- 3 pre-designed templates (no custom CSS)
- Text-only (no images beyond logo)

### 5.3 Cookie Blocking Engine

**Purpose**: Prevent non-consented cookies from loading

**Functionality**:
- Intercepts cookie-setting scripts before execution
- Blocks based on consent state:
  - **Before consent**: Block all except "Necessary"
  - **After consent**: Block based on user's category choices
- Techniques:
  - Script tag modification (`<script type="text/plain" data-category="statistics">`)
  - Cookie override (wrap `document.cookie` API)
  - localStorage/sessionStorage blocking
- Automatic unblocking once consent given
- Fires custom events for tag managers: `monacocookie_consent_given`

**Technical Implementation**:
```javascript
// Customer adds data-category to scripts
<script data-category="marketing" src="facebook-pixel.js"></script>

// MonacoCookie widget:
// 1. Prevents execution until consent
// 2. Changes type to "text/javascript" once consented
// 3. Manually executes script
```

**MVP Simplifications**:
- Manual script tagging required (customer adds `data-category` attribute)
- No automatic script detection (Phase 2 feature)
- Basic iframe blocking only

### 5.4 Consent Recording & Storage

**Purpose**: Maintain audit-ready logs of all consent actions (APDP compliance)

**Database Schema**:
```ruby
# Table: consents
- id (uuid)
- customer_id (foreign key)
- website_id (foreign key)
- visitor_id (anonymous hash)
- consent_given_at (timestamp)
- ip_address (hashed for privacy)
- user_agent (browser info)
- consent_choices (jsonb):
  {
    necessary: true,
    preferences: true,
    statistics: false,
    marketing: false
  }
- consent_method (enum: banner_accept_all, banner_reject_all, banner_customize)
- consent_version (integer, increments on policy change)
- withdrawn_at (timestamp, nullable)

# Retention: 12 months + 30 days (Monaco standard)
```

**API Endpoint**:
```
POST /api/v1/consent
Authorization: Bearer {customer_api_key}
Body: {
  visitor_id: "hash123",
  consent_choices: {...},
  timestamp: "2025-10-07T10:30:00Z"
}
```

**Compliance Features**:
- Consent proof per Article 6 requirements
- Anonymous visitor tracking (no PII)
- IP address hashed (PBKDF2)
- Audit log immutable (append-only)
- Export to CSV for APDP audits

### 5.5 Admin Dashboard

**Purpose**: Customer portal for managing cookie consent

**Core Pages**:

#### A. Overview/Dashboard
- Consent rate trend (last 30 days)
- Total consents this month
- Cookie categories breakdown (pie chart)
- Recent consent log (last 10)
- Scan status (last scan date, next scan date)

#### B. Cookie Management
- List of all detected cookies (table)
  - Name, Domain, Category, Description
  - Edit button (change category, add description)
  - Active/Inactive toggle
- "Scan Now" button (triggers manual scan)
- Add cookie manually (form)

#### C. Banner Configuration
- Live preview (iframe showing banner)
- Template selection (3 options)
- Customization form:
  - Brand color (color picker)
  - Logo upload
  - Privacy policy URL
  - Position (bottom/top/modal)
  - Custom intro text
- Language toggle (French/English preview)
- "Save & Publish" button

#### D. Installation
- Script tag (copy to clipboard):
  ```html
  <script src="https://cdn.monacocookie.mc/widget.js"
          data-site-id="{customer_id}" async></script>
  ```
- Installation guide:
  - WordPress instructions
  - Wix instructions
  - HTML/generic instructions
  - Verification check (ping back when widget loaded)

#### E. Consent Logs
- Filterable table:
  - Date/time
  - Visitor ID (anonymized)
  - Choices (icons for each category)
  - Method (Accept All / Reject All / Customize)
- Export to CSV button (for APDP audits)
- Date range filter
- Search by visitor ID

#### F. Analytics
- Consent rate over time (line chart)
- Category acceptance rates (bar chart)
- Consent method breakdown (Accept All vs Customize vs Reject)
- Geographic breakdown (if available from IP, optional)
- Time to consent (average seconds)

#### G. Account Settings
- Company info (name, address, SIREN)
- Billing info (credit card, invoices)
- Website management (add/remove domains)
- API key (show/regenerate)
- User management (team members, roles - Phase 2)

**Access Control** (MVP):
- Single user account per customer
- No multi-user (Phase 2 feature)
- Email/password login (Devise)
- 2FA optional (Devise Two Factor)

### 5.6 Customer Onboarding Flow

**Purpose**: Get customers to first consent in <15 minutes

**Steps**:
1. **Sign up** (email, password, company name)
2. **Add website** (URL, auto-verify ownership via meta tag or DNS)
3. **Initial scan** (automatic, 1-2 minutes)
4. **Customize banner** (quick setup: logo + color + privacy policy URL)
5. **Install script** (copy/paste code snippet)
6. **Test banner** (live verification check)
7. **Go live!** (banner appears on website)

**Email Sequence**:
- Welcome email (login link)
- Day 1: "Complete your setup" (if script not installed)
- Day 3: "How to customize your banner"
- Day 7: "Understanding your consent data"
- Day 14: "Best practices for consent rates"

---

## 6. Monaco Law 1.565 Compliance Requirements

### 6.1 Article 6 Consent Requirements

**Law Text** (loi-rgpd-monaco.txt:122):
> "Lorsque le traitement est fondé sur le consentement de la personne concernée, le responsable du traitement est en mesure de démontrer que celle-ci a donné son consentement au traitement de données à caractère personnel la concernant au moyen d'un acte positif clair résultant d'une action libre, spécifique, éclairée et non équivoque."

**MonacoCookie Implementation**:
- ✅ **Libre (Free)**: No pre-checked boxes, equal prominence for Accept/Reject
- ✅ **Spécifique (Specific)**: Granular consent per cookie category
- ✅ **Éclairé (Informed)**: Clear description of each category, link to privacy policy
- ✅ **Univoque (Unambiguous)**: Requires explicit click (no implied consent)

**Law Text** (loi-rgpd-monaco.txt:126):
> "Il est aussi simple de retirer que de donner son consentement."

**MonacoCookie Implementation**:
- ✅ Small persistent footer icon to re-open banner
- ✅ One-click "Withdraw all consent" option
- ✅ Same interface for withdrawal as initial consent

### 6.2 Article 11 Transparency Requirements

**Law Text** (loi-rgpd-monaco.txt:182-214):
Information requirements when collecting data

**MonacoCookie Implementation**:
- Banner clearly states purpose of cookies
- Link to privacy policy (customer-provided)
- List of cookie categories with descriptions
- Data retention period shown (12 months)
- Right to withdraw consent prominently displayed

### 6.3 Minor Protection (Article 6, Line 124)

**Law Text**:
> "lorsque le mineur est âgé de moins de 15 ans, ce traitement n'est licite qu'en présence d'un consentement donné par le mineur concerné avec l'autorisation de la ou des personnes exerçant l'autorité parentale"

**MonacoCookie Implementation** (MVP):
- ⚠️ **Out of scope for MVP** - Age gate would require complex verification
- **Recommendation**: Customers must implement age verification separately if targeting minors
- **Documentation**: Provide guidance on minor consent in help docs

---

## 7. Non-Functional Requirements

### 7.1 Performance
- Widget load time: <200ms (P95)
- Widget size: <50KB gzipped
- No impact on customer website Lighthouse score
- Dashboard page load: <1s (P95)
- API response time: <200ms (P95)
- Cookie scan: <2 minutes per website

### 7.2 Security
- All traffic HTTPS only (HSTS enabled)
- API rate limiting (1000 req/hour per customer)
- XSS protection on widget
- CSRF tokens on all dashboard forms
- SQL injection prevention (Rails parameter binding)
- Consent logs encrypted at rest (PostgreSQL encryption)
- PII minimization (hash IP addresses, no names stored)

### 7.3 Reliability
- Uptime SLA: 99.5% (monthly)
- Automated backups (daily, 30-day retention)
- Widget CDN: 99.9% uptime (Cloudflare)
- Graceful degradation (if API down, widget shows cached config)

### 7.4 Scalability
- Support 1,000 customers (Phase 1 target)
- Handle 10M consent events/month
- Handle 1,000 concurrent widget loads
- Database partitioning by customer (future-proof)

### 7.5 Accessibility
- WCAG 2.1 AA compliant
- Keyboard navigation (banner fully accessible)
- Screen reader compatible
- High contrast mode support

### 7.6 Browser Support
- Chrome (last 2 versions)
- Firefox (last 2 versions)
- Safari (last 2 versions)
- Edge (last 2 versions)
- Mobile browsers (iOS Safari, Chrome Mobile)
- IE11 (basic functionality only)

---

## 8. User Roles & Permissions

### MVP Roles
1. **Customer** (single user per account)
   - Full access to their own dashboard
   - Can modify banner, view logs, manage cookies
   - Cannot access other customers' data

2. **Admin** (MonacoCookie staff)
   - Access to all customer accounts (read-only for audit)
   - Can manually trigger scans
   - Can view system logs
   - Billing management

### Phase 2 Roles
- Team member (invited by customer)
- Read-only analyst
- Developer (API-only access)

---

## 9. Pricing & Business Model

### Subscription Tiers (Monthly)

**Starter** - €49/month
- 1 website
- 50,000 consents/month
- Monthly cookie scanning
- Email support
- 12-month consent storage
- Target: Solo entrepreneurs, small Monaco businesses

**Professional** - €99/month
- 5 websites
- 200,000 consents/month
- Weekly cookie scanning
- Priority email support
- 24-month consent storage
- Custom banner CSS (Phase 2)
- Target: Monaco SMEs with multiple properties

**Enterprise** - €249/month
- Unlimited websites
- Unlimited consents
- Daily cookie scanning
- Phone + email support
- Unlimited consent storage
- API access
- White-label option (Phase 2)
- Dedicated account manager
- Target: Larger Monaco businesses, agencies

### Add-ons
- Extra website: €20/month
- Custom integrations: €500 one-time
- Professional services (implementation): €150/hour

### Free Trial
- 14-day trial (no credit card required)
- Full Professional tier access
- 1,000 consents limit during trial
- Converts to Starter plan if no upgrade

---

## 10. Go-to-Market Strategy

### Target Segments
1. **Primary**: Monaco SMEs (10-50 employees) with existing websites
2. **Secondary**: Web agencies managing Monaco client websites
3. **Tertiary**: Monaco e-commerce businesses (high cookie usage)

### Marketing Channels
1. **APDP Partnership**: Get listed on APDP recommended tools page
2. **Content Marketing**: Monaco GDPR compliance blog (French)
3. **Local Partnerships**: Monaco Chamber of Commerce, JCE Monaco
4. **Direct Outreach**: LinkedIn targeting Monaco marketing managers
5. **Referral Program**: 20% commission for agencies

### Launch Plan (Month 1)
- Week 1-2: Beta testing with 5 friendly customers (free)
- Week 3: Official launch, APDP announcement
- Week 4: Press release (Monaco Matin, Monaco Tribune)

### Sales Process
1. **Lead Gen**: Website scanner tool (free, no signup)
   - Enter website URL → see non-compliant cookies
   - CTA: "Fix this in 15 minutes with MonacoCookie"
2. **Trial Signup**: 14-day free trial
3. **Onboarding Email**: 5-email sequence
4. **Conversion**: Auto-convert to Starter unless upgraded

---

## 11. Development Roadmap

### Phase 1: MVP (Months 1-3)
**Goal**: Launch with 10 paying customers

**Month 1: Core Infrastructure**
- Week 1-2: Rails app setup, database schema, customer authentication
- Week 3-4: Cookie scanning engine (Puppeteer integration)

**Month 2: Widget & Dashboard**
- Week 1-2: Consent banner widget (vanilla JS)
- Week 3-4: Admin dashboard (Hotwire)

**Month 3: Polish & Launch**
- Week 1: Consent recording API, analytics
- Week 2: Billing integration (Stripe), invoicing
- Week 3: Beta testing, bug fixes
- Week 4: Public launch

**Deliverables**:
- ✅ Functional cookie scanning
- ✅ Monaco Law 1.565 compliant banner
- ✅ Cookie blocking engine
- ✅ Consent logs & analytics
- ✅ Admin dashboard
- ✅ Payment processing
- ✅ 10 paying customers

### Phase 2: Enhanced Features (Months 4-6)
**Goal**: Scale to 50 customers, €4,000 MRR

**New Features**:
- Multi-user accounts (team collaboration)
- Advanced cookie scanning (deep crawl, multiple pages)
- Custom banner CSS editor
- Integration with Google Tag Manager
- WordPress plugin (one-click install)
- Multi-language support (Italian, English)
- Geo-targeting (different banners by country)
- A/B testing (banner optimization)

**Deliverables**:
- 50 paying customers
- €4,000 MRR
- WordPress plugin published
- Google Tag Manager integration

### Phase 3: Scale & Differentiation (Months 7-12)
**Goal**: 200 customers, €15,000 MRR, expand beyond Monaco

**New Features**:
- Monaco GDPR Certification Badge (partner with APDP)
- Automatic legal text generation
- Integration with broader MonacoGDPR platform
- API for custom integrations
- Shopify app
- EU market expansion (French-speaking: France, Belgium, Switzerland)

---

## 12. Success Metrics & KPIs

### Product Metrics
- **Activation Rate**: % of signups who install widget (Target: >60%)
- **Time to First Consent**: Minutes from signup to first consent recorded (Target: <30 min)
- **Widget Load Time**: P95 load time (Target: <200ms)
- **Consent Rate**: % of visitors who accept cookies (Target: >40%)
- **Scan Accuracy**: % of cookies correctly categorized (Target: >95%)

### Business Metrics
- **Customer Acquisition**: New paying customers/month (Month 3: 10, Month 12: 200)
- **MRR**: Monthly recurring revenue (Month 3: €500, Month 12: €15,000)
- **Churn Rate**: % monthly customer churn (Target: <5%)
- **CAC**: Customer acquisition cost (Target: <€100)
- **LTV:CAC Ratio**: Lifetime value to CAC (Target: >3:1)
- **Trial → Paid Conversion**: % trials converting to paid (Target: >25%)

### Compliance Metrics
- **APDP Violations**: Zero tolerance
- **Consent Proof Availability**: 100% of consents auditable
- **Uptime**: 99.5% monthly uptime

---

## 13. Risks & Mitigations

### Risk 1: APDP Non-Recognition
**Description**: APDP doesn't recognize MonacoCookie as compliant solution
**Impact**: High (customers lose trust)
**Mitigation**:
- Engage APDP legal counsel during development
- Get formal approval before launch
- Publish compliance certification

### Risk 2: Low Adoption (Chicken & Egg)
**Description**: Monaco market too small for standalone cookie product
**Impact**: High (can't reach revenue targets)
**Mitigation**:
- Bundle with broader MonacoGDPR platform (existing PRD)
- Expand to France/Belgium early if Monaco traction low
- Offer free tier for micro-businesses

### Risk 3: Cookie Scanning Inaccuracy
**Description**: Automated categorization makes mistakes
**Impact**: Medium (incorrect cookie blocking)
**Mitigation**:
- Manual override in dashboard (always available)
- Seed database with 500+ known cookies
- Customer feedback loop (report incorrect category)

### Risk 4: Browser Blocking (Ad Blockers)
**Description**: Ad blockers prevent widget from loading
**Impact**: Medium (consents not recorded)
**Mitigation**:
- Use generic CDN domain (not "cookie" or "tracker")
- Fallback to first-party hosting option
- Educate customers on domain choice

### Risk 5: Competition from Cookiebot
**Description**: Cookiebot adds Monaco-specific compliance mode
**Impact**: Medium (lose differentiation)
**Mitigation**:
- Double down on Monaco-native positioning (French, APDP partnership)
- Price aggressively (50% below Cookiebot)
- Bundle with broader MonacoGDPR platform

---

## 14. Out of Scope (MVP)

The following features are explicitly **NOT** included in MVP:

### Features for Phase 2+
- Google Consent Mode integration
- Multi-language support (>2 languages)
- Deep crawling (multi-page scanning)
- Automatic script detection & blocking
- A/B testing for banners
- Custom CSS editor
- Team collaboration / multi-user
- API access for customers
- White-label / agency reseller program
- Mobile app for dashboard
- Compliance certificate / badge

### Features NOT Planned
- Video surveillance compliance (different product)
- General GDPR compliance (see main MonacoGDPR PRD)
- Employee data compliance
- Data breach notification
- DPIA workflows
- Vendor risk management

---

## 15. Dependencies & Integrations

### Required External Services
1. **Stripe** (payment processing)
   - Subscription billing
   - Invoice generation
   - PCI compliance

2. **Cloudflare** (CDN & security)
   - Widget delivery
   - DDoS protection
   - SSL certificates

3. **AWS S3** (file storage)
   - Customer logos
   - Export files (CSV consent logs)

4. **Postmark** (transactional email)
   - Account emails
   - Onboarding sequences
   - Invoices

5. **Sentry** (error tracking)
   - Backend error monitoring
   - Widget error tracking (JS errors)

### Optional Integrations (Phase 2)
- Google Tag Manager
- WordPress
- Shopify
- Wix
- Webflow

---

## 16. Legal & Regulatory Considerations

### Data Residency
- All data stored in Monaco or France (OVH Monaco datacenter preferred)
- Backup replication within EU only
- No data transfer to US without SCCs (Standard Contractual Clauses)

### APDP Compliance
- MonacoCookie platform itself subject to Law 1.565
- DPA (Data Processing Agreement) with customers (we are processor)
- APDP notification if breach (72 hours per Article 32)
- Data retention: 12 months + 30 days (then automatic deletion)

### Terms of Service
- Customer is data controller (for consent data)
- MonacoCookie is data processor
- Customer indemnifies MonacoCookie for their privacy policy accuracy
- MonacoCookie provides "tool" not "legal advice"

### Privacy Policy
- MonacoCookie's own privacy policy (for customer data)
- French + English versions required
- Visible link in footer of all pages

---

## 17. Documentation Requirements

### Customer-Facing Docs
1. **Quick Start Guide** (5 min read)
   - Sign up → Install → Customize → Go live
2. **Installation Guides**
   - WordPress (with screenshots)
   - Wix
   - Shopify
   - Generic HTML/JavaScript
3. **Monaco Law 1.565 Compliance Guide**
   - Article 6 requirements explained
   - How MonacoCookie ensures compliance
   - Best practices for privacy policies
4. **API Documentation** (Phase 2)
   - Authentication
   - Endpoints
   - Rate limits
   - Examples

### Internal Docs
1. **Development Setup** (README)
   - Local environment setup
   - Running tests
   - Deployment process
2. **Architecture Overview**
   - System diagram
   - Database schema
   - API design
3. **Runbook**
   - Incident response
   - Customer support procedures
   - Scaling procedures

---

## 18. Open Questions

1. **APDP Partnership**: Will APDP officially endorse MonacoCookie? (Answer: Engage legal counsel Month 1)

2. **Cookie Database Seeding**: Can we license an existing cookie database (e.g., Cookiebot's) or must we build from scratch? (Answer: Research Month 1)

3. **Minors' Consent**: Should MVP include age gate for <15 years? (Current: Out of scope, document as customer responsibility)

4. **Monaco-Only or France Launch?**: Should we expand to France immediately or prove Monaco first? (Current: Monaco-first, expand Month 9+)

5. **Pricing Strategy**: €49/month competitive enough vs Cookiebot's €59? (Answer: Test with beta customers Month 2)

---

## 19. Appendices

### Appendix A: Monaco Law 1.565 Article References

**Article 2, Line 18** - Definition of consent:
> "consentement de la personne concernée : toute manifestation de volonté, libre, spécifique, éclairée et univoque par laquelle la personne concernée accepte, par une déclaration ou par un acte positif clair, que des données à caractère personnel la concernant fassent l'objet d'un traitement"

**Article 5** - Legal bases for processing (consent is first option)

**Article 6** - Consent requirements and proof obligations

**Article 11** - Transparency and information requirements

**Article 12** - Right of access (consent logs must be accessible)

**Article 14** - Right to erasure (when consent withdrawn)

### Appendix B: Competitive Landscape

| Feature | MonacoCookie (MVP) | Cookiebot | OneTrust | Axeptio |
|---------|-------------------|-----------|----------|---------|
| **Pricing** | €49/month | €59/month | €200+/month | €39/month |
| **Monaco Law 1.565** | ✅ Native | ❌ Generic EU GDPR | ❌ Generic | ❌ Generic |
| **French Language** | ✅ Primary | ✅ Supported | ✅ Supported | ✅ Primary |
| **Cookie Scanning** | ✅ Monthly | ✅ Monthly | ✅ Weekly | ✅ Monthly |
| **Consent Storage** | ✅ 12 months | ✅ 12 months | ✅ Unlimited | ✅ 12 months |
| **APDP Certified** | 🎯 Goal | ❌ No | ❌ No | ❌ No |
| **Local Support** | ✅ Monaco | ❌ Denmark | ❌ US | 🇫🇷 France |
| **Implementation** | <15 min | ~30 min | ~2 hours | ~20 min |

**Key Differentiators**:
1. **Monaco-native**: Only solution built specifically for Law 1.565
2. **APDP partnership**: Official recognition (goal)
3. **Price**: 20% cheaper than Cookiebot
4. **Local support**: French-speaking team in Monaco
5. **Bundle option**: Part of broader MonacoGDPR compliance platform

### Appendix C: User Stories

**As a Monaco business owner, I want to...**
1. Quickly install a cookie consent banner so I comply with Law 1.565 before the APDP deadline
2. Automatically detect all cookies on my website so I don't miss any tracking technologies
3. Prove consent to the APDP during an audit so I avoid fines
4. Customize the banner colors to match my brand so it looks professional
5. Understand my consent rates so I can optimize my cookie usage

**As a website visitor in Monaco, I want to...**
1. Clearly understand what cookies are used so I can make an informed choice
2. Easily reject all cookies if I don't want tracking so I maintain my privacy
3. Choose which cookie categories I accept so I have granular control
4. Withdraw my consent at any time so I can change my mind

**As a web agency managing Monaco clients, I want to...**
1. Manage multiple client websites from one dashboard so I save time
2. White-label the solution so I can resell under my brand (Phase 2)
3. Get alerted when clients' cookies change so I can update consent banners
4. Access API to automate setup for new clients (Phase 2)

---

## 20. Approval & Sign-off

**Document Owner**: Laurent Curau
**Stakeholders**: [To be defined]
**Approval Date**: [Pending]
**Next Review**: Month 3 (post-MVP launch)

---

**END OF DOCUMENT**
