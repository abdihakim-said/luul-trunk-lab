# luul-trunk-lab

A small practice project that shows **trunk-based development end to end**, the way a DevOps / Platform team runs it at a company:

`short-lived branch → Pull Request → CI checks → squash merge to main → CD builds one image → dev → staging → (approval) → prod`

## What's inside

| Path | What it is |
|---|---|
| `app/main.py` | Tiny web service (`/`, `/health`, `/version`) with a **feature flag** |
| `config/flags.json` | Feature flags. Unfinished work merges to trunk but stays OFF |
| `tests/` | Unit tests (run with `make test`) |
| `Dockerfile` | Container image, non-root, with healthcheck |
| `.github/workflows/ci.yml` | Runs on every PR: lint, tests, docker build, smoke test, branch-age warning |
| `.github/workflows/cd.yml` | Runs on every merge to main: build & push to GHCR, deploy dev → staging → prod |
| `.github/workflows/release.yml` | Push a tag `v1.2.3` → GitHub Release with notes |
| `.github/CODEOWNERS` | Who must review what |
| `.github/pull_request_template.md` | Trunk-based PR checklist |
| `scripts/setup-github.sh` | One-time repo setup: squash-only, environments, branch protection |
| `k8s/deployment.yaml` | How it runs on Kubernetes / GitOps |
| `LAB.md` | **Start here.** 11 hands-on labs |
| `docs/Git-GitHub-Trunk-Based-Guide.pdf` | Guide with diagrams + interview Q&A |

## Quick start

```bash
make test       # run tests
make run        # http://localhost:8080
make build      # docker image tagged with the commit SHA
```

Then follow **LAB.md**.
- GET /version shows the running commit
- Practised by Abdihakim
