#!/usr/bin/env bash
# AgentDecoy repo check: finds committed secrets and AI tool configs in the checked-out repo.
# Prints GitHub annotations, never the full secret. Exit code 1 when something is found and FAIL=true.
set -uo pipefail
cd "${GITHUB_WORKSPACE:-.}"
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then echo "::warning::AgentDecoy repo check: not a git checkout (add actions/checkout first). Skipped."; echo "repo-findings=0" >> "${GITHUB_OUTPUT:-/dev/null}"; exit 0; fi

found=0
LV=error; [ "${FAIL:-true}" = "true" ] || LV=warning
note() { found=$((found + 1)); echo "::$LV file=$1${2:+,line=$2}::$3"; }

# 1. Files that should never be in a repo.
while IFS= read -r f; do
  base=$(basename "$f")
  case "$f" in
    *.env.example|*.env.sample|*.env.template|*.env.dist|*.env.test) continue ;;
  esac
  case "$base" in
    .env|.env.*) note "$f" "" "Committed .env file. Scanners read public repos within seconds: a fake OpenAI key in a public repo was used 15 seconds after going public (simgen.dev/agentdecoy/leak-clock). Remove it, add .env to .gitignore and rotate every key it held." ;;
    id_rsa|id_ed25519|*.pem|*.p12|*.pfx) note "$f" "" "Private key file committed. Remove it and replace the key." ;;
  esac
  case "$f" in
    .cursor/mcp.json|.mcp.json|.vscode/mcp.json|.claude/settings.local.json|*claude_desktop_config.json)
      if grep -qiE '(authorization|bearer|api[_-]?key|token|secret)' "$f" 2>/dev/null; then note "$f" "" "AI tool config with credentials committed. MCP and agent configs are now asked for by name. Move the token to an environment variable and rotate it."; fi ;;
  esac
done < <(git ls-files)

# 2. Key formats inside tracked text files (skips lock files, vendored and built code, files over 1 MB).
patterns='sk-proj-[A-Za-z0-9_-]{20,}|sk-ant-(api|admin)[0-9]{2}-[A-Za-z0-9_-]{20,}|AKIA[0-9A-Z]{16}|sk_live_[0-9A-Za-z]{20,}|rk_live_[0-9A-Za-z]{20,}|ghp_[A-Za-z0-9]{36}|github_pat_[A-Za-z0-9_]{40,}|xox[baprs]-[A-Za-z0-9-]{10,}|AIza[0-9A-Za-z_-]{35}'
git ls-files -z | while IFS= read -r -d '' f; do
  case "$f" in *node_modules/*|*dist/*|*build/*|*.min.js|*package-lock.json|*yarn.lock|*pnpm-lock.yaml|*.map) continue ;; esac
  [ -f "$f" ] || continue
  [ "$(wc -c < "$f")" -gt 1048576 ] && continue
  grep -nIoE "$patterns" "$f" 2>/dev/null | while IFS=: read -r line match; do
    kind="secret key"
    case "$match" in sk-proj-*) kind="OpenAI key";; sk-ant-*) kind="Anthropic key";; AKIA*) kind="AWS key";; sk_live_*|rk_live_*) kind="Stripe live key";; ghp_*|github_pat_*) kind="GitHub token";; xox*) kind="Slack token";; AIza*) kind="Google API key";; esac
    echo "::$LV file=$f,line=$line::$kind committed (${match:0:8}...). Leaked AI keys get tested within seconds of a public push. Rotate it and load it from a secret instead."
    echo x >> /tmp/agentdecoy-repo-hits
  done
done
extra=$( [ -f /tmp/agentdecoy-repo-hits ] && wc -l < /tmp/agentdecoy-repo-hits || echo 0 ); rm -f /tmp/agentdecoy-repo-hits
total=$((found + extra))
echo "repo-findings=$total" >> "${GITHUB_OUTPUT:-/dev/null}"
if [ "$total" -gt 0 ]; then
  echo "AgentDecoy repo check: $total problem(s) found."
  [ "${FAIL:-true}" = "true" ] && exit 1
else
  echo "AgentDecoy repo check: no committed secrets or AI tool credentials found."
fi
exit 0
