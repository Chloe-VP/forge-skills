---
name: x-thread-analyzer
description: Analyze X (Twitter) threads and search results. Given a tweet URL or search query, reconstructs the full thread, identifies key claims, extracts sources/links, analyzes sentiment, and produces a structured intelligence report. For search results, aggregates themes, identifies top voices, and maps consensus vs controversy.
metadata:
  {
    "openclaw":
      {
        "emoji": "🔍",
        "requires": { "bins": ["xurl"] },
        "models": ["xai/grok-3-mini"],
        "install":
          [
            {
              "id": "brew",
              "kind": "brew",
              "formula": "xdevplatform/tap/xurl",
              "bins": ["xurl"],
              "label": "Install xurl (brew)",
            },
            {
              "id": "npm",
              "kind": "npm",
              "package": "@xdevplatform/xurl",
              "bins": ["xurl"],
              "label": "Install xurl (npm)",
            },
          ],
      },
  }
---

# X Thread Analyzer

Analyze X (Twitter) threads and search results — reconstructing conversations, identifying claims, extracting signals, and producing structured intelligence reports.

## Prerequisites

- `xurl` CLI installed and authenticated (`xurl auth status`)
- Access to `xai/grok-3-mini` model for deep interpretation
- Never use `--verbose` / `-v` with xurl in agent sessions (leaks auth headers)

---

## Input Detection

**First, determine the input type:**

| Input | Type | Strategy |
|-------|------|----------|
| `https://x.com/*/status/*` | Tweet URL / Thread | Thread reconstruction |
| `https://twitter.com/*/status/*` | Tweet URL / Thread | Thread reconstruction |
| A tweet ID (numeric) | Single post | Thread reconstruction |
| Any other string | Search query | Search aggregation |

---

## Mode A: Thread Analysis

### Step 1 — Fetch the Root Tweet

```bash
# Accept full URL or bare ID — xurl handles both
xurl read <TWEET_URL_OR_ID>
```

Extract from JSON response:
- `data.id` — tweet ID
- `data.author_id` — author's user ID
- `data.text` — tweet text
- `data.conversation_id` — conversation root ID
- `data.entities.urls[]` — embedded links
- `data.referenced_tweets[]` — replies, quotes, retweets

### Step 2 — Reconstruct the Thread

Fetch all replies in the conversation from the same author:

```bash
# Search for all posts in this conversation from the original author
xurl search "conversation_id:<CONVERSATION_ID> from:<AUTHOR_HANDLE>" -n 50
```

If you don't have the author handle yet, fetch it:

```bash
xurl user <AUTHOR_ID>
# Extract data.username from response
```

Then re-run the conversation search with the handle. Sort results by `created_at` ascending to get chronological thread order.

### Step 3 — Fetch Replies & Engagement (Optional Context)

```bash
# Get top replies from others (for context on reception)
xurl search "conversation_id:<CONVERSATION_ID>" -n 30
```

Filter out the original author's posts (already captured). These are third-party reactions.

### Step 4 — Extract Structured Data

From all thread posts, extract:

**Claims inventory:**
- List every declarative assertion made (facts stated, predictions, arguments)
- Flag hedged claims ("I think", "might") vs. definitive claims
- Note any statistics or numbers cited

**Sources & links:**
- Expand all `t.co` URLs using `data.entities.urls[].expanded_url`
- Categorize: news article, paper, thread, video, product, profile

**Named entities:**
- People mentioned (`@handles`)
- Organizations
- Products / projects

**Engagement signals** (from `data.public_metrics`):
- like_count, retweet_count, reply_count, quote_count
- Note which individual tweets got outsized engagement

### Step 5 — Grok Analysis

Pass the extracted thread data to Grok for interpretation:

```
Model: xai/grok-3-mini

Prompt template:
---
You are analyzing an X (Twitter) thread for intelligence signals.

THREAD AUTHOR: @{handle}
THREAD DATE: {created_at}
THREAD POSTS ({count} posts):

{numbered_thread_text}

ENGAGEMENT PEAKS:
{top_engaged_posts}

Analyze and return:

## Thread Summary
2-3 sentence executive summary of what this thread is about.

## Key Claims
List each distinct claim with:
- Claim text (verbatim or paraphrased)
- Type: [FACT | OPINION | PREDICTION | QUESTION]
- Evidence: what does the author cite (if anything)?
- Verifiability: [VERIFIABLE | OPINION-ONLY | NEEDS-CONTEXT]

## Narrative Arc
How does the argument/story develop? Opening → development → conclusion.

## Sentiment & Tone
Overall tone, emotional register, rhetorical style.

## Credibility Signals
What strengthens or weakens the thread's credibility?

## Key Sources
List all external links with their apparent purpose.

## Red Flags
Any logical gaps, misleading framings, or unsupported leaps.

## TL;DR for Sharing
One sentence that captures the thread's core claim.
---
```

### Step 6 — Output: Thread Intelligence Report

```markdown
# Thread Intelligence Report

**Source:** [@{handle}](https://x.com/{handle}) — {date}
**Thread:** [{first_20_chars}...](https://x.com/{handle}/status/{id})
**Posts in thread:** {count}
**Total engagement:** {likes} likes · {RTs} RTs · {replies} replies

---

## Summary
{grok_summary}

## Key Claims
{grok_claims}

## Narrative Arc
{grok_arc}

## Sentiment & Tone
{grok_sentiment}

## Sources Cited
| Link | Type | Context |
|------|------|---------|
| ... | ... | ... |

## Credibility Assessment
{grok_credibility}

## Red Flags
{grok_red_flags}

## TL;DR
> {grok_tldr}
```

---

## Mode B: Search Aggregation

### Step 1 — Run the Search

```bash
# Basic search
xurl search "<QUERY>" -n 25

# With filters (combine as needed)
xurl search "<QUERY> lang:en" -n 25
xurl search "<QUERY> -is:retweet" -n 25
xurl search "from:<handle> <QUERY>" -n 25
xurl search "<QUERY> min_faves:100" -n 25

# Operator reference (X API v2):
# lang:en                  English only
# -is:retweet              Exclude retweets
# is:verified              Verified accounts only
# min_faves:N              Minimum likes
# min_retweets:N           Minimum retweets
# from:handle              Posts from specific user
# to:handle                Replies to specific user
# since:YYYY-MM-DD         After date
# until:YYYY-MM-DD         Before date
```

### Step 2 — Fetch Top Voices

From search results, identify the most-engaged authors:

```bash
# For authors with high-engagement posts, fetch their profiles
xurl user @{handle}
# Look at: public_metrics.followers_count, verified status
```

### Step 3 — Aggregate Themes

Collect all result texts. Group by:
- Recurring keywords / hashtags
- Shared links / sources
- Sentiment polarity (positive / negative / neutral)
- Author categories (researcher, journalist, enthusiast, critic)

### Step 4 — Grok Analysis

```
Model: xai/grok-3-mini

Prompt template:
---
You are analyzing X (Twitter) search results for intelligence signals.

SEARCH QUERY: "{query}"
RESULT COUNT: {n} posts
DATE RANGE: {earliest} to {latest}

POSTS (sorted by engagement):
{numbered_posts_with_handles_and_metrics}

TOP VOICES:
{top_authors_with_follower_counts}

Analyze and return:

## Topic Overview
What is this conversation actually about? What's driving it right now?

## Key Themes
List 3-7 distinct themes appearing in the results, with representative quotes.

## Top Voices
Who are the most influential contributors? What position does each take?

## Consensus Points
What do most posts agree on?

## Controversy & Debate
Where is there active disagreement? What are the competing positions?

## Sentiment Breakdown
Approximate split: positive / negative / neutral / mixed.
What's driving the dominant sentiment?

## Information Quality
Are sources being cited? Any misinformation signals? Echo chamber patterns?

## Emerging Signals
Any early signals of a trend, shift, or breaking development?

## Intelligence Summary
3-5 bullet points an analyst would want to know.
---
```

### Step 5 — Output: Search Intelligence Report

```markdown
# Search Intelligence Report

**Query:** `{query}`
**Retrieved:** {n} posts · {date_range}
**Top engagement:** {peak_likes} likes on single post

---

## Topic Overview
{grok_overview}

## Key Themes
{grok_themes}

## Top Voices
| Handle | Followers | Position |
|--------|-----------|---------|
| ... | ... | ... |

## Consensus
{grok_consensus}

## Controversy
{grok_controversy}

## Sentiment
{grok_sentiment}

## Information Quality
{grok_quality}

## Emerging Signals
{grok_signals}

## Intelligence Summary
{grok_bullets}
```

---

## Error Handling

| Situation | Resolution |
|-----------|-----------|
| `xurl auth status` fails | Direct user to run `xurl auth oauth2` manually |
| Tweet not found (404) | Post may be deleted or private; report as unavailable |
| Rate limited (429) | Wait 15 min for search, 1 min for reads; retry |
| Thread has 1 post | Author may post in separate tweets; check for replies from same user |
| Search returns 0 results | Try broader query, remove filters, check spelling |
| Grok unavailable | Produce raw data report without analysis layer; note limitation |

**Never** use `--verbose` or any credential flags in agent commands.

---

## Security Notes

- Never read, display, or pass `~/.xurl` contents to any model
- Never print raw `Authorization` headers
- API keys and tokens must be configured by the user manually outside agent sessions
- xurl handles auth automatically once configured

---

## Quick-Reference: Common xurl Commands for This Skill

```bash
# Check auth
xurl auth status

# Read a tweet (URL or ID)
xurl read https://x.com/user/status/1234567890

# Get user info (need handle for conversation search)
xurl user @handle
xurl user <user_id>

# Search conversation thread
xurl search "conversation_id:1234567890 from:authorhandle" -n 50

# Search all replies to a conversation
xurl search "conversation_id:1234567890" -n 30

# General search with filters
xurl search "AI agents lang:en -is:retweet min_faves:10" -n 25
```
