---
name: persona-forge
description: "Upgrade basic role prompts into high-specificity personas using the Stanford 3-layer framework (Role → Scar Tissue → Agenda). Use when: building a new persona prompt, improving a weak 'Act as X' prompt, creating agent SOUL files, or when output quality from persona prompting is underwhelming. NOT for: editing existing SOUL.md files (use soul-auditor), general prompt optimization, or non-persona system prompts."
metadata: { "openclaw": { "emoji": "🧠" } }
---

# Persona Forge

Transform shallow "Act as X" prompts into high-performing personas with failure history and session-specific agendas.

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

### Input: User provides one of:
- A basic role description ("startup advisor")
- A weak persona prompt ("Act as an expert copywriter")
- A domain + use case ("I need help with SaaS pricing")

### Process

**Step 1 — Extract or confirm Layer 1 (Role)**
Identify the core expertise. Make it specific:
- ❌ "marketing strategist"
- ✅ "B2B SaaS marketing strategist focused on PLG companies under $10M ARR"

**Step 2 — Interview for Layer 2 (Scar Tissue)**
Ask the user 2-3 targeted questions:
- "What common mistakes do you see in this domain?"
- "What approaches have you tried that failed?"
- "What should this persona refuse to recommend?"

If the user doesn't have specifics, generate plausible scar tissue from domain knowledge:
- What are the top 3-5 failure modes in this domain?
- What do beginners always get wrong?
- What "best practices" actually backfire?

**Step 3 — Define Layer 3 (Agenda)**
Ask: "What specific outcome do you need from THIS conversation?"
The agenda should be concrete and session-scoped:
- ❌ "Help with marketing"
- ✅ "Identify the 3 highest-ROI channels for a $2K/month budget targeting independent plumbers"

**Step 4 — Assemble and Output**
Combine all three layers into a single persona prompt. Format:

```
You are [ROLE with specifics].

You've [SCAR TISSUE — 2-4 sentences of failure history and hard-won lessons].
You refuse to [specific anti-patterns].

In this conversation, your job is to [AGENDA — concrete, measurable outcome].
```

### Output Example

**Input**: "startup advisor"

**Output**:
```
You are a startup advisor who specializes in pre-seed to Series A B2B SaaS companies.

You've watched 200+ founders burn through their runway on premature paid acquisition
before finding product-market fit. You've seen "pivot" used as an excuse to avoid
talking to customers. You know that most startups die from indigestion (too many
features) not starvation (too few). You refuse to recommend scaling spend before
seeing 3 months of organic retention data.

In this conversation, your job is to evaluate this founder's go-to-market plan and
identify the top 3 risks that could burn their remaining 8 months of runway.
```

## Tips

- **More scars = better judgment.** Don't be shy about failure history. 3-4 specific failures outperform 1 generic one.
- **Agenda drives focus.** Without Layer 3, even a well-scarred persona will give broad answers.
- **Test the output.** Ask the forged persona a question and compare to the generic version. The difference should be obvious.
- **Domain matters.** Technical domains benefit from specific tool/framework scars. Business domains benefit from market/customer scars.
