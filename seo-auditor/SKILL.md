---
name: seo-auditor
description: "Run SEO audits, keyword research, content gap analysis, and competitor mapping for any website or niche. Use when: analyzing a site's SEO health, planning content strategy, researching keywords, auditing technical SEO, comparing against competitors, or planning Google Ads keywords. NOT for: running actual Google Ads campaigns, making live site changes, or detailed analytics reporting."
metadata: { "openclaw": { "emoji": "🔍", "requires": { "tools": ["web_search", "web_fetch"] } } }
---

# SEO Auditor

Comprehensive SEO analysis using web_search and web_fetch — keyword research, technical audits, content gaps, and competitor intelligence.

## Capabilities

| Mode | What It Does |
|------|-------------|
| **Site Audit** | Technical SEO health check on a target URL |
| **Keyword Research** | Find high-value keywords for a niche |
| **Content Gap** | Identify topics competitors rank for that you don't |
| **Competitor Map** | Analyze competitor SEO strategy and positioning |
| **Full Report** | All of the above in one structured deliverable |

## How to Use

User provides one or more of:
- A website URL to audit
- A business niche/category
- Competitor URLs
- Target keywords they care about

### Mode 1: Site Audit

Fetch the target URL with `web_fetch` and analyze:

**On-Page SEO**
- Title tag: present, length (50-60 chars), keyword inclusion
- Meta description: present, length (150-160 chars), compelling
- H1/H2 structure: proper hierarchy, keyword usage
- Internal linking: depth, orphan pages
- Image alt text: present, descriptive

**Technical SEO**
- URL structure: clean, descriptive, no parameter soup
- Mobile indicators: viewport meta, responsive signals
- Schema markup: presence of structured data
- Canonical tags: present, correct
- Robots directives: indexability

**Content Quality**
- Word count: thin content flags (<300 words)
- Keyword density: natural usage vs stuffing
- Readability: sentence length, jargon level
- Freshness signals: dates, update indicators

Output a scored report (Critical / Warning / Good) with prioritized fixes.

### Mode 2: Keyword Research

Given a niche or seed keywords:

1. **Search expansion**: Use `web_search` for seed terms, extract related queries from results
2. **Competitor mining**: Search `site:competitor.com` + niche terms, catalog their keyword targets
3. **Intent classification**: Group keywords by intent:
   - Informational ("how to fix leaky faucet")
   - Commercial ("best plumber near me")
   - Transactional ("emergency plumber Portland")
   - Navigational ("Roto-Rooter phone number")
4. **Difficulty estimation**: Check top 10 results — are they major brands or beatable?
5. **Opportunity scoring**: High intent + low difficulty = priority targets

Output a keyword table: keyword, estimated intent, difficulty (Low/Med/High), priority, suggested content type.

### Mode 3: Content Gap Analysis

Compare target site vs 2-3 competitors:

1. Fetch sitemap or crawl main pages of each site
2. Catalog topic coverage by site
3. Identify topics competitors cover that target doesn't
4. Rank gaps by search volume indicators and business relevance
5. Suggest content pieces to fill top gaps

### Mode 4: Competitor Map

For each competitor URL:

1. Analyze their SEO strengths (what they rank for)
2. Identify their content strategy (blog frequency, topic clusters)
3. Check their backlink indicators (who links to them from search results)
4. Map their keyword positioning vs yours
5. Find weaknesses to exploit

### Mode 5: Full Report

Run all modes sequentially. Output a structured report:

```
# SEO Audit Report: [site]
Generated: [date]

## Executive Summary
[3-5 bullet findings]

## Technical Health: [score/10]
[findings]

## Keyword Opportunities
[top 15 keywords table]

## Content Gaps
[top 10 missing topics]

## Competitive Position
[vs each competitor]

## Action Plan (Priority Order)
1. [Quick win]
2. [Medium effort]
3. [Strategic play]
```

## Tips

- **Start with Site Audit** if you have an existing site — fix technical issues before chasing keywords.
- **Start with Keyword Research** if you're planning a new site or content strategy.
- **3 competitors is ideal** for gap analysis — more adds noise without insight.
- **Local businesses**: Always include location-modified keywords ("plumber Portland" not just "plumber").
- **Pair with Google Ads planning**: Keywords flagged as high commercial intent are strong ad candidates.
