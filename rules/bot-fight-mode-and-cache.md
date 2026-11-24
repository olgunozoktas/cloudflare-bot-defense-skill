# Bot Fight Mode and caching for crawlers

## Bot Fight Mode

**Security → Settings → Bot traffic → Bot fight mode.** It challenges requests that Cloudflare scores
as automated.

**Warning: on the Free plan it has no exceptions.** No custom rule, Skip or Allow reaches it
(Cloudflare's "Bot Fight Mode" page, Limitations). Cloudflare says that it may challenge API and
mobile app traffic, and names payment processors among the usual false positives.

1. Turn it on only when you can check the machine paths the same day.
2. Open **Security → Analytics → Events**, and filter **Service: Bot Fight Mode**. Look for your
   webhook paths.
3. In the payment provider's dashboard, look for failed webhook deliveries.
4. A challenged webhook: turn Bot Fight Mode off. On Pro and above, use **Super Bot Fight Mode** with a
   custom Skip rule for the webhook paths.

## Force caching for crawlers (the guide's cache rule)

Some verified crawlers ask the same filtered pages again and again (`/shop/?filter_brand=...&orderby=...`).
A cache rule can serve them the page without its query string, from Cloudflare's cache.

- **Caching → Cache Rules → Create rule**, name "Force caching for bots".
- When:

  ```
  ((lower(http.user_agent) contains "bot"
      or lower(http.user_agent) contains "meta-externalagent"
      or lower(http.user_agent) contains "spider")
    and not starts_with(http.request.uri.path, "/wp-content/")
    and not starts_with(http.request.uri.path, "/wp-admin/"))
  and not starts_with(http.request.uri.path, "/.well-known/")
  ```

- Then: **Eligible for cache**; **Cache key → Ignore query string: on**; **Edge TTL: 1 day**.
- `cf.client.bot` cannot be used in a Cache Rule on the Free plan (the save answered 400 on
  2026-11-14), so the rule matches the user agent text.

**Read these warnings before you use it:**

1. **Pagination and search pages.** With the query string ignored, a crawler gets page 1 for
   `?page=2`. Search engines then see duplicates and stop finding deep pages. Do not use it when your
   pages change content by query string, unless the crawlers only reach filters.
2. **Prices and stock.** With a 1-day Edge TTL, Google can see a price that is a day old. Google
   Merchant Center then reports a price mismatch. Use 2 hours or less for a store in Google Shopping.
3. **A different page for crawlers.** If your app gives verified crawlers a different page than people
   get, a script that sends "bot" in its user agent fills the cache first. Then real crawlers get the
   script's page. Do not use this rule on such a site.
