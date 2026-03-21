# Stanford 3-Layer Persona Framework — Reference

## Source
Stanford study on persona prompting efficacy across Claude, GPT-5, and Gemini.
50 persona configurations tested.

Cited by: Louis Gleeson (@aigleeson), March 20, 2026
https://x.com/aigleeson/status/2034947515012042867

## Key Finding
- Generic personas: **60% quality** score
- Specific personas (with failure history): **94% quality** score

## The 3 Layers

### Layer 1: Role
- Who is this expert?
- What's their domain?
- What's their level of experience?

### Layer 2: Scar Tissue
- What failures have they witnessed?
- What mistakes do they refuse to repeat?
- What "conventional wisdom" have they seen backfire?

This layer activates a different reasoning mode. The model stops pattern-matching generic advice and starts pattern-matching "what went wrong and why."

### Layer 3: Agenda
- What outcome are they personally optimizing for in THIS conversation?
- What's their success metric?
- What tradeoffs are they willing to make?

## Why It Works

Without layers 2 and 3, you're "dressing up a chatbot in a costume."

With all 3 layers, you're "running a cognitive simulation of someone who's actually lived the problem."

The key insight: **specificity of failure** is what separates prompts that sound smart from prompts that actually think smart.

Generic personas → textbook answers.
Scars → judgment.
