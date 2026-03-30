# Tap Ten Website

This directory contains the Tap Ten website workspace.

Recommended structure:

```text
website/
  AGENTS.md
  README.md
  public/
    index.html
    privacy.html
    styles.css
```

## Files

- `public/index.html`: landing page
- `public/privacy.html`: privacy policy
- `public/styles.css`: shared styling
- `AGENTS.md`: website-specific maintenance notes

## Content Notes

- The home page should stay beta-first, not support-first.
- The primary landing-page CTAs are `Join Beta` and `See How It Works`.
- Support contact should remain available, but de-emphasized relative to beta signup.
- The `Try Beta` panel should point people to the beta form and privacy policy; support can live in lighter-touch surfaces such as the footer.

## Deployment

The repo includes a GitHub Pages workflow in [`.github/workflows/website-pages.yml`](../.github/workflows/website-pages.yml).

Current deployment target:
- domain: `playtapten.com`
- publishing source: GitHub Pages via GitHub Actions
- deployed artifact: the contents of `website/public/`

The live site is currently available at:
- `https://playtapten.com`
- `https://playtapten.com/privacy.html`

## Current GitHub Pages setup

The expected repository-side configuration is:

1. In the repository on GitHub, open `Settings` -> `Pages`.
2. Set the source to `GitHub Actions`.
3. Confirm the custom domain is `playtapten.com`.
4. Keep `Enforce HTTPS` enabled.

Do not add a `CNAME` file to `website/public/` for this setup. GitHub's custom Actions-based Pages flow ignores `CNAME` files; the custom domain should be managed in the repository Pages settings instead.

## DNS for `playtapten.com`

For an apex domain on GitHub Pages, the expected DNS shape is:

- Either an `ALIAS` or `ANAME` record for `playtapten.com`, if your DNS provider supports it
- Or `A` records to GitHub Pages:
  - `185.199.108.153`
  - `185.199.109.153`
  - `185.199.110.153`
  - `185.199.111.153`
- Optional `AAAA` records for IPv6 support:
  - `2606:50c0:8000::153`
  - `2606:50c0:8001::153`
  - `2606:50c0:8002::153`
  - `2606:50c0:8003::153`

If you later want `www.playtapten.com`, add that subdomain separately in GitHub Pages and point a DNS `CNAME` record at your GitHub Pages host.
