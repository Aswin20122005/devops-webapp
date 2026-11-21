# DevOps CI/CD Demo 🚀

[![CI Pipeline](https://github.com/Aswin20122005/devops-webapp/actions/workflows/ci.yml/badge.svg)](https://github.com/Aswin20122005/devops-webapp/actions/workflows/ci.yml)
[![Deploy](https://github.com/Aswin20122005/devops-webapp/actions/workflows/deploy.yml/badge.svg)](https://github.com/Aswin20122005/devops-webapp/actions/workflows/deploy.yml)

A small static website used to demonstrate a complete CI/CD pipeline: linting, a hardened container image, automated smoke tests, vulnerability scanning, deployment, and Slack notifications.

## Pipeline

```
push / pull request
      │
      ▼
┌──────────┐   ┌──────────────────────────────┐   ┌────────┐
│   lint   │──▶│            build             │──▶│ notify │  (always runs)
│ html     │   │ docker build                 │   │ Slack  │
│ hadolint │   │ run container                │   └────────┘
│shellcheck│   │ smoke tests (13 checks)      │
└──────────┘   │ wait for HEALTHCHECK         │
               │ Trivy scan (HIGH/CRITICAL)   │
               └──────────────────────────────┘

push to main ──▶ deploy.yml ──▶ GitHub Container Registry (latest + sha tags)
                            └─▶ GitHub Pages (when enabled)
```

| Stage | Tooling | Fails the build when… |
| --- | --- | --- |
| Lint | `html-validate`, `hadolint`, `shellcheck` | invalid HTML, Dockerfile or script issues |
| Build | Docker | the image doesn't build |
| Test | `tests/smoke.sh` + Docker `HEALTHCHECK` | a page, header, 404, gzip or cache check fails, or the container never becomes healthy |
| Scan | Trivy | a fixable HIGH/CRITICAL vulnerability is found |
| Notify | Slack webhook | never; it reports success *and* failure |

## Container

- `nginxinc/nginx-unprivileged:mainline-alpine` running as **uid 101**, on port **8080**
- `apk upgrade` at build time, so Alpine security fixes are applied between base-image releases
- Security headers on every response: strict **Content-Security-Policy** (the 404 page's inline style is allowed by hash), `X-Frame-Options`, `nosniff`, `Referrer-Policy`, `Permissions-Policy`; nginx version hidden
- gzip for text assets and a 7-day cache for CSS/JS/SVG
- `/healthz` liveness endpoint used by the Docker `HEALTHCHECK`
- `/version.json` with the commit and build time, also shown in the page footer
- `docker-compose.yml` runs it with a read-only filesystem and `no-new-privileges`

## Run locally

```bash
docker compose up --build        # http://localhost:8080
# or
make run && make test            # build, start and smoke-test
make lint                        # same linters as CI
```

## Deployment

- **Container image:** every push to `main` publishes `ghcr.io/aswin20122005/devops-webapp:latest` and a `sha-<commit>` tag.
- **GitHub Pages:** enable Pages in *Settings → Pages → Source: GitHub Actions*, then add a repository variable `PAGES_ENABLED=true`. Until then the Pages job is skipped instead of failing.
- **Slack:** add a `SLACK_WEBHOOK` repository secret. Without it, the notify step is skipped.

Dependabot keeps the GitHub Actions and the nginx base image up to date.

## What the history shows

The commit history records issues the pipeline caught while it was being built:

- the Slack step failed every build when the secret wasn't set
- `add_header` in an nginx `location` silently dropped all security headers for CSS and SVG files
- the non-root image couldn't write `version.json` (`Permission denied` in the publish job)
- Trivy found **68 HIGH/CRITICAL CVEs** in the old `1.27-alpine` base, then 6 remaining in nginx itself; fixed with `apk upgrade` and the mainline image

## Project structure

```
├── index.html, 404.html, favicon.svg
├── css/style.css
├── js/version.js            # shows the running commit
├── nginx/
│   ├── default.conf         # server config, caching, /healthz
│   └── security-headers.conf
├── Dockerfile
├── docker-compose.yml
├── Makefile
├── tests/smoke.sh           # HTTP smoke tests
└── .github/
    ├── workflows/ci.yml     # lint → build/test/scan → notify
    ├── workflows/deploy.yml # GHCR + GitHub Pages
    └── dependabot.yml
```
