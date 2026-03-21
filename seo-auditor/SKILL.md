---
name: seo-auditor
description: "Run SEO audits, keyword research, content gap analysis, and competitor mapping for any website or niche. Use when: analyzing a site's SEO health, planning content strategy, researching keywords, auditing technical SEO, comparing against competitors, or planning Google Ads keywords. NOT for: running actual Google Ads campaigns, making live site changes, or detailed analytics reporting."
tools: ["web_search", "web_fetch"]
metadata: { "openclaw": { "emoji": "🔍", "requires": { "tools": ["web_search", "web_fetch"] } } }
---

# SEO Auditor

Comprehensive SEO analysis using `web_search` and `web_fetch` — keyword research, technical audits, content gaps, and competitor intelligence.

> ⚠️ **Data Source Disclaimer:** This skill analyzes publicly visible HTML elements and search result snippets. All scores are **heuristic indicators** based on element presence/absence and SERP composition — they are NOT equivalent to scores from Ahrefs, Moz, SEMrush, or Google Search Console. Treat outputs as a structured checklist and signal map, not an SEO platform rating. For decisions that affect ad spend, validate findings against Google Search Console or a paid SEO tool.

## When to Use

✅ **USE this skill when:**

- Auditing a website's SEO health (on-page, technical, content quality)
- Researching keywords for a niche or business
- Planning content strategy based on search demand signals
- Comparing SEO positioning against competitors
- Identifying content gaps and opportunities
- Planning Google Ads keyword targets
- User says "audit my site" or "what keywords should I target"

❌ **DON'T use this skill when:**

- Running or managing actual Google Ads campaigns
- Making live changes to a website
- Detailed analytics reporting (needs Google Analytics / Search Console access)
- Social media strategy (different signals)
- You need exact search volume numbers (requires keyword data API — see Upgrade Paths)

## Capabilities

| Mode | What It Does | Best For | Query Budget |
|------|-------------|----------|-------------|
| **Site Audit** | Technical SEO health check on a target URL | Existing sites needing fixes | ~5-8 queries |
| **Keyword Research** | Find high-value keywords for a niche (minimum 10 keywords) | New content planning | ~10-15 queries |
| **Content Gap** | Topics competitors rank for that you don't (minimum 5 gaps) | Competitive catch-up | ~8-12 queries |
| **Competitor Map** | Analyze competitor SEO strategy (5 competitors) | Strategic positioning | ~8-12 queries |
| **Full Report** | All of the above in one deliverable | Comprehensive planning | ~35-45 queries |

## Workflow

Choose the mode that matches your goal, then follow the numbered steps within that mode. For comprehensive analysis, run Mode 5 (Full Report) which executes all modes in sequence.

- **Have an existing site?** → Start with Mode 1 (Site Audit)
- **Planning new content?** → Start with Mode 2 (Keyword Research)
- **Want the full picture?** → Run Mode 5 (Full Report)

## Mode 1: Site Audit

Fetch the target URL with `web_fetch` and analyze. Score each category on a **X/10 scale** (heuristic — see methodology below each score).

### Step 1 — Fetch the Page

```bash
# Fetch the target URL
web_fetch("[target-url]")

# If blocked (403/429/timeout), fall back:
web_search("site:[domain]")
# Use snippet data for surface-level analysis and flag as partial
```

### Step 2 — On-Page SEO Checks

```text
Title tag:
- Present? Length 50-60 chars? Primary keyword included?
- Example: ✅ "AI Answering Service for Small Business | Second Ring" (53 chars)
- Example: ❌ "Home" (4 chars, no keywords)
- Scoring: +3 present, +2 right length, +2 keyword included, +3 compelling/unique

Meta description:
- Present? Length 150-160 chars? Compelling CTA?
- Example: ✅ "24/7 AI answering service for plumbers, HVAC & more. Never miss a call. $297/mo." (80 chars, keywords + CTA)
- Example: ❌ "" (missing entirely)
- Scoring: +3 present, +2 right length, +3 keyword + CTA, +2 unique per page
```

```text
Heading structure:
- Single H1? Keyword in H1?
- Logical H2/H3 hierarchy?
- Example: ✅ H1 → H2 → H3 (proper nesting)
- Example: ❌ H1 → H4 → H2 (broken hierarchy)
- Scoring: +4 single H1 with keyword, +3 proper hierarchy, +3 descriptive subheadings
```

### Step 3 — Technical SEO Checks

```text
HTTPS/Security:
- URL begins with https://? (check the target URL itself)
- HTTP → HTTPS redirect functional? (inferred if http:// fetch redirects)
- Scoring: +5 HTTPS present, +3 redirect in place

URL structure:
- Clean, descriptive slugs: ✅ /pricing  ❌ /page?id=123&ref=abc
- Canonical tag present and correct?
- Robots meta: indexable?
- Scoring: +3 clean URLs, +3 canonical present, +2 robots OK, +2 no redirect chains

Mobile signals:
- Viewport meta tag present?
- Responsive design indicators?
- Scoring: +5 viewport meta, +5 responsive indicators

Schema/structured data:
- LocalBusiness, Product, FAQ, or other relevant schema?
- Scoring: +5 schema present, +5 correct and relevant type
```

### Step 4 — Content Quality Checks

```text
Content scoring:
- Word count: <300 = thin content flag, 300-1000 = adequate, 1000+ = strong
- Keyword usage: natural integration vs stuffing
- Readability: short paragraphs, scannable headers
- Freshness: dates, update indicators
- Scoring: +3 adequate length, +3 natural keywords, +2 readable structure, +2 freshness

Internal linking:
- Count anchor tags pointing to same domain (href="/" or href="https://[domain]/...")
- <3 internal links on a key page = thin internal linking flag
- Scoring: +3 adequate internal links (3+), +2 descriptive anchor text
```

### Output Format

```markdown
## Site Audit: [url]

### Overall Score: [X/10] (heuristic — based on HTML element analysis)

> Methodology: Scores reflect presence/absence and quality of HTML elements
> visible to web crawlers. They do not measure actual search rankings,
> traffic, or Core Web Vitals. Use Google Search Console for authoritative data.

| Category | Score | Status | Methodology |
|----------|-------|--------|-------------|
| On-Page SEO | X/10 | 🟢/🟡/🔴 | Title, meta, headings check |
| Technical SEO | X/10 | 🟢/🟡/🔴 | URL, canonical, schema check |
| Content Quality | X/10 | 🟢/🟡/🔴 | Word count, structure, freshness |

### Critical Issues (fix immediately)
1. [issue + specific recommended change + impact: SEO ranking / traffic / conversion]

### Warnings (fix soon)
1. [issue + specific recommended change + impact category]

### Passed
1. [what's working well]
```

**Minimum output:** At least 2 specific findings (pass or fail) per scored category — minimum 6 findings total. If a category has fewer than 2 checkable elements (unusual), note the limitation explicitly.

## Mode 2: Keyword Research

Given a niche or seed keywords, produce a **minimum of 10 keywords** with intent classification.

> **Data limitation:** Keyword difficulty is estimated from SERP composition (who ranks on page 1), not from actual search volume data. Use Google Keyword Planner or SEMrush for volume numbers before committing ad spend.

### Step 1 — Search Expansion (~5 queries)

```bash
# Use web_search to explore the niche
web_search("best [niche] services")
web_search("[niche] near me")
web_search("how to choose [niche]")
web_search("[niche] vs [alternative]")
web_search("[niche] reviews")
```

### Step 2 — Competitor Mining (~3-5 queries)

```bash
# Find what competitors target
web_search("site:competitor1.com [niche]")
web_search("site:competitor2.com [niche]")
# Extract title tags and H1s from top pages
web_fetch("https://[competitor-domain]/services")
```

### Step 3 — Intent Classification

Classify EVERY keyword into one of these categories:

```text
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

**Minimum requirement:** At least 3 keywords must be Commercial or Transactional intent (these drive conversions).

### Step 4 — Difficulty Estimation (from SERP composition)

```text
For each keyword, check top 10 results via web_search:
- All major brands/aggregators (Yelp, HomeAdvisor, Angi, Forbes)? → HIGH difficulty
- Mix of brands + local businesses? → MEDIUM difficulty
- Mostly small sites, forums, thin content? → LOW difficulty

This is RELATIVE difficulty, not absolute. It tells you where
small-site opportunities exist, not exact ranking probability.
```

### Step 5 — Output Keyword Table

```markdown
| Keyword | Intent | Difficulty | Priority | Content Type | Notes |
|---------|--------|-----------|----------|-------------|-------|
| emergency plumber portland | Transactional | Low | ⭐⭐⭐ | Landing page | Local + urgent = high conversion |
| best plumber near me | Commercial | Medium | ⭐⭐⭐ | Service page | High-value, competitive |
| how to fix leaky faucet | Informational | Low | ⭐⭐ | Blog post | Traffic builder, low conversion |
| plumber vs handyman | Commercial | Low | ⭐⭐ | Comparison | Decision-stage searcher |
| roto-rooter reviews | Navigational | High | ⭐ | Skip | Competitor branded term |

> Difficulty is estimated from SERP composition, not keyword volume data.
> Validate with Google Keyword Planner before committing ad budget.
```

**Minimum output:** 10 keywords. At least 3 Commercial/Transactional. All with intent classification. If fewer than 10 unique relevant keywords found across all queries, include a data-limitation note: *"Data limitation: only N relevant keywords found. Broaden seed keywords or niche definition for better coverage."* Do NOT pad with irrelevant terms.

## Mode 3: Content Gap Analysis

Compare target site vs **2-3 competitors**. Produce a **minimum of 5 content gaps**.

> **Data quality:** Gap detection depends on sitemap availability and page fetchability. If a competitor blocks web_fetch, analysis uses search snippet data and is flagged as partial.

### Process

```bash
# Step 1: Map your content (~2-3 queries)
web_fetch("[your-site]/sitemap.xml")  # or crawl main nav
# Catalog: what topics do you cover?

# Step 2: Map competitor content (~4-6 queries)
web_fetch("[competitor]/sitemap.xml")
web_fetch("[competitor]/blog")
# Catalog: what topics do they cover?
# If fetch is blocked (403/429), fall back to:
web_search("site:[competitor-domain]")
# Flag results as "(snippet only — full fetch blocked)"

# Step 3: Diff
# Topics they have that you don't = gaps
# Topics you have that they don't = advantages
```

### Output Format

```markdown
## Content Gap Report: [your site] vs [competitors]

### Gaps (they rank, you don't) — minimum 5
| Topic | Competitor(s) | Their URL | Recommended Content Type | Priority |
|-------|--------------|-----------|------------------------|----------|
| [topic] | [who — list all if multiple] | [url] | Blog / Landing / FAQ / Case Study | High/Med/Low |

### Advantages (you rank, they don't)
| Topic | Your URL | Protect? |
|-------|----------|----------|

### Suggested Content Plan
1. [Highest priority gap] → [content type + target keyword + expected impact]
2. ...

> Data source: Sitemap analysis + search snippet comparison.
> Competitors marked (snippet only) had blocked web_fetch — findings are surface-level.
```

**Minimum output:** 5 content gaps with competitor attribution. If fewer than 5 found, explain why and suggest broadening competitor set.

## Mode 4: Competitor Map

Identify **5 competitors** (or fewer with explicit note if <5 found). For each:

> **Methodology:** Competitor identification via search results for target keywords. Analysis based on publicly visible page content, titles, and meta — not traffic data or backlink databases.

### Process (~8-12 queries)

```bash
# Step 1: Find competitors
web_search("[target's primary keyword]")
web_search("[target's primary keyword] alternatives")
web_search("best [niche] services [location]")
# Extract top 5 distinct competing domains from results

# Step 2: Analyze each competitor
web_fetch("[competitor-domain]")
web_search("site:[competitor-domain]")
# Extract: title patterns, content themes, keyword signals
```

### Per-Competitor Analysis

```text
Analyze per competitor:
1. SEO strengths: What keywords appear in their titles/H1s?
2. Content strategy: Blog present? Topic clusters? Content types?
3. Backlink indicators: Who links to them in search results?
4. Keyword positioning: Head terms vs long tail?
5. Weaknesses: Thin content? Missing topics? Technical issues?
```

### Output Format

```markdown
## Competitor Map: [your domain] vs market

### Competitor Comparison Table
| Domain | SEO Strength | Content Focus | Key Differentiator |
|--------|-------------|---------------|-------------------|
| [competitor1.com] | Strong/Medium/Weak | [primary topics] | [positioning] |
| ... | ... | ... | ... |

### Detailed Analysis: [competitor] ([url])

**SEO Strength**: [Strong/Medium/Weak] (heuristic — based on SERP presence)
**Content Volume**: ~[N] indexed pages (from site: search)
**Primary Keywords**: [top 3-5 inferred from titles/meta]
**Strategy**: [description]

#### What they do well
- [strength 1]

#### Where they're vulnerable
- [weakness 1]

#### Keyword Opportunities
| Keyword | Evidence (where we saw it) | Our Opportunity |
|---------|--------------------------|-----------------|

> Competitor data sourced from public HTML and search results.
> For traffic/backlink data, use Ahrefs or SEMrush.
```

**Minimum output:** 5 competitors (or documented explanation if fewer found). Each with keyword focus and positioning statement.

## Mode 5: Full Report

Run all 4 modes sequentially. Consolidate and **deduplicate** findings.

### Deduplication Rule

When the same finding appears in multiple modes (e.g., a keyword gap that also shows up in the content gap analysis), list it ONCE in the action plan with cross-references to the mode sections where it appeared. Do not repeat identical findings.

### Output Format

```markdown
# SEO Full Report: [site]
Generated: [date]

## Executive Summary (max 200 words)
- Overall SEO health: [X/10] (heuristic score — see methodology)
- Top 3 priority recommendations:
  1. [action] — [Quick Win / Medium Effort / Major Project]
  2. [action] — [Quick Win / Medium Effort / Major Project]
  3. [action] — [Quick Win / Medium Effort / Major Project]

> This report uses heuristic analysis of HTML elements and search snippets.
> Scores are not comparable to SEO platform ratings. Validate key findings
> against Google Search Console before making budget decisions.

## 1. Site Audit
[Mode 1 output]

## 2. Keyword Research
[All keywords found — minimum 10]

## 3. Content Gap Analysis
[All gaps found — minimum 5]

## 4. Competitor Map
[Mode 4 output — 5 competitors]

## 5. Prioritized Action Plan (deduplicated)
| # | Action | Source Modes | Effort | Impact | Timeline |
|---|--------|-------------|--------|--------|----------|
| 1 | [Quick win] | Site Audit + Keywords | Low | High | This week |
| 2 | [Medium effort] | Content Gap | Med | High | This month |
| 3 | [Strategic play] | Competitor Map | High | High | This quarter |

Items that appear in multiple modes: list once, cite all source modes in the Source Modes column.
Items marked with ⚠️ affect ad spend decisions — validate with paid tools first.
```

## Error Handling

### No Search Results (AC9)

```text
When web_search returns 0 results for a query:

1. Log: "⚠️ No results for: [query]"
2. Reformulate with broader terms or synonyms:
   - Original: "AI answering service HVAC Portland"
   - Reformulated: "AI phone answering for contractors"
3. If STILL 0 results after reformulation:
   - Include an "Insufficient Data" note in that section of the report
   - Do NOT silently omit the section
   - Example: "### Keyword Research: Insufficient data
     web_search returned no results for [query] or reformulated [query2].
     This may indicate a very niche market or unusual terminology.
     Recommendation: Try broader seed keywords or check spelling."
```

### Blocked web_fetch (AC10)

```text
When web_fetch returns an error (403, 429, timeout, redirect loop):

1. Log the error: "⚠️ web_fetch blocked on [url]: [error type]"
2. Fall back to web_search snippet analysis:
   web_search("site:[domain]")
   web_search("[domain] [primary keyword]")
3. Mark ALL findings from fallback data:
   "(snippet only — full fetch blocked: [error type])"
4. Continue analysis with available data — never crash or abort
5. In the output, note which URLs were fully fetched vs snippet-only

Example output line:
| On-Page SEO | 4/10 | 🟡 | (snippet only — 403 blocked) |
```

### Partial Data Quality Flag

```text
If more than 50% of data sources are snippet-only (blocked fetches),
add a prominent warning at the top of the report:

> ⚠️ **Partial Data Warning:** [N] of [M] target URLs blocked web_fetch.
> This report relies heavily on search snippet data. Findings are
> directionally useful but less detailed than a full-fetch analysis.
> Consider running from a different network or using a paid SEO tool.
```

## Tips

- **Start with Site Audit** if you have an existing site — fix technical issues before chasing keywords.
- **Start with Keyword Research** if you're planning a new site or content strategy.
- **3 competitors is ideal** for gap analysis — more adds noise without insight.
- **Local businesses**: Always include location-modified keywords ("plumber Portland" not just "plumber").
- **Pair with Google Ads**: Keywords flagged as high commercial/transactional intent are strong ad candidates. Always validate with Google Keyword Planner before committing budget.
- **Check monthly**: SEO is not set-and-forget. Re-audit quarterly at minimum.
- **Don't chase vanity keywords**: "marketing" has huge volume but zero conversion intent. Prefer specific long-tail terms.
- **Content quality > quantity**: One thorough 2000-word guide outranks ten 300-word thin posts.
- **Query budget**: A full report uses ~35-45 Brave Search API queries. Free tier (2,000/month) supports ~50 full audits. Single-mode runs use ~5-15 queries.
- **Score interpretation**: All scores are heuristic. A 9/10 means "all checked elements present and well-formed" — not "this page ranks well." Ranking depends on factors we can't measure (domain authority, backlinks, user signals).
- **Non-English sites**: If `web_fetch` returns content in a non-English language, note this explicitly: *"Site content is in [language]. Keyword research and content quality analysis require language-specific context — results may be less accurate. Consider native-language seed keywords."*

## Upgrade Paths

For users who need authoritative data beyond what this skill provides:

```text
Google Search Console (free):
- Real search queries driving traffic
- Actual click-through rates and positions
- Index coverage and Core Web Vitals
- Integrate via API for data-backed audits

Google Keyword Planner (free with Ads account):
- Actual monthly search volume ranges
- CPC estimates for ad planning
- Competition level from advertiser density

SEMrush / Ahrefs / Moz (paid):
- Backlink analysis and domain authority
- Historical ranking data
- Exact keyword difficulty scores
- Competitor traffic estimates
```

## Calibration

To verify this skill produces useful results, test against a known site:

```bash
# Smoke test: Run site audit on example.com
# Expected: Score ≤5/10 (has basic HTML elements but no commercial content or optimization)
# Time: Should complete in <5 minutes

# Real test: Run full report on your actual site
# Expected: Minimum 10 findings, 5+ actionable, relevant to your niche
# If results seem generic or miss obvious issues, refine seed keywords
```
