# Welcome Email Template

**Use for:** New customers immediately after payment is confirmed
**Sent by:** Chloe (chloe.velocity.point@gmail.com) via `send-email-as.sh`
**Timing:** Within 1 hour of payment receipt

---

## Subject Line

```
Welcome to Second Ring — Your AI Receptionist is Being Set Up
```

---

## Email Body (HTML)

```html
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Welcome to Second Ring</title>
</head>
<body style="font-family: Georgia, 'Times New Roman', serif; max-width: 600px; margin: 0 auto; padding: 40px 20px; background: #ffffff; color: #1a1a1a;">

  <div style="margin-bottom: 40px;">
    <h1 style="font-size: 28px; font-weight: normal; margin: 0 0 8px 0; color: #1a1a1a;">Welcome to Second Ring.</h1>
    <p style="font-size: 16px; color: #666; margin: 0;">Your AI receptionist is on its way.</p>
  </div>

  <p style="font-size: 16px; line-height: 1.7;">Hi [FIRST_NAME],</p>

  <p style="font-size: 16px; line-height: 1.7;">
    Thank you for joining Second Ring. Your payment is confirmed and we're setting up your AI receptionist right now.
  </p>

  <p style="font-size: 16px; line-height: 1.7;">
    Here's what happens next:
  </p>

  <div style="background: #f8f8f8; border-left: 3px solid #1a1a1a; padding: 20px 24px; margin: 24px 0;">
    <p style="margin: 0 0 12px 0; font-size: 15px;"><strong>1. We review your intake form</strong><br>
    We're reading through the details you shared so the AI knows your business inside and out.</p>

    <p style="margin: 0 0 12px 0; font-size: 15px;"><strong>2. We set up your dedicated phone number</strong><br>
    We'll provision a new local number for [BUSINESS_NAME] (or port your existing number if you requested that).</p>

    <p style="margin: 0 0 12px 0; font-size: 15px;"><strong>3. We train the AI</strong><br>
    Your services, FAQs, hours, and preferences are loaded into the AI's knowledge base.</p>

    <p style="margin: 0 0 12px 0; font-size: 15px;"><strong>4. We run test calls</strong><br>
    We make sure the greeting is right, the AI answers correctly, and your SMS summaries arrive on time.</p>

    <p style="margin: 0; font-size: 15px;"><strong>5. We hand it to you</strong><br>
    A quick 10-minute walkthrough call, you forward your calls, and you're live.</p>
  </div>

  <p style="font-size: 16px; line-height: 1.7;">
    <strong>Timeline:</strong> You'll be live within 1–3 business days. We'll reach out to schedule your walkthrough call once everything is ready.
  </p>

  <p style="font-size: 16px; line-height: 1.7;">
    <strong>Your 30-day guarantee:</strong> If Second Ring isn't working for you within the first 30 days, you get every dollar back — setup and monthly fee, no questions asked.
  </p>

  <hr style="border: none; border-top: 1px solid #e0e0e0; margin: 32px 0;">

  <p style="font-size: 15px; line-height: 1.7;"><strong>Questions?</strong> Just reply to this email or reach me directly at <a href="mailto:dave.lawler@outlook.com" style="color: #1a1a1a;">dave.lawler@outlook.com</a>.</p>

  <p style="font-size: 15px; line-height: 1.7;">
    Talk soon,<br>
    <strong>Dave Lawler</strong><br>
    Second Ring · Velocity Point LLC<br>
    360-608-0220
  </p>

  <hr style="border: none; border-top: 1px solid #e0e0e0; margin: 32px 0;">

  <p style="font-size: 13px; color: #999; line-height: 1.6;">
    Second Ring by Velocity Point LLC · 8406 NE HWY 99 STE 1078, Vancouver WA 98665<br>
    You're receiving this because you purchased Second Ring. · <a href="[UNSUBSCRIBE_LINK]" style="color: #999;">Unsubscribe</a>
  </p>

</body>
</html>
```

---

## Plain Text Version (fallback)

```
Welcome to Second Ring.

Hi [FIRST_NAME],

Thank you for joining Second Ring. Your payment is confirmed and we're setting up your AI receptionist right now.

Here's what happens next:

1. We review your intake form
   We're reading through the details you shared so the AI knows your business inside and out.

2. We set up your dedicated phone number
   We'll provision a new local number for [BUSINESS_NAME] (or port your existing number if you requested that).

3. We train the AI
   Your services, FAQs, hours, and preferences are loaded into the AI's knowledge base.

4. We run test calls
   We make sure the greeting is right, the AI answers correctly, and your SMS summaries arrive on time.

5. We hand it to you
   A quick 10-minute walkthrough call, you forward your calls, and you're live.

Timeline: You'll be live within 1–3 business days. We'll reach out to schedule your walkthrough call once everything is ready.

Your 30-day guarantee: If Second Ring isn't working for you within the first 30 days, you get every dollar back — setup and monthly fee, no questions asked.

Questions? Just reply to this email or reach me at dave.lawler@outlook.com.

Talk soon,
Dave Lawler
Second Ring · Velocity Point LLC
360-608-0220
```

---

## Send Command

```bash
# Save HTML body to temp file first
cat > /tmp/welcome-email-[CUSTOMERNAME].html << 'EOF'
[paste HTML body here]
EOF

# Send via Chloe's Gmail
~/workspace/scripts/send-email-as.sh \
  "[CUSTOMER_EMAIL]" \
  "Welcome to Second Ring — Your AI Receptionist is Being Set Up" \
  /tmp/welcome-email-[CUSTOMERNAME].html
```

---

## Variables to Replace

| Variable | Replace With |
|----------|-------------|
| `[FIRST_NAME]` | Customer's first name |
| `[BUSINESS_NAME]` | Customer's DBA/preferred name |
| `[CUSTOMER_EMAIL]` | Customer's email address |
| `[UNSUBSCRIBE_LINK]` | Stripe customer portal link or `mailto:dave.lawler@outlook.com?subject=Unsubscribe` |

---

*Template version 1.0 · 2026-03-21*
