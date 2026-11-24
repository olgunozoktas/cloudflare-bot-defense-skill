---
name: cloudflare-bot-defense
description: "Use when a site behind Cloudflare gets spam orders, card testing, fake sign-ups, scanner probes, scraper load or bot visits in its analytics, or when the person asks to protect a site, store or app from bots with Cloudflare (WAF custom rules, managed challenge, rate limiting, Bot Fight Mode, AI crawler policies). Works for WordPress/WooCommerce, Laravel and any other stack, on the Free plan."
license: MIT
metadata:
  author: olgunozoktas
  version: "1.0.0"
  checked_against_dashboard: "2026-11-24"
---

# Cloudflare bot defense

Stop bad bots at Cloudflare's edge, before they reach the server. Keep real people, search engines and
AI assistants in. The method comes from Andrii Toniievych's guide for WooCommerce stores (see the
README for the link). This skill makes it work for any stack and adds the checks that keep it safe.

## The goal, in one line

Real visitors pass without a prompt. Search engines and verified bots pass. Scripts get a managed
challenge, which a person can pass and a script cannot.

## Before you change anything

1. Read the zone's current state: **Security → Security rules** (custom rules, rate limiting rules),
   **Security → Settings** (Bot Fight Mode, AI bot policies), **Caching → Cache Rules**. Write it down.
   Another person or agent may have set rules already. Change those rules; do not add copies.
2. Count the free slots. On the Free plan (dashboard, 2026-11-24): **5 custom rules** and **1 rate
   limiting rule**. Join conditions with `or` when the slots run out.
3. List every path that a machine calls: payment webhooks, OAuth callbacks, the API, feeds, sitemaps,
   `robots.txt`, health checks, `/.well-known/`, uptime monitors, your own server's calls to itself.
   Read the app's route list for them (`php artisan route:list`, `wp-json` routes, your framework's list).
   Every rule that can challenge such a path must leave it out. A challenged webhook is a lost payment.
4. Get the server's own public IPv4 and IPv6 addresses. Your app may call itself through Cloudflare.

## The rule set (order matters)

Read [rules/security-rules.md](rules/security-rules.md) for each expression and its variants.

| Order | Rule | Action |
|---|---|---|
| 1 | Allow internal requests and good bots: your server's IPs, verified bots of the categories you want | Skip (remaining custom rules, rate limiting) |
| 2 | Restrict login access: the sign-in and remote-login paths | Managed Challenge |
| 3 | Restrict old browsers: user agents of browser versions that people no longer run | Managed Challenge |
| 4 | Restrict suspicious traffic: HTTP/1.0 and HTTP/1.1 requests, minus machine paths | Managed Challenge |
| 5 | Limit automated orders: cart and checkout from countries you do not sell to | Managed Challenge |
| rate rule | Checkout or form posts: a few requests in 10 seconds per IP | Block |

Use **Managed Challenge**, not Block, for every rule that a person can meet. Use Block only for paths
that no person ever asks for (scanner probes for files your stack never serves).

## Stack variants

- **WordPress / WooCommerce:** the guide's paths apply as written. Read
  [rules/wordpress.md](rules/wordpress.md).
- **Laravel and other frameworks:** there is no `wp-login.php`. Challenge the scanner probes instead,
  and leave out the framework's machine paths. Read [rules/laravel.md](rules/laravel.md).
- **A site that sells nothing:** drop rule 5. Use the slot for scanner probes or a country challenge
  that your analytics justify.

## Other settings

- **Onboarding, DNS, the origin, AI bot policies:** read [rules/onboarding.md](rules/onboarding.md).
- **The one rate limiting rule:** read [rules/rate-limiting.md](rules/rate-limiting.md).
- **Bot Fight Mode and caching for crawlers:** read [rules/bot-fight-mode-and-cache.md](rules/bot-fight-mode-and-cache.md).
  Both have traps that can stop payments or hurt search rankings.

## After each change: validate

Read [rules/validate.md](rules/validate.md). In short:

1. Run `tools/edge-check.sh https://your-site.example` (it asks each path over HTTP/1.1 and HTTP/2
   and prints who got a challenge). Exit 0: the pages and machine paths answer as expected.
2. The same day, open **Security → Analytics → Events** and filter by each rule. Check the CSR (challenge
   solve rate). A high CSR means that the rule challenges people: make it narrower.
3. Open the sampled logs of each rule. Look for webhooks, monitors and partners. Leave them out.
4. Check the payment provider's webhook log for failed deliveries.

## Warnings

- **Never set the AI bot policy "Training" to Block** when you want search traffic. Cloudflare puts
  Googlebot, Bingbot and Applebot in that group, because their crawl also feeds AI features (seen in
  AI Crawl Control on 2026-10-29). Block single training crawlers in **AI Crawl Control** instead.
- **Bot Fight Mode on the Free plan has no exceptions.** No custom rule, Skip or Allow reaches it. It can
  challenge payment webhooks. Check the webhooks the same day, or leave it off.
- **Update the browser version list every 2 or 3 months.** Chrome and Firefox ship a new version about
  every 4 weeks. A list that is not updated challenges people with current browsers.
- **Bots that know the origin IP skip every rule.** Lock the origin to Cloudflare's ranges, or use
  zone-level Authenticated Origin Pulls ([rules/onboarding.md](rules/onboarding.md)).
