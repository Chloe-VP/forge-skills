---
name: seo-auditor
description: "Run SEO audits, keyword research, content gap analysis, and competitor mapping for any website or niche. Use when: analyzing a site's SEO health, planning content strategy, researching keywords, auditing technical SEO, comparing against competitors, or planning Google Ads keywords. NOT for: running actual Google Ads campaigns, making live site changes, or detailed analytics reporting."
metadata: { "openclaw": { "emoji": "🔍", "requires": { "tools": ["web_search", "web_fetch"] } } }
---

# SEO Auditor

Comprehensive SEO analysis using web_search and web_fetch — keyword research, technical audits, content gaps, and competitor intelligence.

## When to Use

✅ **USE this skill when:**

- Auditing a website's SEO health
- Researching keywords for a niche or business
- Planning content strategy based on search demand
- Comparing SEO positioning against competitors
- Identifying content gaps and opportunities
- Planning Google Ads keyword targets
- User says "audit my site" or "what keywords should I target"

❌ **DON'T use this skill when:**

- Running or managing actual Google Ads campaigns
- Making live changes to a website
- Detailed analytics reporting (need Google Analytics access)
- Social media strategy (different signals)

## Capabilities

| Mode | What It Does | Best For |
|------|-------------|----------|
| **Site Audit** | Technical SEO health check on a target URL | Existing sites needing fixes |
| **Keyword Research** | Find high-value keywords for a niche | New content planning |
| **Content Gap** | Topics competitors rank for that you don't | Competitive catch-up |
| **Competitor Map** | Analyze competitor SEO strategy | Strategic positioning |
| **Full Report** | All of the above in one deliverable | Comprehensive planning |

## Mode 1: Site Audit

Fetch the target URL with `web_fetch` and analyze:

### On-Page SEO Checks

```text
Title tag:
- Present? Length 50-60 chars? Primary keyword included?
- Example: ✅ "AI Answering Service for Small Business | Second Ring" (53 chars)
- Example: ❌ "Home" (4 chars, no keywords)

Meta description:
- Present? Length 150-160 chars? Compelling CTA?
- Example: ✅ "24/7 AI answering service for plumbers, HVAC & more. Never miss a call. $297/mo." (80 chars, could be longer but has keywords + CTA)
- Example: ❌ "" (missing entirely)
```

```text
Heading structure:
- Single H1? Keyword in H1?
- Logical H2/H3 hierarchy?
- Example: ✅ H1 → H2 → H3 (proper nesting)
- Example: ❌ H1 → H4 → H2 (broken hierarchy)
```

### Technical SEO Checks

```text
URL structure:
- Clean, descriptive slugs: ✅ /pricing  ❌ /page?id=123&ref=abc
- Canonical tag present and correct?
- Robots meta: indexable?

Mobile signals:
- Viewport meta tag present?
- Responsive design indicators?

Schema/structured data:
- LocalBusiness, Product, FAQ, or other relevant schema?
```

### Content Quality Checks

```text
Content scoring:
- Word count: <300 = thin content flag
- Keyword usage: natural integration vs stuffing
- Readability: short paragraphs, scannable headers
- Freshness: dates, update indicators
```

### Output Format

```markdown
## Site Audit: [url]

### Score: [X/10]

| Category | Score | Status |
|----------|-------|--------|
| On-Page SEO | X/10 | 🟢/🟡/🔴 |
| Technical SEO | X/10 | 🟢/🟡/🔴 |
| Content Quality | X/10 | 🟢/🟡/🔴 |

### Critical Issues (fix immediately)
1. [issue + fix]

### Warnings (fix soon)
1. [issue + fix]

### Passed
1. [what's working well]
```

## Mode 2: Keyword Research

Given a niche or seed keywords:

### Step 1 — Search Expansion

```bash
# Use web_search to explore the niche
web_search("best [niche] services")
web_search("[niche] near me")
web_search("how to choose [niche]")
web_search("[niche] vs [alternative]")
web_search("[niche] reviews")
```

### Step 2 — Competitor Mining

```bash
# Find what competitors target
web_search("site:competitor1.com [niche]")
web_search("site:competitor2.com [niche]")
# Extract title tags and H1s from top pages
web_fetch("competitor1.com/services")
```

### Step 3 — Intent Classification

```text
Group keywords by search intent:

Informational (top of funnel):
- "how to fix leaky faucet" → Blog post / guide
- "signs you need a new HVAC system" → Educational content

Commercial (middle of funnel):
- "best plumber near me" → Service page + reviews
- "AI answering service comparison" → Comparison page

Transactional (bottom of funnel):
- "emergency plumber Portland" → Landing page + CTA
- "hire HVAC technician today" → Booking page

Navigational (branded):
- "Second Ring pricing" → Pricing page
- "Roto-Rooter phone number" → (competitor brand, hard to rank)
```

### Step 4 — Difficulty Estimation

```text
Check top 10 results for each keyword:
- All major brands (Yelp, HomeAdvisor, Angi)? → HIGH difficulty
- Mix of brands + local businesses? → MEDIUM difficulty
- Mostly small sites, forums, thin content? → LOW difficulty
```

### Step 5 — Output Keyword Table

```markdown
| Keyword | Intent | Difficulty | Priority | Content Type |
|---------|--------|-----------|----------|-------------|
| emergency plumber portland | Transactional | Low | ⭐⭐⭐ | Landing page |
| best plumber near me | Commercial | Medium | ⭐⭐⭐ | Service page |
| how to fix leaky faucet | Informational | Low | ⭐⭐ | Blog post |
| plumber vs handyman | Commercial | Low | ⭐⭐ | Comparison |
| roto-rooter reviews | Navigational | High | ⭐ | Skip |
```

## Mode 3: Content Gap Analysis

Compare target site vs 2-3 competitors:

### Process

```bash
# Step 1: Map your content
web_fetch("[your-site]/sitemap.xml")  # or crawl main nav
# Catalog: what topics do you cover?

# Step 2: Map competitor content
web_fetch("[competitor]/sitemap.xml")
web_fetch("[competitor]/blog")
# Catalog: what topics do they cover?

# Step 3: Diff
# Topics they have that you don't = gaps
# Topics you have that they don't = advantages
```

### Output Format

```markdown
## Content Gap Report: [your site] vs [competitors]

### Gaps (they rank, you don't)
| Topic | Competitor | Their URL | Priority |
|-------|-----------|-----------|----------|
| [topic] | [who] | [url] | High/Med/Low |

### Advantages (you rank, they don't)
| Topic | Your URL | Protect? |
|-------|----------|----------|

### Suggested Content Plan
1. [Highest priority gap] → [content type + target keyword]
2. ...
```

## Mode 4: Competitor Map

For each competitor URL:

```text
Analyze per competitor:
1. SEO strengths: What do they rank well for?
2. Content strategy: Blog frequency? Topic clusters? Content types?
3. Backlink indicators: Who links to them in search results?
4. Keyword positioning: Head terms vs long tail?
5. Weaknesses: Thin content? Missing topics? Technical issues?
```

### Output Format

```markdown
## Competitor: [name] ([url])

**SEO Strength**: [Strong/Medium/Weak]
**Content Volume**: ~[N] indexed pages
**Strategy**: [description]

### What they do well
- [strength 1]

### Where they're vulnerable
- [weakness 1]

### Keywords to steal
| Keyword | Their rank position | Our opportunity |
|---------|-------------------|-----------------|
```

## Mode 5: Full Report

Run all modes sequentially. Combine into:

```markdown
# SEO Audit Report: [site]
Generated: [date]

## Executive Summary
- [3-5 bullet key findings]
- Overall SEO health: [score/10]

## 1. Technical Health
[Site Audit output]

## 2. Keyword Opportunities
[Top 15 keywords table]

## 3. Content Gaps
[Top 10 missing topics with content recommendations]

## 4. Competitive Position
[Per-competitor analysis]

## 5. Action Plan (Priority Order)
| # | Action | Effort | Impact | Timeline |
|---|--------|--------|--------|----------|
| 1 | [Quick win] | Low | High | This week |
| 2 | [Medium effort] | Med | High | This month |
| 3 | [Strategic play] | High | High | This quarter |
```

## Tips

- **Start with Site Audit** if you have an existing site — fix technical issues before chasing keywords.
- **Start with Keyword Research** if you're planning a new site or content strategy.
- **3 competitors is ideal** for gap analysis — more adds noise without insight.
- **Local businesses**: Always include location-modified keywords ("plumber Portland" not just "plumber").
- **Pair with Google Ads**: Keywords flagged as high commercial/transactional intent are strong ad candidates.
- **Check monthly**: SEO is not set-and-forget. Re-audit quarterly at minimum.
- **Don't chase vanity keywords**: "marketing" has huge volume but zero conversion intent. Prefer specific long-tail terms.
- **Content quality > quantity**: One thorough 2000-word guide outranks ten 300-word thin posts.
