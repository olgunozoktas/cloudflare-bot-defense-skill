# Laravel (and other non-WordPress stacks)

A Laravel site has no `wp-login.php`, `xmlrpc.php` or `wp-json`. Bots still ask for them: these are
scanners that look for a weak WordPress or a leaked file. Challenge them at the edge, so that they
never reach PHP.

## Find the machine paths first

```bash
php artisan route:list --json | python3 -c '
import json,sys,re
pat=re.compile(r"webhook|^/api/|feed|rss|sitemap|robots|llms|well-known|health|^/up$|callback|csp-report")
for r in json.load(sys.stdin):
    u="/"+r["uri"].lstrip("/")
    if pat.search(u): print(r["method"].ljust(10), u)'
```

Each path in the answer that a machine calls goes into the "not" list below. Typical ones:

| Path | Who calls it |
|---|---|
| `/stripe/webhook` (Cashier), `/<gateway>/webhook` | The payment provider |
| `/api/...` | API clients, mobile apps |
| `/up`, `/health` | Uptime monitors, the load balancer |
| `/feed...`, `/rss.xml`, `/sitemap...`, `/robots.txt`, `/llms.txt` | Feed readers, crawlers |
| `/.well-known/...` | Certificate checks, Apple Pay, security.txt readers |
| `/csp-report` | Browsers' report requests |
| `/cdn-cgi/...` | Cloudflare itself |

OAuth callbacks (`/oauth/.../callback`) are browser redirects: browsers use HTTP/2, so they pass.

## Rule 4 for Laravel: HTTP/1.x plus scanner probes, in one slot

```
(not cf.client.bot
 and http.request.version in {"HTTP/1.0" "HTTP/1.1"}
 and http.host in {"<example.com>" "www.<example.com>"}
 and not starts_with(http.request.uri.path, "/cdn-cgi/")
 and not starts_with(http.request.uri.path, "/.well-known/")
 and not starts_with(http.request.uri.path, "/api/")
 and not starts_with(http.request.uri.path, "/stripe/")
 and not starts_with(http.request.uri.path, "/webhooks/")
 and not starts_with(http.request.uri.path, "/feed")
 and not starts_with(http.request.uri.path, "/sitemap")
 and not http.request.uri.path in {"/robots.txt" "/llms.txt" "/health" "/up" "/csp-report"}
 and not http.request.uri.path.extension in {"js" "css" "svg" "png" "jpg" "jpeg" "webp" "gif" "ico" "woff" "woff2" "webmanifest" "xml" "txt"})
or (http.host in {"<example.com>" "www.<example.com>"}
 and (http.request.uri.path in {"/wp-login.php" "/xmlrpc.php"}
  or starts_with(http.request.uri.path, "/wp-admin")
  or starts_with(http.request.uri.path, "/wp-content")
  or starts_with(http.request.uri.path, "/wp-includes")
  or starts_with(http.request.uri.path, "/.env")
  or starts_with(http.request.uri.path, "/.git/")))
```

- `http.host` keeps the rule off other hosts of the zone (an image or file subdomain).
- Static files are left out: Cloudflare caches them, and a challenge on a stylesheet breaks a page.
- Livewire, Inertia and other XHR requests are not left out. A person who passed the challenge on the
  page has the `cf_clearance` cookie, and the XHR requests pass with it.

## Rule 2 for Laravel

Fortify and Breeze put sign-in at `/login`, `/register`, `/forgot-password` and
`/two-factor-challenge`. A challenge on each sign-in page adds a step for people. Use it when the
Security Events show password guessing; else keep the slot for something the logs justify.

## Your own server

Laravel's scheduler, a queue worker or a health check can call the site's public address. Put the
server's IPv4 and IPv6 into rule 1 (Skip). Find them on the server with `curl -4 ifconfig.me` and
`curl -6 ifconfig.me`, or in the host's panel.
