---
title: "Documentation Guide"
weight: 5
draft: false
---

# Documentation Guide  

## Overview

This repository powers the MR2 documentation website.  
We use **[Hugo](https://gohugo.io/)** — a fast static-site generator — to turn Markdown files into a fully rendered site that GitHub Pages deploys automatically.  
Follow the steps below to set up your local environment, add or edit content, preview changes, and contribute back via pull requests.

---

## Clone the Repository

```bash
git clone --recursive https://github.com/URC-kaist/urc-kaist.github.io.git
cd urc-kaist.github.io
```

> **Why `--recursive`?**  
> Themes and other third-party components live in Git submodules; the `--recursive` flag ensures they are fetched as well.

---

## Install Hugo

See the [official installation guide](https://gohugo.io/installation/). The site currently builds with Hugo **v0.125** or newer.

| Platform | Command |
|----------|---------|
| **macOS** | `brew install hugo` |
| **Ubuntu / Debian / WSL** | `sudo apt update && sudo apt install hugo` |
| **Windows** | `choco install hugo` (Chocolatey) or `scoop install hugo` (Scoop) |

Verify the installation:

```bash
hugo version
# Hugo Static Site Generator v0.125.x …
```

---

## Write & Organize Content

### Directory Layout

```text
content/
└── en/                 # English docs (optional namespace)
    ├── _index.md       # Section index
    ├── overview.md     # Regular page
    └── subtopic/
        ├── _index.md   # Sub-section index
        └── guide.md
```

* Every **`.md`** file becomes a page.  
* Folder hierarchy maps 1-to-1 to site URLs.  
* An **`_index.md`** at any level turns that folder into a list/landing page.

### Creating a New Page

1. Decide the folder path under `content/` (create folders if missing).  
2. Add a new `<name>.md` file.  
3. Paste the **front matter** (see below) and start writing in Markdown.  
4. Run `hugo server -D` to preview.

### Front Matter Template

```yaml
---
title: "Page Title"        # Displayed in menus & browser tabs
weight: 1                  # Lower = appears higher in side nav
draft: false               # true → excluded from production build
bookCollapseSection: true  # For _index.md: hide children by default
---
```

> **Tip:** Set `draft: true` while your page is WIP; Hugo includes drafts in `hugo server -D` preview but omits them from production deployments.

---

## Live Preview

```bash
hugo server -D
```

* Opens <http://localhost:1313/> with hot-reload.  
* `-D` includes draft pages; omit it to preview only publish-ready content.

---

## Build & Deploy

A GitHub Actions workflow (`.github/workflows/gh-pages.yml`) watches the **`main`** branch:

1. Push or merge PR → workflow builds the site.  
2. Static files are published to the **`gh-pages`** branch.  
3. GitHub Pages serves the latest build.

No extra steps are required once your changes reach `main`.

---

## Contribution Workflow (Quick-Start)

1. **Create a branch**

   ```bash
   git checkout -b docs/your-topic
   ```

2. **Write / edit content** and commit.  
3. **Preview locally** with `hugo server -D`; fix any warnings.  
4. **Push & open a Pull Request** targeting `main`.  
5. **Request review** – at least one maintainer must approve.  
6. **Merge** → GitHub Actions deploys automatically.

### Commit Message Style

```
docs(topic): short description

Longer body if necessary…
```

---

## Troubleshooting

| Symptom | Possible Cause / Fix |
|---------|----------------------|
| **404 for theme assets** | Submodules missing → `git submodule update --init --recursive` |
| **“Hugo version incompatible”** | Install newer Hugo (`brew upgrade hugo`, `choco upgrade hugo`, etc.) |
| **CSS/JS not updating** | Browser cache → hard-refresh / disable cache in dev tools |
| **Workflow fails on build** | Check front-matter syntax (unterminated `---`) or invalid shortcode |

---

## Additional Resources

* **Hugo Docs** – <https://gohugo.io/documentation/>  
* **Markdown Guide** – <https://www.markdownguide.org/basic-syntax>  
* **Theme Documentation** – see `themes/<theme-name>/README.md`  
* **GitHub Pages Guide** – <https://docs.github.com/pages>  

