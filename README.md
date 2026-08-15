# PullTimer website

Marketing site for the Mac app. Same teal / sand / glass language as PullTimer.

```
website/
  index.html      Landing page
  guide.html      Tutorial (same design)
  GUIDE.md        Same tutorial as a document
  styles.css
  app.js
  assets/
```

## Preview locally

```bash
cd website
python3 -m http.server 4173
```

Open [http://localhost:4173](http://localhost:4173).

## Publish

- **GitHub Pages:** set the source to `/website` (or copy this folder to `/docs`).
- **Netlify / Cloudflare Pages:** point the publish directory at `website`.
Download file: `website/downloads/PullTimer.dmg` (built with `make dmg` from the repo root).
