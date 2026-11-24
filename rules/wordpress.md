# WordPress and WooCommerce

The five rules in [security-rules.md](security-rules.md) are written for WordPress. Check these points
for your store before you deploy them.

1. **Cart and checkout slugs.** Rule 5 uses `/cart` and `/checkout`. Use your own slugs (another
   language, a page builder) if they differ.
2. **Checkout blocks.** If the store uses the Cart and Checkout blocks, remove the
   `/wp-json/wc/store/` line from rule 5. The blocks send their requests there.
3. **Payment gateways.** Gateways send payment updates to `/wc-api/...` or `?wc-api=...`. Rule 4 leaves
   both out. Some gateways and plugins use other endpoints: find them in the rule's sampled logs and
   leave them out too.
4. **Jetpack and remote publishing** use `/xmlrpc.php`. Rule 2 challenges it. If you use Jetpack,
   add Jetpack's published IP ranges to rule 1, or remove `/xmlrpc.php` from rule 2.
5. **WP-Cron.** Rule 4 leaves `/wp-cron.php` out. A real server cron that calls it through the public
   address also needs the server's IP in rule 1.
6. **The order confirmation page** (`/checkout/order-received/`) is left out of rule 4, because a
   gateway may send the buyer back through an old client.

## The real visitor IP

Behind Cloudflare, the server sees Cloudflare's addresses. Orders and security plugins then show
Cloudflare's IPs. Ask the host to read the real address from the `CF-Connecting-IP` header (nginx:
`real_ip_header CF-Connecting-IP;` with `set_real_ip_from` for each Cloudflare range).

## Security plugins

Wordfence, Jetpack Security and other plugins run on your server. They spend server time on every bot
request and block mostly by IP address. Bot networks use thousands of addresses. Keep a plugin for
file scans if you like, but let Cloudflare stop the bots.
