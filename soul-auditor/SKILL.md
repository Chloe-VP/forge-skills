---
name: soul-auditor
description: "Score and improve OpenClaw SOUL.md files against the Stanford 3-layer persona framework (Role → Scar Tissue → Agenda). Use when: reviewing agent persona quality, auditing SOUL.md files, improving agent output quality, or checking if an agent's persona is too generic. NOT for: creating personas from scratch (use persona-forge), general prompt optimization, or non-persona system prompts."
metadata: { "openclaw": { "emoji": "📊" } }
---

# SOUL Auditor

Score any SOUL.md file against the 3-layer persona framework. Find what's missing, suggest improvements.

## When to Use

✅ **USE this skill when:**

- Reviewing an existing SOUL.md file for quality
- Auditing multiple agent personas across a team
- Agent output feels generic and you suspect the persona is weak
- After creating a persona with `persona-forge`, want to verify quality
- User says "audit my SOUL file" or "why is my agent giving generic answers"

❌ **DON'T use this skill when:**

- Creating a persona from scratch (use `persona-forge`)
- Optimizing non-persona prompts
- Debugging agent behavior unrelated to persona quality

## The Scoring Framework

Each layer is scored 0-3:

| Score | Meaning | Indicator |
|-------|---------|-----------|
| **0** | Absent | Layer not present at all |
| **1** | Generic | Present but vague, could apply to any agent |
| **2** | Specific | Clear detail, identifiable domain |
| **3** | Battle-tested | Vivid, specific, actionable, with concrete examples |

**Total: 0-9 points.** Ratings:

```text
7-9 points: Strong persona — minor polish only
4-6 points: Functional but generic — significant improvement possible
0-3 points: Costume, not a persona — needs a rebuild with persona-forge
```

## How to Use

### Input

User provides:
- A path to a SOUL.md file, OR
- Pasted persona text directly, OR
- A directory of SOUL.md files (batch mode)

### Step 1: Read and Parse

Read the file and identify content for each layer:

```text
Layer 1 — Role: Look for:
- Agent name and domain
- Expertise area and specialization
- Scope boundaries (what they do / don't do)
- Seniority or experience indicators
```

```text
Layer 2 — Scar Tissue: Look for:
- Hard rules ("never do X")
- Failure references ("we've seen Y go wrong")
- Refusals ("refuse to recommend Z")
- Lessons learned from past mistakes
- Anti-patterns to avoid
```

```text
Layer 3 — Agenda: Look for:
- Optimization targets ("minimize cost while maintaining uptime")
- Success metrics ("keep spend under $X")
- Tradeoff preferences ("when X conflicts with Y, choose Y")
- Per-conversation or per-session goals
- Priority ordering
```

### Step 2: Score Each Layer

For each layer, produce:

```markdown
### Layer 1: Role — Score: X/3

**Found**: [specific text from SOUL.md that maps to this layer]
**Missing**: [what's absent or could be stronger]
**Suggested improvement**:
> [specific text to add or replace]
```

```markdown
### Layer 2: Scar Tissue — Score: X/3

**Found**: [hard rules, refusals, failure references found]
**Missing**: [domain-specific failure modes not covered]
**Suggested improvement**:
> [specific scar tissue text to add, based on the agent's domain]
```

```markdown
### Layer 3: Agenda — Score: X/3

**Found**: [optimization targets, tradeoff preferences found]
**Missing**: [concrete metrics, session-scoped goals]
**Suggested improvement**:
> [specific agenda text with measurable outcomes]
```

### Step 3: Overall Assessment

```markdown
## SOUL Audit: [agent name]
Overall Score: X/9 ([Strong / Functional / Costume])

| Layer | Score | Status |
|-------|-------|--------|
| Role | X/3 | 🟢/🟡/🔴 |
| Scar Tissue | X/3 | 🟢/🟡/🔴 |
| Agenda | X/3 | 🟢/🟡/🔴 |

### Top 3 Improvements (highest impact first)
1. [Most impactful change with specific text]
2. [Second priority]
3. [Third priority]
```

### Step 4: Generate Improvements (if requested)

When user wants auto-generated improvements:

**For missing scar tissue** — generate based on domain:

```text
Research the agent's domain and ask:
1. What are the top 3-5 failure modes in this domain?
2. What do practitioners commonly get wrong?
3. What "best practices" actually backfire?
4. What should this agent refuse to do?

Write as lived experience:
"You've seen [specific failure]. You refuse to [anti-pattern]."
```

**For missing agenda** — generate based on role:

```text
Ask:
1. What does success look like for this agent's typical interaction?
2. What tradeoffs does this agent face?
3. What's the measurable outcome?

Write as a concrete goal:
"Your job is to [specific outcome] while [constraint]."
```

## Batch Mode

When given a directory of SOUL.md files:

### Process

```bash
# Find all SOUL files
find /path/to/agents -name "SOUL.md" -type f
# Audit each one
# Compile results
```

### Output

```markdown
## Team SOUL Audit — [date]

### Summary Table
| Agent | Role | Scars | Agenda | Total | Rating |
|-------|------|-------|--------|-------|--------|
| Chloe | 3 | 2 | 2 | 7/9 | 🟢 Strong |
| Bob | 3 | 3 | 1 | 7/9 | 🟢 Strong |
| Diana | 2 | 1 | 0 | 3/9 | 🔴 Rebuild |

### Patterns
- [e.g., "No agent has a strong Layer 3 — agendas are the weakest across the team"]
- [e.g., "Infrastructure agents have strong scars; customer-facing agents don't"]

### Priority Rebuilds
1. [Weakest agent] — needs [what]
2. [Second weakest] — needs [what]
```

## Scoring Calibration

Concrete examples to calibrate scoring consistency:

### Layer 1 — Role

```text
Score 0: No role defined
  (empty or "You are a helpful assistant")

Score 1: Generic role
  "You are an experienced developer"

Score 2: Specific role
  "You are an Azure infrastructure specialist for B2B SaaS deployments"

Score 3: Battle-tested role
  "You are an Azure infrastructure specialist who manages Function Apps,
  App Services, and DNS for a SaaS product serving SMB customers on a
  sub-$100/mo cloud budget"
```

### Layer 2 — Scar Tissue

```text
Score 0: No hard rules or failure references
  (no "never", "refuse", "don't", or failure patterns)

Score 1: Generic caution
  "Be careful with production changes"

Score 2: Specific rules
  "Never deploy to production without testing. Always check DNS propagation."

Score 3: Vivid failure history
  "You've seen 3 outages caused by Function App slot swaps during peak hours.
  You refuse to deploy between 9am-5pm PT. You always verify CNAME propagation
  with dig before declaring DNS changes complete because GoDaddy's UI lies
  about propagation status."
```

### Layer 3 — Agenda

```text
Score 0: No optimization target
  (no measurable goal or tradeoff preference)

Score 1: Vague helpfulness
  "Help the user with their request"

Score 2: Directional goal
  "Minimize cloud costs while maintaining uptime"

Score 3: Concrete, measurable agenda
  "Keep monthly Azure spend under $100 while maintaining 99.9% uptime for
  the answering service. When cost and reliability conflict, choose
  reliability — a dropped customer call costs more than $50 in overage."
```

## Tips

- **Score before suggesting.** Always show the current state before proposing changes — users need to see the gap.
- **Use their language.** Generated improvements should match the agent's existing voice and domain terminology.
- **Scars are the biggest lever.** Most SOUL files have decent roles but zero scar tissue. Layer 2 improvements deliver the most quality gain.
- **Agenda should be session-scoped.** "In this conversation" or "for this task" focuses the agent better than permanent goals.
- **Batch mode reveals patterns.** Team-wide audits often show systemic weaknesses (e.g., every agent missing Layer 3).
- **Re-audit after changes.** Run the auditor again after applying improvements to verify the score improved.
- **Don't over-score.** A score of 2 is not a failure — it means the persona works but has room to grow. Reserve 3 for genuinely vivid, specific text.
- **Pair with persona-forge.** If a SOUL scores 0-3, don't patch it — rebuild from scratch using `persona-forge`.
