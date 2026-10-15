# MEYA website

Static site (no build step) published on Cloudflare Pages:
https://meya-app.pages.dev/. Publish from this folder with `npx wrangler pages deploy`.

The GitHub Pages notes below are kept for reference.

## Publish on GitHub Pages

GitHub Pages is free only for **public** repositories (private repositories
need a paid GitHub plan). Keep the MEYA source repository private and publish
the website from its own small public repository:

1. On GitHub, create a new **public** repository, e.g. `meya-website`.
2. Upload `index.html` (and this README) to the root of the `main` branch.
3. Repository **Settings → Pages → Build and deployment**:
   Source = *Deploy from a branch*, Branch = `main`, folder = `/ (root)`.
4. The site appears at `https://<your-github-user>.github.io/meya-website/`
   within a few minutes.
5. Optional custom domain: buy a domain, add it under Settings → Pages →
   Custom domain, create the DNS records GitHub shows, then tick
   *Enforce HTTPS*.

## Content rules

- Mark a feature "ready" only after its tests have passed.
- Do not describe calls, groups or attachments as end-to-end encrypted until
  they are implemented and verified.
- Keep the Signal attribution and "not affiliated with or endorsed by Signal".
