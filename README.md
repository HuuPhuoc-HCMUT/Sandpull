# Sandpull website

Marketing site for the Mac app. Same teal / sand / glass language as Sandpull. The pull gesture is inspired by Gestimer.

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

Live site: [https://huuphuoc-hcmut.github.io/Sandpull/](https://huuphuoc-hcmut.github.io/Sandpull/) (the `gh-pages` branch is this folder).

Download file: `website/downloads/Sandpull.dmg` (built with `make dmg` from the repo root).
