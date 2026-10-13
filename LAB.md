# Trunk-Based Development Lab — step by step

Do the labs **in order**. Every lab says **what it is like at work** and **what to say in an interview**.
Read the PDF guide (`docs/Git-GitHub-Trunk-Based-Guide.pdf`) next to this file. It has the diagrams.

> **The trunk** = the `main` branch. Everybody merges small changes into it **at least once a day**.
> Every commit on `main` must be **ready to deploy to production**.

---

## Lab 0 — Put the project on GitHub and set it up like a company

```bash
cd ~/wezva-ai-driven-bootcamp/git-github/luul-trunk-lab
git init -b main
git add .
git commit -m "chore: initial project"

gh repo create luul-trunk-lab --public --source=. --push   # create repo on GitHub and push
./scripts/setup-github.sh abdihakim-said/luul-trunk-lab    # squash-merge only, environments, protect main
```

Now open GitHub → **Settings** and look at:
- **Branches**: `main` is protected. You need a PR, and CI must pass.
- **Environments**: `prod` needs your approval.
- **General → Pull Requests**: only "Squash merge" is allowed, and branches are deleted after merge.

**At work:** the platform team sets this up once for every repo, often with Terraform (`github` provider) or org-wide **rulesets**.
**Interview:** *"I protect main with required status checks, required reviews, linear history and no force-push, and I use environments with required reviewers for production."*

---

## Lab 1 — Your first trunk-based change (the daily loop)

```bash
git switch main && git pull                  # 1. always start from the latest trunk
git switch -c feat/add-version-docs          # 2. short-lived branch (hours, not weeks)
echo "- GET /version shows the running commit" >> README.md
git add README.md
git commit -m "docs: document /version endpoint"
git push -u origin feat/add-version-docs     # 3. push
gh pr create --fill                          # 4. open a pull request
gh pr checks --watch                         # 5. watch CI run
gh pr merge --squash                         # 6. squash merge into trunk
git switch main && git pull                  # 7. update local main
```

Go to the **Actions** tab. Merging started the **CD** pipeline: build → dev → staging → **waits for your approval** → prod. Click **Review deployments** → approve.

**Interview:** *"We use trunk-based development. I make a short-lived branch, open a small PR, CI runs tests and builds the image, a teammate reviews, we squash-merge, and CD promotes the same image from dev to staging to prod with an approval gate."*

---

## Lab 2 — CI protects the trunk (break it on purpose)

```bash
git switch main && git pull
git switch -c fix/greeting-text
```
Edit `app/main.py` and change `"Hello from Luul Solutions"` to `"Hi"`. **Do not** change the test.
```bash
git commit -am "fix: shorter greeting"
git push -u origin fix/greeting-text
gh pr create --fill
gh pr checks --watch        # ❌ fails
```
Try to merge: GitHub **blocks** it. That is branch protection working.
```bash
gh pr merge --squash
# To use administrator privileges to immediately merge the pull request, add the `--admin` flag.
```
⚠️ **Never use `--admin` to skip a red check.** It's the emergency (break-glass) option, and at a company every use is visible in the audit log.

Fix it: put the text back (or update the test too), then:
```bash
git commit -am "fix: keep test and text in sync"
git push                    # ✅ CI goes green, now you can merge
```

**Interview:** *"Because everyone commits to trunk, a broken main blocks the whole team. Required CI checks are the safety net that makes trunk-based development possible."*

---

## Lab 3 — Feature flags: merge unfinished work safely ⭐ (most important trunk idea)

The feature is "new greeting". It is not ready for customers, but in trunk-based development you **still merge it today**. It stays hidden behind a flag.

1. Look at `config/flags.json`: `"new_greeting": false`.
2. Run the app:
   ```bash
   make run                                 # in another terminal: curl localhost:8080/
   FLAG_NEW_GREETING=true make run          # same code, feature ON
   ```
3. The code for both greetings is already on `main`. The flag decides which one users see.
4. Release the feature to everybody with a one-line PR:
   ```bash
   git switch -c feat/enable-new-greeting
   sed -i '' 's/false/true/' config/flags.json     # on Linux: sed -i 's/false/true/'
   git commit -am "feat: enable new greeting for all users"
   git push -u origin feat/enable-new-greeting && gh pr create --fill
   ```
5. Something wrong? Turn the flag back off. You don't need to roll back the code.

**At work:** flags come from tools like LaunchDarkly, Unleash, Flagsmith or AWS AppConfig, or from config per environment (see `k8s/deployment.yaml`, `FLAG_NEW_GREETING`).
**Interview:** *"Deploy is not the same as release. We deploy code dark behind a feature flag, then release by turning the flag on, first for dev, then for a few users, then for everyone. Later we delete the old code path and the flag, so flags don't become technical debt."*

---

## Lab 4 — Keep your branch fresh with rebase

You simulate a teammate merging to main while you work.

```bash
git switch main && git pull
git switch -c feat/my-work
echo "my work" > notes.txt && git add . && git commit -m "feat: add notes"
git push -u origin feat/my-work           # your branch is on GitHub now

# --- teammate's change (we do it straight on GitHub) ---
gh api -X PUT repos/:owner/:repo/contents/TEAMMATE.md \
  -f message="docs: teammate change" -f content="$(echo 'hi' | base64)" \
  -f branch=main 2>/dev/null || echo "main is protected: make the change with a PR in the GitHub web UI instead"

git fetch origin
git log --oneline --graph --all -10       # see the two lines of history
git rebase origin/main                    # replay MY commits on top of latest main
git log --oneline --graph -5              # now it's one straight line
git push --force-with-lease               # safe force-push of MY branch only
```

**Rule:** rebase **your own** branch, but never rebase or force-push `main`.
**Interview:** *"Merge keeps history as it happened and adds a merge commit. Rebase rewrites my commits on top of main so the history is linear. In trunk-based development we rebase short branches often and squash-merge, so main stays a clean straight line."*

---

## Lab 5 — Merge conflict (you WILL see this at work)

```bash
git switch main && git pull
git switch -c conflict-a
sed -i '' 's/VERSION = "1.0.0"/VERSION = "1.1.0"/' app/main.py
git commit -am "chore: bump to 1.1.0"

git switch main
git switch -c conflict-b
sed -i '' 's/VERSION = "1.0.0"/VERSION = "2.0.0"/' app/main.py
git commit -am "chore: bump to 2.0.0"

git merge conflict-a          # ❌ CONFLICT
git status                    # shows "both modified: app/main.py"
```
Open `app/main.py` and you will see:
```
<<<<<<< HEAD
VERSION = "2.0.0"
=======
VERSION = "1.1.0"
>>>>>>> conflict-a
```
Keep the correct line and **delete the 3 marker lines**, then:
```bash
git add app/main.py
git commit                    # finish the merge
make test
git switch main && git branch -D conflict-a conflict-b   # clean up (practice only)
```
To give up in the middle of a merge: `git merge --abort`. During a rebase: `git rebase --abort`.

**Interview:** *"Trunk-based development reduces conflicts because branches live for hours, not weeks. When one happens, I check with the other author, resolve it, run tests locally, and push."*

---

## Lab 6 — Production is broken: ROLL BACK with `git revert`

```bash
git switch main && git pull
git switch -c feat/risky
echo 'raise SystemExit("boom")' >> app/main.py      # a "bad" change
git commit -am "feat: risky change"
```
Imagine this got merged and deployed. **Roll back**:
```bash
git log --oneline -3                 # find the bad commit id, e.g. a1b2c3d
git revert a1b2c3d                   # NEW commit that undoes it (history kept)
git log --oneline -3
```
At work you then push the revert in a PR → CI → CD deploys the fixed version. You can also re-run the **CD** workflow for an older good commit (each image is tagged with its SHA).

Clean up: `git switch main && git branch -D feat/risky`

**Interview:** *"On a shared branch I use `git revert`, never `git reset`, because revert doesn't rewrite history. Our options are: turn off the feature flag (fastest), redeploy the previous image tag, or revert the commit and let CD ship it. Then we write a blameless postmortem."*

---

## Lab 7 — Hotfix in trunk-based: fix forward

In GitFlow you would make a `hotfix/*` branch from a release branch. In trunk-based development **a hotfix is just a normal, very small PR to main**:

```bash
git switch main && git pull
git switch -c hotfix/404-message
sed -i '' 's/"not found"/"path not found"/' app/main.py   # the tiny fix
make test
git commit -am "fix: clearer 404 message"
git push -u origin hotfix/404-message && gh pr create --fill
gh pr checks --watch
gh pr merge --squash      # CD ships it the same way as every other change
```

**Interview:** *"The pipeline is our only path to production, including for hotfixes. It's fast because changes are small, so we fix forward through the same pipeline instead of making a special branch."*

---

## Lab 8 — Releases: tags (and release branches only when needed)

```bash
git switch main && git pull
git tag -a v1.0.0 -m "Release 1.0.0"
git push origin v1.0.0                 # the Release workflow creates a GitHub Release with notes
gh release view v1.0.0
```

**Semantic versioning:** `MAJOR.MINOR.PATCH`. MAJOR = breaking change, MINOR = new feature, PATCH = bug fix.

**Release branch (optional, for mobile apps or products customers install):**
```bash
git switch -c release/1.0 v1.0.0       # cut from trunk, never merged back
git push -u origin release/1.0

# 1. A bug is fixed on MAIN first (normal PR):
git switch main && git switch -c fix/version-endpoint
sed -i '' 's/{"version": VERSION,/{"app": "luul-trunk-lab", "version": VERSION,/' app/main.py
make test && git commit -am "fix: show app name in /version"
git push -u origin fix/version-endpoint && gh pr create --fill
gh pr checks --watch && gh pr merge --squash
git switch main && git pull
git log --oneline -1                   # copy this commit id, e.g. 9f8e7d6

# 2. Copy that fix into the release branch:
git switch release/1.0
git cherry-pick 9f8e7d6                # use YOUR id from the line above
git push
git tag -a v1.0.1 -m "Release 1.0.1" && git push origin v1.0.1
```
**Rule:** fix on **trunk first**, then cherry-pick to the release branch. Never develop on the release branch.

**Interview:** *"For web services we release straight from trunk with tags. If we must support an old version, we cut a release branch from trunk and cherry-pick fixes from main into it. Fixes always land on trunk first."*

---

## Lab 9 — Context switch with `git stash`

```bash
git switch -c feat/half-done
echo "half done" >> README.md          # unfinished, don't want to commit
git stash push -m "half done readme"   # put it aside
git switch main                        # urgent work...
git switch feat/half-done
git stash list
git stash pop                          # bring the work back
```

---

## Lab 10 — "I lost my commits!" → `git reflog`

```bash
git switch -c feat/oops
echo "important" > important.txt && git add . && git commit -m "feat: important work"
git reset --hard HEAD~1                # 😱 commit gone
git reflog                             # every place HEAD has been
git reset --hard HEAD@{1}              # ✅ back
```

**Interview:** *"reflog is Git's safety net. It records every move of HEAD locally, so I can recover commits after a bad reset or rebase."*

---

## Lab 11 — GitOps: deploy by changing Git

Open `k8s/deployment.yaml`. In a GitOps company:
1. CD builds `ghcr.io/<owner>/luul-trunk-lab:<sha>`.
2. A PR (often automatic) changes `image:` to that new tag in a **config repo**.
3. **Argo CD / Flux** sees the change in Git and applies it to Kubernetes.
4. Rollback = `git revert` of that PR.

Practice: change the `image:` tag and `FLAG_NEW_GREETING` value in a PR, and explain in your own words what Argo CD would do.

**Interview:** *"Git is the single source of truth. Nobody runs kubectl apply by hand in prod. Every change is a reviewed, audited PR, and the cluster is pulled into the state that Git describes."*

---

## ✅ You are "trunk-based ready" when you can, without notes:
- [ ] Explain trunk-based vs GitFlow and why we chose trunk
- [ ] Do the daily loop (Lab 1) from memory
- [ ] Explain and demo a feature flag
- [ ] Resolve a conflict and rebase a branch
- [ ] Roll back with revert, and say the 3 rollback options
- [ ] Read and explain every line of `.github/workflows/ci.yml` and `cd.yml`
- [ ] Set up branch protection and environments
