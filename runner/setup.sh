#!/bin/bash
# Install GitHub Actions self-hosted runner for DSH review
#
# Usage: bash setup.sh
#
# Requires:
#   - A GitHub personal access token (classic) with `repo` and `manage_runners` scopes,
#     or an organization-level runner registration token from:
#     https://github.com/organizations/<org>/settings/actions/runners/new
#     (for org-level) or https://github.com/<owner>/<repo>/settings/actions/runners/new (for repo-level).
#
# Set these env vars before running:
#   GITHUB_RUNNER_TOKEN  — runner registration token (required)
#   GITHUB_REPO_URL      — e.g. https://github.com/inclusionAI/Avernet (required)
#   RUNNER_LABELS        — comma-separated labels, default "dsh-review"
#   RUNNER_NAME          — display name, default "dsh-review-$(hostname)"

set -euo pipefail

: "${GITHUB_RUNNER_TOKEN:?required}"
: "${GITHUB_REPO_URL:?required}"

RUNNER_LABELS="${RUNNER_LABELS:-deepseek-runner}"
RUNNER_NAME="${RUNNER_NAME:-deepseek-runner-$(hostname)}"
RUNNER_DIR="${HOME}/actions-runner"

RUNNER_VERSION="2.337.0"
RUNNER_TAR="actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz"
RUNNER_URL="https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/${RUNNER_TAR}"

echo "=== Installing self-hosted runner ==="
echo "  Repo:     ${GITHUB_REPO_URL}"
echo "  Labels:   ${RUNNER_LABELS}"
echo "  Name:     ${RUNNER_NAME}"
echo "  Dir:      ${RUNNER_DIR}"

# ---- Download ----
if [ ! -f "/tmp/${RUNNER_TAR}" ]; then
  echo "Downloading runner agent v${RUNNER_VERSION}..."
  curl -sSfLo "/tmp/${RUNNER_TAR}" "${RUNNER_URL}"
fi

mkdir -p "${RUNNER_DIR}"
cd "${RUNNER_DIR}"

# Remove old installation if present
if [ -f "./config.sh" ]; then
  echo "Removing previous runner registration..."
  sudo ./svc.sh stop 2>/dev/null || true
  sudo ./svc.sh uninstall 2>/dev/null || true
  ./config.sh remove --token "${GITHUB_RUNNER_TOKEN}" 2>/dev/null || true
  rm -rf ./*
fi

tar xzf "/tmp/${RUNNER_TAR}"

# ---- Configure ----
echo "Configuring runner..."
./config.sh \
  --url "${GITHUB_REPO_URL}" \
  --token "${GITHUB_RUNNER_TOKEN}" \
  --name "${RUNNER_NAME}" \
  --labels "${RUNNER_LABELS}" \
  --unattended \
  --replace

# ---- Install as systemd service ----
echo "Installing as systemd service..."
sudo ./svc.sh install
sudo ./svc.sh start

echo ""
echo "=== Done ==="
echo "Runner '${RUNNER_NAME}' is running as a systemd service."
echo "Check status:  sudo ./svc.sh status"
echo "View logs:     journalctl -u actions.runner.* -f"