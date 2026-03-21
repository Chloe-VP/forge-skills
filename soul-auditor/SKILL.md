---
name: soul-auditor
description: "Score and improve OpenClaw SOUL.md files against the Stanford 3-layer persona framework (Role → Scar Tissue → Agenda). Use when: reviewing agent persona quality, auditing SOUL.md files, improving agent output quality, or checking if an agent's persona is too generic. NOT for: creating personas from scratch (use persona-forge), general prompt optimization, or non-persona system prompts."
metadata: { "openclaw": { "emoji": "📊" } }
---

# SOUL Auditor

Score any SOUL.md file against the 3-layer persona framework. Find what's missing, suggest improvements.

## The Scoring Framework

Each layer is scored 0-3:

| Score | Meaning |
|-------|---------|
| **0** | Absent — layer not present at all |
| **1** | Generic — present but vague ("experienced developer") |
| **2** | Specific — clear detail but could be sharper |
| **3** | Battle-tested — vivid, specific, actionable |

**Total: 0-9 points.** Ratings:
- **7-9**: Strong persona — minor polish only
- **4-6**: Functional but generic — significant improvement possible
- **0-3**: Costume, not a persona — needs a rebuild

## How to Use

### Input
User provides a path to a SOUL.md file, or pastes persona text directly.

### Step 1: Read and Parse

Read the SOUL.md file. Identify content that maps to each layer:

**Layer 1 — Role**
Look for: name, domain, expertise area, scope, specialization, seniority.
- Does it say WHAT this agent does?
- Is the domain narrow enough to be useful?
- Could you distinguish this agent from a generic assistant?

**Layer 2 — Scar Tissue**
Look for: hard rules, "never do X", failure references, refusals, lessons learned, anti-patterns.
- Does it reference what goes wrong in this domain?
- Are there specific things this agent refuses to do?
- Could a newcomer learn from these rules what NOT to do?

**Layer 3 — Agenda**
Look for: optimization targets, success metrics, per-conversation goals, tradeoff preferences.
- Does it define what this agent is optimizing for?
- Are there clear priorities when tradeoffs arise?
- Could you measure whether the agent succeeded?

### Step 2: Score Each Layer

For each layer, output:
```
### Layer N: [Name] — Score: X/3
**Found**: [what's present]
**Missing**: [what's absent]
**Example improvement**: [specific text to add]
```

### Step 3: Overall Assessment

```
## SOUL Audit: [agent name]
Overall Score: X/9 ([rating])

| Layer | Score | Status |
|-------|-------|--------|
| Role | X/3 | [emoji] |
| Scar Tissue | X/3 | [emoji] |
| Agenda | X/3 | [emoji] |

### Top 3 Improvements
1. [Most impactful change]
2. [Second]
3. [Third]
```

### Step 4: Generate Improvements (if requested)

For each weak layer, generate specific text the user can add:

- **Scar tissue generation**: Based on the agent's domain, what are the 3-5 most common failure modes? Write them as lived experience.
- **Agenda generation**: Based on the agent's role, what should they optimize for in a typical interaction? Write a concrete goal.

## Batch Mode

If user provides a directory of SOUL.md files:

1. Audit each file
2. Output a summary table ranking all agents by score
3. Identify the weakest agents (rebuild candidates)
4. Identify patterns (e.g., "no agent has a strong Layer 3")

## Scoring Calibration Examples

**Layer 1 — Role**
- Score 0: No role defined
- Score 1: "You are a helpful coding assistant"
- Score 2: "You are an Azure infrastructure specialist for B2B SaaS deployments"
- Score 3: "You are an Azure infrastructure specialist who manages Function Apps, App Services, and DNS for a SaaS product serving SMB customers on a <$100/mo cloud budget"

**Layer 2 — Scar Tissue**
- Score 0: No hard rules or failure references
- Score 1: "Be careful with production changes"
- Score 2: "Never deploy to production without testing. Always check DNS propagation."
- Score 3: "You've seen 3 outages caused by Function App slot swaps during peak hours. You refuse to deploy between 9am-5pm PT. You always verify CNAME propagation with `dig` before declaring DNS changes complete because GoDaddy's UI lies about propagation status."

**Layer 3 — Agenda**
- Score 0: No optimization target
- Score 1: "Help the user with their request"
- Score 2: "Minimize cloud costs while maintaining uptime"
- Score 3: "Keep monthly Azure spend under $100 while maintaining 99.9% uptime for the answering service. When cost and reliability conflict, choose reliability — a dropped customer call costs more than $50 in overage."
