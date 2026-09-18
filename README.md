# GitHub Review Host

Self-hosted GitHub Actions runner for DSH-powered PR code review.

## Architecture

```
GitHub PR comment "@deepseekReviewer review"
  → GitHub Actions workflow (issue_comment trigger)
    → Picked up by self-hosted runner (label: dsh-review)
      → dsh --profile headless reviews the PR with full context
        → Posts findings as a PR review comment
```

## Setup

### 1. Install the self-hosted runner

Copy `runner/setup.sh` to your cloud server and run it:

```bash
bash runner/setup.sh
```

The script downloads the GitHub Actions runner agent, registers it with the
`dsh-review` label, and installs it as a systemd service.

### 2. Install DSH on the runner

```bash
# Install DSH CLI (the headless profile is used for review)
npm install -g dsh
```

### 3. Configure secrets

Add these in your repo's `Settings → Secrets and variables → Actions`:

| Secret | Description |
|---|---|
| `DEEPSEEK_API_KEY` | DeepSeek API key for code review |

### 4. Add the workflow to your target repo

Copy `.github/workflows/dsh-review.yml` into any repo you want to review.
The workflow triggers on `issue_comment` events containing
`@deepseekReviewer review`.

## Usage

Comment on any PR in the configured repo:

```
@deepseekReviewer review
```

The self-hosted runner picks up the job, DSH checks out the PR, reads all
changed files with full context, and posts a review comment.