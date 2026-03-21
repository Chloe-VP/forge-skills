---
name: x-thread-analyzer
description: "Extract and analyze X/Twitter posts and threads from URLs. Use when: user shares an X.com or twitter.com link, asks to summarize a tweet, wants to analyze a thread, needs engagement data from a post, or wants to extract insights from X content. NOT for: posting tweets (use xurl skill), searching X without a specific URL, or real-time X monitoring."
metadata: { "openclaw": { "emoji": "🐦", "requires": { "tools": ["browser"] } } }
---

# X Thread Analyzer

Extract full content from X/Twitter posts and threads, then analyze.

## Why Browser-Based

X blocks `web_fetch` for logged-out scraping. This skill uses browser snapshots to reliably extract post content, engagement data, and thread context without authentication.

## How to Use

### Input
User provides an X/Twitter URL in any format:
- `https://x.com/user/status/123456`
- `https://twitter.com/user/status/123456`
- With query params (`?s=52`, `?t=abc`) — strip before use

### Step 1: Extract

1. Open the URL in browser (`profile="openclaw"`)
2. Take a compact snapshot
3. Parse the article region for:

| Field | Where to Find |
|-------|--------------|
| **Author** | First link with verified account text |
| **Handle** | `@username` link |
| **Post text** | Text nodes in the article element |
| **Media** | Image/video links (describe if visible) |
| **Timestamp** | Time element in the article |
| **Engagement** | Stats group: replies, reposts, likes, bookmarks, views |

4. Close the browser tab (don't leak tabs)

### Step 2: Detect Threads

If the post is part of a thread:
- Check for "Show this thread" or multiple articles by the same author
- Scroll down to capture reply chain if needed
- Note thread position ("3/7 in thread")

### Step 3: Analyze (choose mode based on user intent)

**Default — Summary**
Present extracted data in a clean format:
```
**[Author]** (@handle) — [timestamp]

[Full post text]

**Engagement**: [views] views • [likes] likes • [reposts] reposts • [bookmarks] bookmarks • [replies] replies
```

Add a brief editorial note: what's interesting, relevant, or worth acting on.

**If user asks for deeper analysis, offer these modes:**

#### Insight Extract
- Key claims or findings
- Actionable takeaways
- Relevance to user's domain/work
- Credibility assessment (who is this person, are claims sourced?)

#### Issue Creator
- Convert findings into a GitHub issue
- Include source attribution and link
- Map actionable items to next steps
- Suggest labels and assignees if context available

#### Engagement Analysis
- Views-to-likes ratio (benchmark: 1-3% is typical)
- Bookmarks-to-likes ratio (high = practical value; >1:1 is strong signal)
- Reply sentiment snapshot
- Virality indicators (repost velocity)

#### Response Drafter
- Generate a quote tweet or reply
- Match the tone of the user's brand
- Add value (don't just agree — extend the point)

## Handling Edge Cases

**Post not loading**: X sometimes returns a login wall. If snapshot shows "Something went wrong" or only login prompts:
1. Wait 3 seconds and re-snapshot
2. If still blocked, fall back to `web_search` for the post content
3. Report partial data with a note about what's missing

**Images with text**: If the post contains an image that appears to have important text (infographics, screenshots):
- Note that image text wasn't extracted
- Offer to analyze the image separately if user wants

**Long threads**: For threads >5 posts:
- Summarize the overall arc
- Pull out the top 3-5 most insightful posts
- Note total thread length

**Deleted or private posts**: If the post doesn't exist, say so. Don't fabricate content.

## Tips

- **Always close the browser tab** after extraction. Browser sessions are expensive.
- **Strip tracking params** (`?s=52`, `?t=abc`) from URLs before opening.
- **Bookmark ratio is signal**: Posts with high bookmarks relative to likes contain practical, save-worthy content — flag these.
- **Check the author**: A quick note on who they are (follower count, domain) helps contextualize the content.
