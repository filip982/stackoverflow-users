#!/bin/bash
# Fires on SubagentStop for reviewer-agent. Reads the hook JSON from stdin,
# inspects the reviewer's last output for the VERDICT line, and feeds the
# result back to the orchestrator via additionalContext so the loop continues
# (fix → re-review) without ending the turn.

INPUT=$(cat)

# Only act on the reviewer agent.
AGENT=$(echo "$INPUT" | jq -r '.agent_type // empty')
if [ "$AGENT" != "reviewer-agent" ]; then
  exit 0
fi

# Pull the reviewer's final text. Field name can vary by version; try common ones.
TEXT=$(echo "$INPUT" | jq -r '.last_message // .output // .transcript // empty')

if echo "$TEXT" | grep -q "VERDICT: APPROVED"; then
  cat <<'EOF'
{"hookSpecificOutput":{"additionalContext":"Reviewer APPROVED. Stop the loop for this task and report the summary."}}
EOF
  exit 0
fi

if echo "$TEXT" | grep -q "VERDICT: CHANGES_REQUESTED"; then
  BLOCKERS=$(echo "$TEXT" | sed -n '/BLOCKERS:/,/VERDICT:/p')
  ESCAPED=$(printf '%s' "$BLOCKERS" | jq -Rs .)
  cat <<EOF
{"hookSpecificOutput":{"additionalContext":"Reviewer requested changes. Re-delegate to the SAME worker to fix ONLY these blockers, then re-review:\n${ESCAPED}"}}
EOF
  exit 0
fi

# No parsable verdict — nudge the orchestrator rather than silently passing.
echo '{"hookSpecificOutput":{"additionalContext":"Reviewer produced no VERDICT line. Ask it to re-review and emit a VERDICT."}}'
exit 0
