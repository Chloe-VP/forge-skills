# xurl Command Patterns — X Thread Analyzer Reference

Practical command patterns used by the x-thread-analyzer skill. All commands return JSON to stdout.

---

## Auth Check

```bash
# Always verify auth before running analysis
xurl auth status
```

Expected: lists configured apps with token status. If empty/error, user must run `xurl auth oauth2` manually.

---

## Thread Reconstruction Patterns

### Pattern 1: Start from a tweet URL

```bash
# Step 1: Fetch the root tweet
xurl read https://x.com/sama/status/1234567890123456789

# Step 2: Extract conversation_id and author_id from response
# data.conversation_id → "1234567890123456789"
# data.author_id → "12345"

# Step 3: Get author handle
xurl user 12345
# → data.username: "sama"

# Step 4: Reconstruct the thread (all posts by author in conversation)
xurl search "conversation_id:1234567890123456789 from:sama" -n 50

# Step 5: Get third-party replies for reception context
xurl search "conversation_id:1234567890123456789 -from:sama" -n 30
```

### Pattern 2: Start from a bare tweet ID

```bash
xurl read 1234567890123456789
# Same flow as Pattern 1 from here
```

### Pattern 3: Long thread (50+ posts)

xurl search returns up to 100 results. For very long threads, the author may span multiple pages — but in practice, most threads are under 30 posts. Fetch up to 100 to be safe:

```bash
xurl search "conversation_id:<ID> from:<handle>" -n 100
```

---

## Search Aggregation Patterns

### Pattern 4: Topic search with quality filters

```bash
# English posts only, no retweets, some engagement signal
xurl search "OpenAI GPT-5 lang:en -is:retweet min_faves:5" -n 25
```

### Pattern 5: Recent breaking news / trend

```bash
# Posts from last 7 days on a topic
xurl search "Claude 4 since:2026-03-14 until:2026-03-21" -n 25
```

### Pattern 6: Influencer's perspective on a topic

```bash
xurl search "from:sama AI safety" -n 20
xurl search "from:karpathy neural networks" -n 20
```

### Pattern 7: Hashtag conversation

```bash
xurl search "#buildinpublic AI agents lang:en" -n 25
```

### Pattern 8: Find debate / controversy

```bash
# Look for both sides
xurl search "AGI timeline debate -is:retweet min_faves:10" -n 30
```

---

## User Profile Lookup Patterns

### Pattern 9: Look up by handle

```bash
xurl user @GaryMarcus
xurl user elonmusk
```

Key fields from response:
- `data.username` — handle
- `data.name` — display name
- `data.public_metrics.followers_count` — follower count
- `data.verified` — verification status
- `data.description` — bio

### Pattern 10: Look up by ID (from tweet data)

```bash
xurl user 783214  # numeric user ID also works
```

---

## Data Extraction Reference

### From `xurl read` response

```json
{
  "data": {
    "id": "1234567890",
    "text": "Tweet text here",
    "author_id": "12345",
    "conversation_id": "1234567890",
    "created_at": "2026-03-21T18:00:00.000Z",
    "public_metrics": {
      "retweet_count": 42,
      "reply_count": 18,
      "like_count": 310,
      "quote_count": 7
    },
    "entities": {
      "urls": [
        {
          "url": "https://t.co/abc123",
          "expanded_url": "https://arxiv.org/abs/2601.00001",
          "display_url": "arxiv.org/abs/2601.00001"
        }
      ],
      "mentions": [
        { "username": "OpenAI", "id": "818895875" }
      ]
    }
  }
}
```

### From `xurl search` response

```json
{
  "data": [
    {
      "id": "1234567890",
      "text": "...",
      "author_id": "12345",
      "public_metrics": { ... },
      "created_at": "2026-03-21T18:00:00.000Z"
    }
  ],
  "meta": {
    "newest_id": "...",
    "oldest_id": "...",
    "result_count": 25
  }
}
```

---

## jq Helpers (for parsing in scripts)

```bash
# Extract conversation_id from a tweet read
xurl read <ID> | jq -r '.data.conversation_id'

# Extract author_id
xurl read <ID> | jq -r '.data.author_id'

# Extract all expanded URLs from a tweet
xurl read <ID> | jq -r '.data.entities.urls[]?.expanded_url'

# Sort search results by likes (descending)
xurl search "topic" -n 25 | jq '.data | sort_by(-.public_metrics.like_count)'

# Get all unique author_ids from search results
xurl search "topic" -n 25 | jq -r '.data[].author_id' | sort -u

# Extract just text + metrics from search
xurl search "topic" -n 25 | jq '.data[] | {text: .text, likes: .public_metrics.like_count}'
```

---

## Rate Limit Guidance

| Endpoint | Approximate limit | Strategy |
|----------|-----------------|----------|
| `xurl read` (GET /2/tweets/:id) | ~900/15min | Usually fine for single threads |
| `xurl search` | ~450/15min | Batch queries, don't loop tight |
| `xurl user` | ~900/15min | Cache user lookups in session |

If you hit 429:
- Search endpoints: wait ~15 minutes
- Read endpoints: wait ~1 minute
- xurl will return a JSON error with `code: 429`
