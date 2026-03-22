# Second Ring — Go-Live Checklist

**Customer:** _______________
**Go-Live Date:** _______________
**Dave Review:** _______________
**Agent:** Bob + Tara + Chloe

---

## Phase 1 — GHL Provisioning (Bob)

### Sub-Account
- [ ] Sub-account created from `[SR] Customer Template` snapshot
- [ ] Location ID logged: `_______________________`
- [ ] Custom values set: `business_name`, `customer_phone`, `customer_email`

### Phone Number
- [ ] Phone number purchased in customer's local area code
- [ ] Number: `_______________________`
- [ ] Number assigned to Voice AI agent

### Knowledge Base
- [ ] KB created: `[Business Name] Knowledge`
- [ ] Business description added
- [ ] Services list added (5+ services)
- [ ] Hours of operation added
- [ ] FAQs added (5+ minimum)
- [ ] Urgent call criteria added
- [ ] Booking link added (if applicable)
- [ ] Special instructions added

### Voice AI Agent
- [ ] Agent created: `[Business Name] Receptionist`
- [ ] Greeting correct: "Thank you for calling [Business Name]..."
- [ ] Voice selected (Dakota H or per customer preference)
- [ ] Time zone set to customer's local timezone
- [ ] Knowledge base linked
- [ ] Base prompt customized with business details
- [ ] Availability: Active 24x7 (or hours per intake)

### Workflow
- [ ] `Call.Complete.Notify` workflow is **Published** (toggle ON)
- [ ] Workflow sends SMS to correct phone
- [ ] Workflow sends email to correct email

---

## Phase 2 — Azure / Webhook Setup (Tara)

- [ ] Webhook endpoint configured for this customer
- [ ] GHL webhook configured (call.completed + transcript.generated events)
- [ ] Azure Function environment variables set (`GHL_LOCATION_ID`, `GHL_PIT`)
- [ ] Webhook endpoint responds 200 to test ping
- [ ] Call parsing pipeline verified
- [ ] Structured summary output format correct

---

## Phase 3 — Notification Routing (Chloe)

- [ ] SMS delivery confirmed working
- [ ] Email delivery confirmed working
- [ ] Daily digest timing configured for customer's timezone
- [ ] Urgent escalation routing tested

---

## Phase 4 — Test Calls (Bob + Dave)

### Test 1: Routine Call
- [ ] Called the Second Ring number
- [ ] AI answered within 2 rings
- [ ] Correct business name in greeting
- [ ] Asked 2 qualifying questions
- [ ] Answered a FAQ correctly
- [ ] Offered booking link (if applicable)
- [ ] SMS summary received within 60 seconds
- [ ] Email summary received within 5 minutes

### Test 2: Urgent Call
- [ ] Stated an emergency matching customer's urgent criteria
- [ ] AI recognized urgency
- [ ] Immediate SMS alert sent (< 60 seconds)
- [ ] Did NOT get batched into daily digest

### Test 3: After-Hours Call
- [ ] Called outside business hours
- [ ] AI answered professionally
- [ ] Acknowledged after-hours status
- [ ] Captured caller info
- [ ] SMS summary sent to customer

**All 3 tests:** ☐ PASS ☐ FAIL (fix before proceeding)

---

## Phase 5 — Dave Go/No-Go Review

- [ ] Test report reviewed
- [ ] All 3 scenarios confirmed pass
- [ ] Dave: Go ☐ / No-Go ☐
- [ ] If No-Go: issues documented, re-test scheduled

---

## Phase 6 — Customer Activation

### Call Forwarding (Customer action)
- [ ] Instructions sent to customer
- [ ] Customer confirmed call forwarding active
- [ ] Test: call existing number → AI answers ☐

### Customer Training (10-min call)
- [ ] How to test their own number
- [ ] What SMS summaries look like (showed example)
- [ ] What email summaries look like (showed example)
- [ ] Urgent call criteria confirmed with customer
- [ ] How to request changes (email Dave)
- [ ] Booking link confirmed working
- [ ] Customer questions answered

---

## Phase 7 — Check-In Reminders Set

- [ ] Day 1 reminder set (24 hours from go-live)
- [ ] Day 7 reminder set
- [ ] Day 14 reminder set
- [ ] Day 30 reminder set (refund window closes — final satisfaction check)

---

## Go-Live Confirmation

| Item | Status |
|------|--------|
| All provisioning complete | ☐ |
| All tests passed | ☐ |
| Dave approved | ☐ |
| Customer forwarding active | ☐ |
| Customer trained | ☐ |
| Check-ins scheduled | ☐ |

**GO-LIVE CONFIRMED:** ☐ Yes — Date/Time: _______________

---

*Sign off: [Bob - model] [Tara - model] [Chloe - model] [Dave]*
