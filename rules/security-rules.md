# The five custom rules

Make each rule in **Security → Security rules → Create rule → Custom rules**. Select **Edit expression**
and paste the expression. Replace every value in angle brackets (`<...>`). The dashboard validates the
expression when you select **Deploy**; a refused expression names its error.

`cf.client.bot` is true for Cloudflare's verified bots (Googlebot, Bingbot and the other names on
[radar.cloudflare.com/traffic/verified-bots](https://radar.cloudflare.com/traffic/verified-bots)).
Every challenge rule below leaves them out.

## Rule 1 — Allow internal requests and good bots (Skip, order: First)

Your server may call its own site through Cloudflare (a health probe, a queue job, a webhook from a
service on the same machine). A challenge would stop it. Good bots also skip the challenge rules here,
so that a rule mistake never costs you search traffic.

```
(cf.client.bot and cf.verified_bot_category in {"Search Engine Crawler" "Search Engine Optimization" "AI Search" "AI Assistant" "Page Preview" "Feed Fetcher" "Monitoring & Analytics"})
or (ip.src in {<server IPv4> <server IPv6>})
```

- Action: **Skip**. Components: **All remaining custom rules** and **All rate limiting rules**. Keep
  **Log matching requests** on, so that you can see what it lets through.
- Remove a bot category from the list when you do not want it (for example "AI Assistant").
- Add a fixed partner here (a payment provider's published IP list, an uptime monitor) when the
  sampled logs show that a rule challenges it.

## Rule 2 — Restrict login access (Managed Challenge)

Bots guess passwords on the sign-in page and on remote-login endpoints. A person passes a managed
challenge once; a script does not.

WordPress:

```
(starts_with(http.request.uri.path, "/wp-login.php"))
or (starts_with(http.request.uri.path, "/xmlrpc.php"))
```

Other stacks: name your own paths, for example `/login`, `/register`, `/forgot-password`. Challenge
only the page (GET). A challenge on a background POST (an XHR or `fetch`) fails without a visible
prompt, so the person sees a broken form.

```
http.request.method eq "GET"
and http.request.uri.path in {"/login" "/register" "/forgot-password"}
```

## Rule 3 — Restrict old browsers (Managed Challenge)

Bot scripts are written once and rarely updated. They keep sending the user agent of an old browser
version. People update their browsers automatically.

```
not cf.client.bot
and not http.user_agent contains "Electron/"
and not http.user_agent contains "ChatGPT"
and not http.user_agent contains "Claude"
and not http.user_agent contains "SamsungBrowser/"
and (
  http.user_agent contains "Chrome/11" or
  http.user_agent contains "Chrome/12" or
  http.user_agent contains "Chrome/13" or
  http.user_agent contains "Chrome/141.0" or
  http.user_agent contains "Chrome/142.0" or
  http.user_agent contains "Chrome/143.0" or
  http.user_agent contains "Android 9." or
  http.user_agent contains "Android 8." or
  http.user_agent contains "Android 7." or
  http.user_agent contains "Android 6." or
  http.user_agent contains "Android 5." or
  http.user_agent contains "Firefox/11" or
  http.user_agent contains "Firefox/12" or
  http.user_agent contains "Firefox/13" or
  (http.user_agent contains "Firefox/14" and not http.user_agent contains "Firefox/140.")
)
```

- The list is right for late November 2026 (current Chrome: 158). **Move it forward every 2 or 3
  months:** challenge versions that are older than about 4 months.
- `"Chrome/11"` matches Chrome 110 to 119; `"Chrome/13"` matches 130 to 139.
- Electron apps (Slack, Discord, VS Code link previews) send old Chrome versions: they are left out.
- **Samsung Internet** runs an older Chrome engine and names it in its user agent. It is left out, so
  that its people are not challenged on every visit.
- **Firefox ESR 140** (companies, Tor Browser) is left out until the next ESR. Change this line when
  ESR moves.
- Android 10 and later send `Android 10` for every version (Chrome freezes the user agent), so the
  list stops at 9.

## Rule 4 — Restrict suspicious traffic (Managed Challenge)

Browsers reach HTTPS sites over HTTP/2 or HTTP/3. Most bot libraries (Python Requests, Node's HTTP
client, curl scripts) use HTTP/1.1. Challenge HTTP/1.x, and leave out every path that a machine calls.

WordPress / WooCommerce:

```
(not cf.client.bot
and not starts_with(http.request.uri.path, "/wp-cron.php")
and not starts_with(http.request.uri.path, "/wp-admin/admin-ajax.php")
and not starts_with(http.request.uri.path, "/wp-content/")
and not starts_with(http.request.uri.path, "/wp-includes/")
and not starts_with(http.request.uri.path, "/wp-json/")
and not starts_with(http.request.uri.path, "/checkout/order-received/")
and not starts_with(http.request.uri.path, "/.well-known/")
and not starts_with(http.request.uri.path, "/wc-api/")
and not starts_with(http.request.uri.query, "wc-api=")
and http.request.version in {"HTTP/1.0" "HTTP/1.1"})
```

Laravel and others: [laravel.md](laravel.md) has a full expression.

- **Warning:** corporate proxies (for example a secure web gateway) can send a person's request over
  HTTP/1.1. That person sees a challenge and passes it. Check the CSR: a high value means too many
  people.
- Leave out each integration that the sampled logs show as challenged.

## Rule 5 — Limit automated orders (Managed Challenge)

Card testers place many orders from many countries. Challenge the cart and the checkout for
countries that you do not sell to.

```
(starts_with(http.request.uri.path, "/checkout") and not ip.src.country in {"US" "CA"})
or (starts_with(http.request.uri.path, "/cart") and not ip.src.country in {"US" "CA"})
or (starts_with(http.request.uri.path, "/wp-json/wc/store/") and not ip.src.country in {"US" "CA"})
```

- Replace the country codes and the paths with your own.
- **Warning:** the WooCommerce Cart and Checkout **blocks** send their requests to
  `/wp-json/wc/store/`. If your store uses these blocks, remove the third line, or the checkout breaks.
- The country check does not stop testers that use proxies in your countries. Add the rate limiting
  rule ([rate-limiting.md](rate-limiting.md)).
- A site that sells nothing: use this slot for scanner probes, or for a country that your analytics
  show as bot traffic (a managed challenge on pages, with static files left out).
