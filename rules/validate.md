# Validate each change

A rule that stops real people or webhooks costs more than the bots it stops. Check every change the
same day, and again after a week.

## 1. From a terminal

```bash
tools/edge-check.sh https://example.com
tools/edge-check.sh https://example.com /stripe/webhook /api/health   # add your own machine paths
```

It asks each path over HTTP/2 and over HTTP/1.1 and prints the status and `cf-mitigated`. What you
expect:

- Pages over HTTP/2: 200 with no challenge (a browser).
- Pages over HTTP/1.1: `challenge` (rule 4).
- Machine paths over HTTP/1.1: no `challenge`.
- `/wp-login.php` on a non-WordPress site: `challenge`.

A 403 with no `cf-mitigated` header on a POST to a webhook is often Bot Fight Mode, not your rules.

## 2. In the dashboard: events and CSR

Open **Security → Security rules**. Each custom rule shows its **Events** count and its **CSR**
(challenge solve rate: the share of challenges that a visitor solved).

- **CSR near 0 %:** the rule challenges scripts. Good.
- **CSR of several percent or more:** the rule challenges people. Make it narrower.

## 3. Read the challenged requests

Select a rule's event count. The sampled logs show each request: country, ASN, user agent, path,
HTTP version, referrer. Look for:

- A webhook, a monitor, a partner, a feed reader, a mobile app: leave its path out, or add its IP to
  rule 1.
- A real browser through a company proxy (a recent user agent with HTTP/1.1): accepted, it can pass
  the challenge.
- A country, an ASN or a user agent that sends much traffic and buys nothing: a candidate for its own
  condition. Add it to an existing rule with `or` when the slots are full.

## 4. Analytics after a week

**Analytics → Traffic:** compare the top countries and the requests by status code with the week
before. Your own analytics (page views, sign-ups) should lose bot noise but keep real people.
