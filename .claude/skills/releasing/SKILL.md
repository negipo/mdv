---
name: releasing
description: End-to-end release flow — create PR, enable automerge, wait for merge, trigger Release workflow, and wait for completion. Use when the user says things like "release", "merge and release", "deploy", "ship it", etc.
---

Execute the full flow from PR creation through release completion.
Each step waits for the previous step to finish before proceeding.

## Steps

### 1. Create PR

Create a pull request. Skip this step if one already exists for the current branch.

### 2. Enable automerge

Mark the PR as ready if it is a draft, then enable automerge with squash.

```bash
gh pr ready
gh pr merge --auto --squash
```

### 3. Wait for merge

Watch CI checks and wait for the PR to be merged. Automerge handles the merge automatically — do not run `gh pr merge` manually.

```bash
gh pr checks --watch --fail-fast
```

- Once all checks pass, automerge will merge the PR
- If any check fails, report to the user and abort

### 4. Run Release workflow

Dispatch the Release workflow on the main branch. The command outputs the run URL which contains the run ID — use it directly in the next step without querying `gh run list`.

```bash
gh workflow run release.yml --ref main
```

### 5. Wait for release

Watch the workflow run using the run ID from step 4's output.

```bash
gh run watch <run-id> --exit-status
```

- If the run fails, report to the user
- On success, show the release tag and name

```bash
gh release list --limit 1 --json tagName,name --jq '.[0]' | \cat
```
