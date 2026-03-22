# Second Ring — Customer Onboarding Playbook

**Owner:** Chloe (coordinator)
**Version:** 1.0
**Last Updated:** 2026-03-21
**Status:** Active

---

## Overview

This playbook covers the full onboarding journey for a new Second Ring customer — from signed contract to go-live. It spans three agent domains:

| Domain | Agent | Key Responsibilities |
|--------|-------|---------------------|
| GHL Provisioning | Bob | Sub-account, phone, Voice AI, workflows |
| Azure/Webhook Setup | Tara | Webhook endpoints, function app, transcription pipeline |
| Telegram Notifications | Chloe | Customer channel, daily summaries, escalation routing |

**Total Time (target):** 2–3 hours of agent work + ~15 min of human gates

**Human Gates:** 2 required (PIT creation + go-live approval)

---

## Section 1: Pre-Sale Checklist

Complete before any provisioning begins. All fields required.

### What We Need From the Customer

Collected via the [Customer Intake Form](templates/customer-intake-form.md).

| Item | Why We Need It |
|------|---------------|
| **Business name** (legal + DBA if different) | GHL account name, greeting, KB |
| **Primary contact name** | Account owner, notifications |
| **Contact mobile (for SMS)** | Call summaries delivered here |
| **Contact email** | Backup notifications, Stripe billing |
| **Business phone number** (current, if porting) | Number port or new provisioning |
| **Business address** | GHL sub-account, A2P compliance |
| **Time zone** | Voice AI availability config |
| **Business hours** | After-hours behavior |
| **Services offered** (top 5) | Knowledge base, AI response training |
| **Typical call types** | FAQ content, AI training |
| **Urgent call criteria** | What triggers immediate escalation vs. summary |
| **Custom greeting preference** | "Thank you for calling [Business]..." |
| **Booking link** (if they have one) | Calendly, Google, etc. |
| **FAQs** (3–10 common questions + answers) | Knowledge base seeding |
| **Competitors to avoid mentioning** | AI guardrails |
| **Special instructions** | Seasonal hours, special handling |

### Pre-Sale Gate

Before provisioning starts, verify:

- [ ] Payment received: $297 setup + $297 first month = **$594 via Stripe**
- [ ] Intake form fully completed (no blanks)
- [ ] Intake saved to `VelocityPoint/Product-SecondRing/Customers/[BusinessName]/intake.md`
- [ ] 30-day refund window start date logged
- [ ] Welcome email sent (see [welcome-email template](templates/welcome-email.md))

---

## Section 2: GHL Provisioning (Bob's Domain)

**Owner:** Bob  
**Estimated Time:** 45–60 min (automated) + 10 min Human Gate 1

Bob runs `provision_customer.py` against the intake file. Manual steps documented below for transparency and troubleshooting.

### Step 2.1 — Create Sub-Account

**Script:** `provision_customer.py` (Phase 1)

| Step | Detail |
|------|--------|
| Token | Agency PIT (`ghl-agency-pit.json`) — the ONLY one that works for location creation |
| Snapshot | Use hardcoded snapshot ID: `9Y9ChGNP4WLMkQAoOuMu` (list snapshots via API is impossible) |
| Template | `[SR] Customer Template` (snapshot source ID: `tDDVukW3qNvz2lKDQglh`) |
| Fields required | `name`, `email`, `phone`, `address`, `city`, `state`, `country`, `timezone`, `snapshotId` (top-level), `companyId` |
| ⚠️ Warning | Do NOT nest `snapshotId` inside an object — must be top-level in POST body |
| ⚠️ Warning | Always pass `companyId` when using agency PIT |

**Result:** New location ID logged to customer record.

### Step 2.2 — Human Gate 1 (~10 min)

A VP employee must complete these steps manually (API not available):

1. Log into GHL agency view
2. Navigate to the new sub-account
3. **Buy phone number:** Settings → Phone Numbers → Buy Number → search customer's local area code
4. **Create sub-account PIT:** Settings → API Keys → Create → save to `~/.openclaw/credentials/ghl-[customername].json`
5. Notify Bob via GitHub issue comment with: location ID, phone number, PIT credential path

> **⚠️ PIT Rule:** Custom values, KB, Voice AI, Conv AI ALL require the sub-account PIT. Never use agency PIT for these.

### Step 2.3 — Configure Custom Values

**Script:** `provision_customer.py` (Phase 2, after Human Gate 1)  
**Token:** Sub-account PIT

| Custom Value | Set To |
|-------------|--------|
| `customer_phone` | Customer mobile in +1 format |
| `customer_email` | Customer email address |
| `business_name` | Customer's DBA / preferred name |

### Step 2.4 — Create Knowledge Base

**Token:** Sub-account PIT  
**Name convention:** `[Business Name] Knowledge`

Content to include:
1. Business name and description (2–3 sentences)
2. Services offered (list with brief descriptions)
3. Hours of operation + time zone
4. Booking link (if applicable)
5. FAQs from intake (minimum 5)
6. Urgent call criteria (what triggers escalation)
7. Competitors to avoid mentioning
8. Special instructions

> **Note:** KB API `doc-add` endpoint is not available. Embed content directly in the agent prompt (as seen with Portland Pipe Co).

### Step 2.5 — Create Voice AI Agent

**Token:** Sub-account PIT  
**Name convention:** `[Business Name] Receptionist`

| Setting | Value |
|---------|-------|
| Voice | Dakota H (default) or customer preference |
| Time zone | Customer's local timezone |
| Initial message | `"Thank you for calling [Business Name]. How can I help you today?"` |
| Knowledge base | Link `[Business Name] Knowledge` |
| Base prompt | From `Product-SecondRing/docs/Customer_Receptionist/Base_Prompt.md` |
| Availability | Active 24x7 (or specific hours per customer) |
| Phone number | Purchased in Human Gate 1 |

### Step 2.6 — Verify Workflow: Call.Complete.Notify

This workflow fires automatically on every Voice AI call via "Transcript Generated" trigger.

| Check | Expected |
|-------|---------|
| Automation → Workflows | `Call.Complete.Notify` is Published (toggle ON) |
| Trigger | "Transcript Generated" (fires for all Voice AI calls) |
| Actions | Sends SMS to `customer_phone`, email to `customer_email` |

> No editing needed — uses custom values automatically.

### Step 2.7 — Test Call Flow

Bob runs internal test suite. Three scenarios minimum:

| Scenario | Test |
|----------|------|
| Routine call | Ask a FAQ from the intake form |
| Urgent call | State an emergency matching customer's urgent criteria |
| After-hours | Call outside defined business hours |

**Pass criteria:**
- AI answers within 2 rings
- Greeting uses correct business name
- FAQ answered correctly
- Urgent call criteria recognized
- SMS summary delivered within 60 seconds
- Email transcript received

**Fail → fix before Human Gate 2:**

| Failure | Fix |
|---------|-----|
| Wrong greeting | Edit Voice AI → Agent Details → Initial Message |
| Wrong business name | Edit Voice AI → Agent Details → Business Name |
| Wrong answers | Edit Knowledge Base content |
| No SMS | Check workflow Published; check `notification_phone` in webhook payload; check SR Notification Hub toll-free status |
| No email | Check workflow email action and recipient |

---

## Section 3: Azure Setup (Tara's Domain)

**Owner:** Tara  
**Repo:** `VelocityPoint/secondring-functions`  
**Estimated Time:** 30–45 min

### Step 3.1 — Webhook Endpoint Configuration

Each new customer gets a dedicated webhook endpoint (or uses shared with customer routing).

| Item | Detail |
|------|--------|
| Base URL | Azure Function App (prod) |
| Endpoint pattern | `/api/ghl-webhook?customer={locationId}` |
| Auth | Webhook secret in GHL → Azure → environment variable |
| Events | `call.completed`, `transcript.generated`, `voicemail.received` |

Configure in GHL sub-account:
1. Settings → Integrations → Webhooks
2. Add webhook: URL = Azure endpoint, Events = call.completed + transcript.generated
3. Note the webhook secret → add to Azure Function App environment variables

### Step 3.2 — Function App Connection to GHL

| Setting | Detail |
|---------|--------|
| Environment variable | `GHL_LOCATION_ID_{CUSTOMER}` = sub-account location ID |
| Environment variable | `GHL_PIT_{CUSTOMER}` = sub-account PIT value |
| Function | `ProcessCallWebhook` — receives GHL event, parses transcript |
| Output | Structured call record → storage queue |

Deployment steps:
1. Add customer environment variables to Function App (Azure portal or `az` CLI)
2. Verify webhook endpoint responds 200 to GHL test ping
3. Check Application Insights for any errors

### Step 3.3 — Call Recording & Transcription Pipeline

| Stage | Tool |
|-------|------|
| Inbound trigger | GHL webhook → Azure Function |
| Transcription | GHL native transcript (included in `transcript.generated` payload) |
| Parsing | Azure Function extracts: caller name, intent, urgency, action items |
| Storage | Azure Blob or Cosmos DB (per customer) |
| Notification | Sends structured summary → Telegram notification pipeline |

**Verification:**
- Make a test call to the customer's number
- Confirm webhook fires (check Azure Function logs)
- Confirm transcript payload received and parsed correctly
- Confirm structured summary output matches expected format

---

## Section 4: Telegram Notifications (Chloe's Domain)

**Owner:** Chloe  
**Estimated Time:** 15–20 min

### Step 4.1 — Customer Notification Channel Setup

Each customer gets a Telegram notification setup. Options (discuss with Dave per customer):

**Option A — Agent-mediated (current default):**
- Chloe receives call summaries via internal channel
- Forwards to customer via SMS/email (GHL handles this natively)
- No Telegram setup required on customer side

**Option B — Customer Telegram (power users):**
- Create dedicated Telegram group for customer
- Add customer to group
- Configure webhook to post summaries to group

For most customers: Option A (GHL SMS/email via workflow handles delivery).

### Step 4.2 — Daily Summary Configuration

The `Call.Complete.Notify` workflow sends per-call summaries. For daily digest:

| Setting | Detail |
|---------|--------|
| Trigger | Cron: daily at end of business day (customer's timezone) |
| Content | All calls from that day: caller, intent, action taken, urgency |
| Delivery | SMS to customer phone + optional email |
| Format | Numbered list, brief entries, action items bolded |

Configure in GHL sub-account:
1. Automation → Workflows → `Customer.Active.Checkin`
2. Verify daily digest timing matches customer's timezone
3. Test: manually trigger and verify delivery format

### Step 4.3 — Escalation Routing

Urgent calls bypass the summary queue and route immediately.

| Trigger | Action |
|---------|--------|
| Caller states emergency matching urgent criteria | AI flags as urgent in transcript |
| GHL workflow detects urgent flag | Fires `urgent` webhook event |
| Azure Function receives urgent flag | Sends immediate SMS to customer phone |
| Backup | If SMS fails, email sent + internal Telegram alert to Chloe |

Configure urgent criteria in Voice AI prompt (from intake form).

**Test escalation:**
- Make test call, state an urgent scenario
- Verify immediate SMS within 60 seconds (not queued for daily digest)
- Verify internal alert fires correctly

---

## Section 5: Go-Live Checklist

### Step 5.1 — Phone Number Strategy

**Option A — New number (default, faster):**
- Number purchased in Human Gate 1
- Customer updates their website, voicemail, business cards to use new number
- Immediate — no porting wait

**Option B — Port existing number (slower, seamless for callers):**
- Customer submits port request via GHL (or Twilio directly)
- Timeline: 2–4 weeks
- During porting: route existing number to new number (call forwarding)
- Post-port: all calls come directly

> **Recommendation:** Start with new number + call forwarding. Port later if customer wants it.

### Step 5.2 — Three Go-Live Test Calls

Run with Dave (or designated VP employee) before handing to customer.

| Test | Scenario | Pass Criteria |
|------|----------|--------------|
| **Test 1: Routine** | Call asking for a service quote | AI answers, asks 2 qualifying questions, offers booking link, sends SMS summary within 60s |
| **Test 2: Urgent** | State an emergency (e.g., "I have a burst pipe flooding my basement") | AI recognizes urgency, acknowledges emergency, routes immediately, SMS to customer within 60s |
| **Test 3: After-Hours** | Call at a time outside business hours | AI answers, acknowledges after-hours, captures message, sends summary |

All three must pass before customer handoff.

### Step 5.3 — Human Gate 2 — Dave Review

Dave reviews the test report. Checks:
- [ ] All 3 test scenarios pass
- [ ] Greeting and business name correct
- [ ] SMS + email delivery confirmed
- [ ] Urgent routing confirmed
- [ ] No embarrassing AI responses noted

Go/No-Go decision. If No-Go: Bob/Tara address issues, re-test.

### Step 5.4 — Customer Training (10-min Walkthrough)

Deliver via phone/video call with the customer. Cover:

1. **How to test it** — Call their new number, see what they hear
2. **What they'll receive** — Sample SMS summary, sample email
3. **What "urgent" means** — What triggers immediate alert vs. end-of-day summary
4. **How to request changes** — Email Dave directly or reply to any summary SMS
5. **Booking link** — Confirm their booking link is live and AI is referencing it correctly
6. **Questions** — Leave time for "what if..." scenarios

> Script: Keep it under 10 minutes. Customers don't want training — they want it to work.

### Step 5.5 — Human Gate 3 — Customer: Call Forwarding

Customer must activate call forwarding from their existing number to the new Second Ring number.

Instructions to send:
1. Call their carrier or access their account online
2. Enable unconditional call forwarding to: `[new Second Ring number]`
3. OR use business phone system's call forwarding feature
4. Test by calling their existing number — should reach the AI

> **Gotcha:** Some carriers require calling from the phone being forwarded. Give customer a step-by-step for their specific carrier if needed.

### Step 5.6 — Check-In Reminders

Set these in GHL `Customer.Active.Checkin` workflow on go-live day:

| Touchpoint | Timing | Purpose |
|-----------|--------|---------|
| **Day 1** | 24 hours after go-live | "How's it going?" — catch any early issues |
| **Day 7** | 7 days after go-live | Review first week's calls, any tweaks needed |
| **Day 14** | 14 days after go-live | Mid-month check, value confirmation |
| **Day 30** | 30 days after go-live | 30-day mark — refund window closes, upsell opportunity |

Each check-in: automated SMS from GHL + create task for Chloe to follow up if no response.

---

## Section 6: Troubleshooting Guide

### Common Issues

| Issue | Likely Cause | Fix |
|-------|-------------|-----|
| AI doesn't answer | Voice AI agent not assigned to phone number | GHL → Voice AI → Phone & Availability → assign number |
| AI answers with wrong name | Custom value not set or Initial Message wrong | Check `business_name` custom value; check Agent Details Initial Message |
| No SMS after call | Workflow not published | Automation → `Call.Complete.Notify` → toggle Published ON |
| No SMS after call | `customer_phone` custom value wrong format | Must be `+1XXXXXXXXXX` format |
| No email after call | Workflow email action wrong recipient | Edit workflow email action → verify `customer_email` |
| AI gives wrong answers | KB content outdated or incomplete | Update Knowledge Base content |
| Urgent not routing immediately | Urgent criteria not in AI prompt | Edit Voice AI agent prompt → add urgent criteria |
| Webhook not firing | GHL webhook not configured | Settings → Integrations → Webhooks → verify endpoint |
| Azure Function errors | Environment variable missing | Add `GHL_LOCATION_ID` + `GHL_PIT` to Function App config |
| Transcript not parsing | Payload format changed | Check Azure Function logs, update parser |

### PIT Errors (Bob's domain)

> ⚠️ **STOP AND CHECK** `~/.openclaw/credentials/GHL_PIT_REFERENCE.md` before any PIT-related fix.

| Error | Cause | Fix |
|-------|-------|-----|
| 401 on location creation | Wrong PIT — must use agency PIT | Switch to `ghl-agency-pit.json` |
| 401 on custom values | Agency PIT used — must be sub-account PIT | Use customer sub-account PIT |
| 401 on KB/Voice AI | Same as above | Use sub-account PIT |
| Production sub-account blocked | No PIT available for `[SR] Sales` production | Always blocked — do not attempt |

### Escalation Paths

| Severity | Escalation | Response Time |
|----------|-----------|--------------|
| **AI not answering** (customer calls going to voicemail) | Bob immediately → Dave if not resolved in 1 hour | 1 hour |
| **No notifications** (customer not getting summaries) | Bob + Tara → Dave if 2 hours | 2 hours |
| **Wrong AI responses** (embarrassing or incorrect answers) | Chloe alerts Dave → Bob fixes KB | 30 min (business hours) |
| **Webhook/Azure errors** | Tara → Chuck for infra → Dave if 4 hours | 4 hours |
| **Billing issues** | Chloe → Dave (never autonomous billing changes) | Same business day |
| **Customer refund request** | Dave only — never autonomous | Immediate escalation |

### SLA Expectations

| Metric | Target |
|--------|--------|
| AI answer rate | > 99% (missed calls = customer misses revenue) |
| SMS delivery after call | < 60 seconds |
| Email delivery after call | < 5 minutes |
| Urgent escalation SMS | < 60 seconds |
| Issue response (agent) | < 2 hours business hours |
| Issue response (Dave) | < 4 hours business hours |
| Go-live provisioning | < 3 business days from payment |

### Known Limitations

| Limitation | Status |
|-----------|--------|
| KB API `doc-add` endpoint not available | Embed content in agent prompt directly |
| List snapshots via API: impossible | Use hardcoded snapshot ID `9Y9ChGNP4WLMkQAoOuMu` |
| Production `[SR] Sales` — no PIT available | Always use Dev for testing; new customers get own sub-account |
| GHL website editing — no API | Requires browser automation (Playwright) or manual UI |
| A2P 10DLC campaign | Verify compliance before customer goes live (per A2P project) |

---

## Appendix: Agent Contacts

| Agent | Domain | How to Reach |
|-------|--------|-------------|
| Bob | GHL provisioning, Voice AI, workflows | GitHub issue with label `agent:bob` |
| Tara | Azure Functions, webhooks, transcription | GitHub issue with label `agent:tara` |
| Chloe | Notifications, coordination, escalation | Direct — handles routing |
| Dave | Business decisions, refunds, go-live approval | Telegram (urgent only) |

---

*Built by Chloe (claude-sonnet-4-6) · 2026-03-21*
