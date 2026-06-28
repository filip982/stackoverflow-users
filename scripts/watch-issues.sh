#!/usr/bin/env bash
set -euo pipefail

REPO="filip982/stackoverflow-users"
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
POLL_INTERVAL=30
TRIGGER_LABEL="ready-for-implementation"
IN_PROGRESS_LABEL="in-progress"

# ── Usage ────────────────────────────────────────────────────────────────────
# ./watch-issues.sh          Watch for labeled issues and run tech-lead-agent
# ./watch-issues.sh pm       Run pm-agent once to groom backlog and queue work
# ─────────────────────────────────────────────────────────────────────────────

run_pm() {
  echo "🧠  Running pm-agent — grooming backlog..."
  echo ""
  cd "$REPO_DIR"
  claude --agent pm-agent \
    --allowedTools "Bash(gh issue:*),Bash(gh pr:*),Bash(git log:*),Bash(git diff:*),Read,Glob,Grep" \
    -p "Review the current project state and groom the backlog.

1. Read docs/architecture.md and docs/PROJECT_SPEC.md for the full roadmap.
2. Check open and closed issues on GitHub to understand what is done, in-progress, and not started.
3. Check open PRs to see what is in review.
4. Create or update any issues that are missing or poorly scoped.
5. Label the next unblocked issue(s) as 'ready-for-implementation' if appropriate.
6. Report: what you did, what's now queued, and what's blocked and why.

Repo: $REPO"
  echo ""
  echo "✅  pm-agent done"
}

run_tech_lead() {
  local NUM="$1"
  local TITLE="$2"
  local BODY="$3"

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🚀  Issue #$NUM: $TITLE"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  # Swap label immediately so we don't pick it up again on next poll
  gh issue edit "$NUM" \
    --repo "$REPO" \
    --remove-label "$TRIGGER_LABEL" \
    --add-label "$IN_PROGRESS_LABEL" 2>/dev/null && \
    echo "🏷   Label → in-progress" || \
    echo "⚠️   Could not swap label (continuing anyway)"

  cd "$REPO_DIR"
  git fetch origin develop --quiet
  git checkout develop --quiet
  git pull origin develop --quiet

  claude --agent tech-lead-agent \
    --allowedTools "Bash(git checkout:*),Bash(git push:*),Bash(git add:*),Bash(git commit:*),Bash(gh issue:*),Bash(gh pr create:*),Bash(gh pr comment:*),Bash(gh pr view:*),Bash(git diff:*),Bash(git log:*),Read,Write,Edit,Glob,Grep,Agent" \
    -p "You are the tech lead for the StackOverflow Users iOS app.

Implement the following GitHub issue end-to-end.

Issue number: #$NUM
Issue title: $TITLE
Issue body:
$BODY

Instructions:
1. Read docs/architecture.md and docs/PROJECT_SPEC.md for full context.
2. Check project memory for patterns that caused review failures on previous features.
3. Follow the tech-lead workflow defined in .claude/agents/tech-lead-agent.md exactly.
4. Create a feature branch from develop.
5. Delegate implementation to worker agents in dependency order.
6. When implementation is complete, open a PR targeting develop with 'Closes #$NUM' in the body and request review from filip982.
7. Monitor the PR for VERDICT comments. Address CHANGES_REQUESTED by delegating fixes to the relevant worker.
8. When VERDICT: APPROVED, post a summary comment on the PR and on issue #$NUM.

Work in: $REPO_DIR (already on develop branch)."

  echo ""
  echo "✅  Tech lead finished for issue #$NUM"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
}

# ── PM mode ──────────────────────────────────────────────────────────────────
if [ "${1:-}" = "pm" ]; then
  run_pm
  exit 0
fi

# ── Watcher mode ─────────────────────────────────────────────────────────────
echo "👀  Watching $REPO for issues labeled '$TRIGGER_LABEL'"
echo "    Repo: $REPO_DIR"
echo "    Polling every ${POLL_INTERVAL}s — Ctrl+C to stop"
echo "    Tip: run './scripts/watch-issues.sh pm' to groom the backlog"
echo ""

while true; do
  ISSUE=$(gh issue list \
    --repo "$REPO" \
    --label "$TRIGGER_LABEL" \
    --state open \
    --json number,title,body \
    --jq '.[0] // empty' 2>/dev/null)

  if [ -n "$ISSUE" ]; then
    NUM=$(echo "$ISSUE" | jq -r '.number')
    TITLE=$(echo "$ISSUE" | jq -r '.title')
    BODY=$(echo "$ISSUE" | jq -r '.body')
    run_tech_lead "$NUM" "$TITLE" "$BODY"
  fi

  sleep "$POLL_INTERVAL"
done
