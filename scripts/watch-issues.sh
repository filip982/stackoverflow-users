#!/usr/bin/env bash
set -euo pipefail

REPO="filip982/stackoverflow-users"
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
POLL_INTERVAL=30
TRIGGER_LABEL="ready-for-implementation"
IN_PROGRESS_LABEL="in-progress"

echo "👀  Watching $REPO for issues labeled '$TRIGGER_LABEL'"
echo "    Repo: $REPO_DIR"
echo "    Polling every ${POLL_INTERVAL}s — Ctrl+C to stop"
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

    # Run Claude as orchestrator in this terminal
    cd "$REPO_DIR"
    git fetch origin develop --quiet
    git checkout develop --quiet
    git pull origin develop --quiet

    claude --allowedTools "Bash(git checkout:*),Bash(git push:*),Bash(git add:*),Bash(git commit:*),Bash(gh issue:*),Bash(gh pr create:*),Bash(gh pr comment:*),Read,Write,Edit,Glob,Grep,Agent" \
      -p "You are the orchestrator for the StackOverflow Users iOS app.

A GitHub issue has been labeled 'ready-for-implementation'. Your job is to implement it.

Issue number: #$NUM
Issue title: $TITLE
Issue body:
$BODY

Instructions:
1. Read docs/architecture.md and docs/PROJECT_SPEC.md for full context.
2. Follow the orchestrator workflow defined in .claude/agents/orchestrator.md exactly.
3. Create a feature branch from develop named after this issue (e.g. feature/user-list).
4. Delegate implementation to the appropriate worker agents in dependency order.
5. When implementation is complete, open a PR targeting develop with 'Closes #$NUM' in the body.
6. Post a comment on issue #$NUM with the PR URL and a summary of what was built.

Work in: $REPO_DIR (already on develop branch)."

    echo ""
    echo "✅  Orchestrator finished for issue #$NUM"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
  fi

  sleep "$POLL_INTERVAL"
done
