# cloudflare-bot-defense

A Claude Code / [Agent Skills](https://agentskills.io/) skill that stops spam orders, card testers,
scanners and scrapers at **Cloudflare's edge**, on the **Free plan**, while real people, search
engines and AI assistants still get in.

It turns a proven WooCommerce setup into a method for any stack (WordPress, Laravel, others): five
custom rules, one rate rule, the AI bot policies, origin lockdown, and a validation routine with a
small check script.

```sh
git clone https://github.com/olgunozoktas/cloudflare-bot-defense-skill.git
ln -s "$PWD/cloudflare-bot-defense-skill" ~/.claude/skills/cloudflare-bot-defense
```

Refresh with `git pull`. Nothing to build. Then ask your agent, for example: "protect my store from
bots with Cloudflare" or "my analytics are full of bot visits".

## What is inside

| File | What it covers |
|---|---|
| `SKILL.md` | The workflow: read the current state, list machine paths, the rule order, validation, warnings |
| `rules/security-rules.md` | The five custom rules, each expression, and when to change it |
| `rules/wordpress.md` | WooCommerce checkout blocks, gateways, Jetpack, WP-Cron, the real visitor IP |
| `rules/laravel.md` | Scanner probes plus HTTP/1.x in one slot; finding machine paths with `route:list` |
| `rules/onboarding.md` | Adding the domain, AI policies, proxied DNS, origin lockdown (Authenticated Origin Pulls) |
| `rules/rate-limiting.md` | The Free plan's one rate rule: checkout attempts or pages per address |
| `rules/bot-fight-mode-and-cache.md` | Bot Fight Mode's missing exceptions; the crawler cache rule and its SEO traps |
| `rules/validate.md` | CSR, sampled logs, what to look for |
| `tools/edge-check.sh` | Asks your paths over HTTP/2 and HTTP/1.1 and shows which ones Cloudflare challenged |

## Credit

The rule set comes from **Andrii Toniievych**'s article
[How to protect a WooCommerce store against bots and spam](https://www.linkedin.com/pulse/how-protect-woocommerce-store-against-bots-spam-andrii-toniievych-dad9f/)
(updated 2026-11-23). Read it for the original reasoning and screenshots. This skill rewrites it as
agent instructions and adds:

- variants for stacks without WordPress;
- a first step that reads the zone's existing rules, so that an agent changes them instead of adding copies;
- exceptions for Samsung Internet and Firefox ESR in the old-browser rule;
- the Free-plan traps: Bot Fight Mode has no exceptions, `cf.client.bot` is refused in Cache Rules,
  and the AI "Training" policy also holds Googlebot;
- the SEO risks of ignoring the query string for crawlers.

## Keep it current

The old-browser list in `rules/security-rules.md` is right for late November 2026. Chrome and Firefox
ship a new version about every 4 weeks: move the list forward every 2 or 3 months. Pull requests are
welcome.

## License

MIT
