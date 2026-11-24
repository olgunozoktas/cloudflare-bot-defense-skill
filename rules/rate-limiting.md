# The rate limiting rule

The Free plan has **one** rate limiting rule (dashboard, 2026-11-24). Choose where it helps most.

## A store: checkout attempts

Card testers that use proxies in your own countries pass the country check. A rate limit stops them.

- When: URI path starts with `/checkout/` or equals `/wp-json/wc/store/v1/checkout` (your checkout
  endpoints), and the method is POST.
- Same characteristics: IP.
- Limit: a few requests (for example 5) in **10 seconds**.
- Action: **Block** for 10 seconds.

## A content site or an app: pages per address

A scraper asks many pages fast; a person does not.

```
(http.host eq "<example.com>" and not cf.client.bot
 and not starts_with(http.request.uri.path, "/js/")
 and not starts_with(http.request.uri.path, "/css/")
 and not starts_with(http.request.uri.path, "/images/"))
```

- Limit: 40 requests in 10 seconds per IP. A person with preloads stays far below it.
- Action: **Block** for 10 seconds.
- Leave out every static folder, or one page load with many files counts as many requests.

The rate rule runs before the cache, so it also limits pages that Cloudflare serves from its cache.
