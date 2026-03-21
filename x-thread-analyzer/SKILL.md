---
name: x-thread-analyzer
description: "Extract and analyze X/Twitter posts and threads from URLs. Use when: user shares an X.com or twitter.com link, asks to summarize a tweet, wants to analyze a thread, needs engagement data from a post, or wants to extract insights from X content. NOT for: posting tweets (use xurl skill), searching X without a specific URL, or real-time X monitoring."
metadata: { "openclaw": { "emoji": "🐦", "requires": { "tools": ["browser"] } } }
---

# X Thread Analyzer

Extract full content from X/Twitter posts and threads, then analyze with multiple modes.

## When to Use

✅ **USE this skill when:**

- User shares an X.com or twitter.com URL
- "What does this tweet say?"
- "Summarize this thread"
- "What's the engagement on this post?"
- "Extract the key insights from this"
- "Turn this into an issue/task"

❌ **DON'T use this skill when:**

- Posting or replying to tweets (use `xurl` skill)
- Searching X without a specific URL (use Grok)
- Real-time X monitoring or feed scanning
- The URL is not from x.com or twitter.com

## Why Browser-Based

X blocks `web_fetch` for logged-out content. This skill uses browser snapshots to reliably extract post content, engagement data, and thread context without authentication.

## Extraction Process

### Step 1: Clean the URL

Strip tracking parameters before opening:

```text
Input:  https://x.com/user/status/123456?s=52&t=abc
Clean:  https://x.com/user/status/123456

Input:  https://twitter.com/user/status/123456
Clean:  https://x.com/user/status/123456  (normalize domain)
```

### Step 2: Open and Snapshot

```text
1. Open URL in browser (profile="openclaw")
2. Take a compact snapshot
3. Parse the article region
4. Close the browser tab immediately after extraction
```

### Step 3: Extract Fields

Parse the snapshot for these fields:

```text
| Field       | Where to find                                    |
|-------------|--------------------------------------------------|
| Author      | First link with "Verified account" text           |
| Handle      | @username link                                    |
| Post text   | Text nodes inside the article element             |
| Media       | Image/video links (note: can't extract image text)|
| Timestamp   | Time element in the article                       |
| Engagement  | Stats group: replies, reposts, likes, bookmarks   |
| Views       | Views link with count                             |
```

### Step 4: Detect Threads

```text
Check for thread indicators:
- Multiple articles by the same author in the conversation region
- "Show this thread" link
- Reply chain from the same handle

If thread detected:
- Note thread position ("Post 3/7 in thread")
- Scroll to capture additional posts if needed
- Summarize the thread arc, not just the linked post
```

## Analysis Modes

### Default: Summary

Always provide this unless user asks for something specific:

```markdown
**[Author Name]** (@handle) — [timestamp]

[Full post text, preserving formatting]

[If media present: "📷 Attached: [image description]" or "🎥 Attached: video"]

**Engagement**: [views] views • [likes] likes • [reposts] reposts • [bookmarks] bookmarks • [replies] replies
```

Add a brief editorial note: what's interesting, relevant, or worth acting on for the user.

### Mode: Insight Extract

When user wants deeper analysis:

```markdown
## Insights from @[handle]

### Key Claims
1. [Claim with supporting quote]
2. [Claim with supporting quote]

### Actionable Takeaways
1. [What you could do with this information]
2. [How this applies to your work]

### Credibility Check
- **Author**: [Who they are, follower count, domain expertise]
- **Sources cited**: [Are claims backed by research/data?]
- **Verification needed**: [Claims that should be independently verified]
```

### Mode: Issue Creator

Turn a post into a GitHub issue:

```markdown
## Suggested Issue

**Title**: [Descriptive title based on post content]
**Labels**: [Suggested labels]

### Context
[Source post summary with link]

### Action Items
1. [First actionable step derived from the post]
2. [Second step]

### Source
- Post: [URL]
- Author: [name] (@handle)
- Date: [timestamp]
```

### Mode: Engagement Analysis

When user wants to understand performance:

```markdown
## Engagement Analysis: @[handle]

### Raw Numbers
| Metric | Count |
|--------|-------|
| Views | [N] |
| Likes | [N] |
| Reposts | [N] |
| Bookmarks | [N] |
| Replies | [N] |

### Ratios (benchmarks for context)
| Ratio | Value | Benchmark | Assessment |
|-------|-------|-----------|------------|
| Likes/Views | X% | 1-3% typical | Above/Below average |
| Bookmarks/Likes | X:1 | <0.5:1 typical | High = practical value |
| Reposts/Likes | X:1 | 0.1-0.3:1 typical | High = share-worthy |
| Replies/Likes | X:1 | 0.1-0.2:1 typical | High = controversial |

### Assessment
[What the engagement pattern tells us about the content]
- High bookmarks → practical, save-worthy content
- High reposts → strong signal/share-worthy takes
- High replies → controversial or discussion-starting
- High views, low engagement → reached audience but didn't resonate
```

### Mode: Response Drafter

Generate a reply or quote tweet:

```markdown
## Draft Response

### Quote Tweet Option
"[Draft that adds value — extends the point, adds a personal angle, or
applies the insight to a specific domain. Never just agrees.]"

### Reply Option
"[Shorter, conversational reply that contributes to the discussion]"

### Tone Notes
- [Adjust for user's brand voice]
- [Don't be sycophantic — add genuine value]
```

## Handling Edge Cases

### Post Not Loading

```text
If snapshot shows login wall or "Something went wrong":
1. Wait 3 seconds, re-snapshot
2. If still blocked, fall back to web_search for the post content:
   web_search("[author handle] [key phrase from URL]")
3. Report partial data with note about what's missing
```

### Images with Text

```text
If post contains an image that likely has important text:
- Note: "📷 Image attached — may contain text/infographic not extracted"
- Offer: "Want me to analyze the image separately?"
- Use the image tool if user confirms
```

### Long Threads (>5 posts)

```text
For long threads:
1. Summarize the overall arc (beginning → middle → end)
2. Pull out the top 3-5 most insightful posts verbatim
3. Note total thread length: "Thread: 12 posts total, key points below"
4. Offer to extract any specific post by number
```

### Deleted or Private Posts

```text
If the post doesn't exist or is from a private account:
- Say so clearly: "This post appears to be deleted/private"
- Don't fabricate content
- Suggest checking if the URL is correct
```

### Quote Tweets

```text
If the post quotes another tweet:
- Extract BOTH the outer post and the quoted post
- Label clearly: "Quote tweet by @X, quoting @Y:"
- Provide context for both
```

## Tips

- **Always close the browser tab** after extraction. Browser sessions are expensive tokens.
- **Strip tracking params** (`?s=52`, `?t=abc`) from URLs before opening.
- **Bookmark ratio is the best signal.** High bookmarks relative to likes = practical, save-worthy content. Flag these.
- **Check the author.** A quick note on who they are helps contextualize — "Founder of X, 50K followers" vs "Anonymous account, 200 followers."
- **Don't over-analyze small posts.** A single tweet with 100 views doesn't need engagement analysis. Match depth to content.
- **Thread summaries > full threads.** For long threads, a good summary beats pasting 15 posts verbatim.
- **Editorial notes add value.** After summarizing, a one-line "why this matters" is what makes this skill useful vs just reading the tweet.
- **Normalize timestamps.** Convert to the user's timezone when known (check session context).
