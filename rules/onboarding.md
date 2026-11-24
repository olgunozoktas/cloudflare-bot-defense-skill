# Onboarding, DNS, the origin and the AI bot policies

## Add the domain

1. Create an account at dash.cloudflare.com, then **Domains → Add domain → Connect a domain**.
2. On **Connect your domain**, set the AI policies before you continue:
   - **Search: Allow.** Search engines and AI search bring visitors.
   - **Training: Allow**, unless you accept the loss of search traffic (see the warning below).
   - **Agents: Allow**, and each **Personal Agent: Allow**. These fetch pages for a person who asked.
   - **Import DNS records: Automatic.**
3. Change the domain's nameservers at the registrar to the two `*.ns.cloudflare.com` names that
   Cloudflare shows. Activation can take a few hours.

**Warning: do not set Training to Block if you want search traffic.** Cloudflare puts Googlebot,
Bingbot and Applebot in the Training group, because their crawl also feeds AI features. To refuse
pure training crawlers (CCBot, Bytespider and others), block each one by its own switch in
**AI Crawl Control → Crawlers**.

**Bot Preference Sync** puts Cloudflare's lines at the top of your `robots.txt`. Leave it off when your
own `robots.txt` already names the crawlers.

## DNS: proxy the site

Open **DNS → Records**. Each A, AAAA or CNAME record of the site must be **Proxied** (orange cloud).
"DNS only" sends visitors straight to your server, past every rule. Mail records (MX, DKIM CNAMEs) stay
DNS only.

## Hide and lock the origin

A bot that knows the server's IP skips Cloudflare and all its rules. The IP leaks through old DNS
records, an unproxied subdomain (`mail.`, `ftp.`), and the headers of outgoing mail.

1. Allow web traffic (80, 443) on the server only from Cloudflare's ranges
   ([cloudflare.com/ips](https://www.cloudflare.com/ips/)). Test: a request straight to the IP times out.
2. Better: **zone-level Authenticated Origin Pulls** (SSL/TLS → Origin Server). The server accepts only
   a client certificate that **your** zone uploaded. The global AOP certificate is shared by every
   Cloudflare account, so it proves only "some Cloudflare zone", not "your zone".
3. **Warning:** turn on the certificate check on the server (nginx `ssl_verify_client on;`) only
   after Cloudflare sends the certificate. In the wrong order, every request fails with 400.
