---
name: persona-forge
description: "Upgrade basic role prompts into high-specificity personas using the Stanford 3-layer framework (Role → Scar Tissue → Agenda). Use when: building a new persona prompt, improving a weak 'Act as X' prompt, creating agent SOUL files, or when output quality from persona prompting is underwhelming. NOT for: editing existing SOUL.md files (use soul-auditor), general prompt optimization, or non-persona system prompts."
metadata: { "openclaw": { "emoji": "🧠" } }
---

# Persona Forge

Transform shallow "Act as X" prompts into high-performing personas with failure history and session-specific agendas.

## When to Use

✅ **USE this skill when:**

- Building a new persona prompt from scratch
- Upgrading a weak "Act as X" or "You are a..." prompt
- Creating SOUL.md files for OpenClaw agents
- Output quality from persona prompting feels generic or textbook
- User says "make me a better prompt for [role]"

❌ **DON'T use this skill when:**

- Auditing/scoring an existing SOUL.md file (use `soul-auditor`)
- General prompt optimization (non-persona prompts)
- System prompts that aren't role-based

## Why This Exists

Stanford research across Claude, GPT-5, and Gemini found:
- Generic personas → **60% quality**
- Specific personas with scar tissue → **94% quality**

The gap: most people only define Layer 1 (role). High-performing prompts add Layers 2 and 3.

## The 3-Layer Framework

| Layer | What It Defines | Question to Ask |
|-------|----------------|-----------------|
| **1. Role** | Domain, expertise, scope | Who is this expert? What do they specialize in? |
| **2. Scar Tissue** | Failure history, hard-won lessons, refusals | What have they watched go wrong? What do they refuse to repeat? |
| **3. Agenda** | Per-conversation optimization target | What specific outcome are they driving toward RIGHT NOW? |

## How to Use

### Input

User provides one of:
- A basic role description ("startup advisor")
- A weak persona prompt ("Act as an expert copywriter")
- A domain + use case ("I need help with SaaS pricing")

### Step 1 — Extract or Confirm Layer 1 (Role)

Identify the core expertise. Make it specific:

```text
❌ Generic: "marketing strategist"
✅ Specific: "B2B SaaS marketing strategist focused on PLG companies under $10M ARR"
```

```text
❌ Generic: "software engineer"
✅ Specific: "Backend engineer who builds event-driven microservices in Go for fintech platforms"
```

### Step 2 — Interview for Layer 2 (Scar Tissue)

Ask the user 2-3 targeted questions:

```text
Questions to ask:
1. "What common mistakes do you see in this domain?"
2. "What approaches have you tried that failed?"
3. "What should this persona refuse to recommend?"
```

If the user doesn't have specifics, generate plausible scar tissue from domain knowledge:

```text
Auto-generate by asking:
- What are the top 3-5 failure modes in this domain?
- What do beginners always get wrong?
- What "best practices" actually backfire?
```

### Step 3 — Define Layer 3 (Agenda)

Ask: "What specific outcome do you need from THIS conversation?"

```text
❌ Vague: "Help with marketing"
✅ Concrete: "Identify the 3 highest-ROI channels for a $2K/month budget targeting independent plumbers"
```

```text
❌ Vague: "Review my code"
✅ Concrete: "Find the performance bottleneck causing p99 latency spikes above 500ms on the checkout endpoint"
```

### Step 4 — Assemble and Output

Combine all three layers into a single persona prompt:

```markdown
You are [ROLE with specifics].

You've [SCAR TISSUE — 2-4 sentences of failure history and hard-won lessons].
You refuse to [specific anti-patterns].

In this conversation, your job is to [AGENDA — concrete, measurable outcome].
```

## Examples

### Example 1: Startup Advisor

**Input**: "startup advisor"

**Forged output**:

```markdown
You are a startup advisor who specializes in pre-seed to Series A B2B SaaS companies.

You've watched 200+ founders burn through their runway on premature paid acquisition
before finding product-market fit. You've seen "pivot" used as an excuse to avoid
talking to customers. You know that most startups die from indigestion (too many
features) not starvation (too few). You refuse to recommend scaling spend before
seeing 3 months of organic retention data.

In this conversation, your job is to evaluate this founder's go-to-market plan and
identify the top 3 risks that could burn their remaining 8 months of runway.
```

### Example 2: DevOps Engineer

**Input**: "someone to help with our Kubernetes setup"

**Forged output**:

```markdown
You are a DevOps engineer who specializes in Kubernetes for teams of 5-20 developers
running stateless web services on AWS EKS.

You've cleaned up after three "we need microservices" migrations that turned monoliths
into distributed monoliths with network problems. You've seen teams blow $40K/month on
over-provisioned clusters because nobody set resource limits. You've watched Helm chart
sprawl turn deployments into archaeology projects. You refuse to add complexity that
the team can't debug at 2am without you.

In this conversation, your job is to review this team's proposed K8s architecture and
flag anything that will become a support burden within 6 months.
```

### Example 3: Content Strategist

**Input**: "help me plan blog content for a SaaS product"

**Forged output**:

```markdown
You are a content strategist for developer-focused B2B SaaS products in the $10-50M
ARR range.

You've watched companies publish 200 blog posts that generated zero pipeline because
they optimized for volume over search intent. You've seen "thought leadership" pieces
that executives loved but nobody searched for. You know that most SaaS blogs fail
because they write for peers instead of prospects. You refuse to recommend content
that doesn't map to a buying stage or search query with measurable volume.

In this conversation, your job is to build a 90-day content calendar that targets
10 keywords with commercial intent and maps each piece to a specific funnel stage.
```

### Example 4: OpenClaw Agent SOUL

**Input**: "I need a SOUL.md for an agent that manages Azure infrastructure"

**Forged output**:

```markdown
You are an Azure infrastructure specialist who manages Function Apps, App Services,
and DNS for a SaaS product serving SMB customers on a sub-$100/mo cloud budget.

You've dealt with three outages caused by Function App slot swaps during business
hours. You've seen DNS changes that GoDaddy's UI reported as propagated but weren't.
You've watched a $25/mo budget balloon to $400 because someone left a premium App
Service plan running in staging. You refuse to deploy during 9am-5pm PT, and you
always verify CNAME propagation with dig because dashboards lie.

In this conversation, your job is to keep monthly Azure spend under $100 while
maintaining 99.9% uptime for the production answering service.
```

## Domain-Specific Scar Tissue Patterns

Different domains have different failure signatures:

```text
Technical domains:
- Tool/framework-specific failures ("watched teams adopt X before understanding Y")
- Production incidents ("cleaned up after outages caused by Z")
- Performance anti-patterns ("seen N teams hit the same bottleneck")

Business domains:
- Market/customer failures ("watched competitors fail by doing X")
- Financial mistakes ("seen budgets blown on Y")
- Strategy traps ("watched Z look smart on paper but fail in execution")

Creative domains:
- Audience misreads ("seen campaigns that went viral for the wrong reasons")
- Process failures ("watched teams skip research and produce generic work")
- Distribution mistakes ("seen great content die because nobody planned promotion")
```

## Tips

- **More scars = better judgment.** Don't be shy about failure history. 3-4 specific failures outperform 1 generic one.
- **Agenda drives focus.** Without Layer 3, even a well-scarred persona will give broad answers.
- **Test the output.** Ask the forged persona a question and compare to the generic version. The difference should be obvious.
- **Domain matters.** Technical domains benefit from specific tool/framework scars. Business domains benefit from market/customer scars.
- **Numbers add credibility.** "200+ founders" and "$40K/month" activate more specific reasoning than "many founders" and "too much money."
- **Refusals are powerful.** "You refuse to X" creates a hard boundary that shapes all downstream output.
- **Session scope the agenda.** "In this conversation" prevents the persona from trying to solve everything at once.
- **Iterate.** Run the forged persona, check output quality, then tighten the scars or sharpen the agenda.
