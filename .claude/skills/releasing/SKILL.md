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

Watch CI checks and wait for the PR to be merged.

```bash
gh pr checks --watch --fail-fast
```

- Once all checks pass, wait for the merge to complete
- If any check fails, report to the user and abort

### 4. Run Release workflow

Dispatch the Release workflow on the main branch.

```bash
gh workflow run release.yml --ref main
```

### 5. Wait for release

Identify the latest Release workflow run and watch it until completion.

```bash
gh run list --workflow=release.yml --limit 1 --json databaseId --jq '.[0].databaseId' | \cat
```

```bash
gh run watch <run-id> --exit-status
```

- If the run fails, report to the user
- On success, show the release URL

```bash
gh release list --limit 1 --json tagName,url --jq '.[0]' | \cat
```
