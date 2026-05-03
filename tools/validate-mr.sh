#!/usr/bin/env bash
# validate-mr.sh — Brandon's MR pre-merge validation.
#
# Usage:
#   tools/validate-mr.sh <member-branch> [base=main]
#
# Checks: branch exists, ahead-of-base, linear history, FF-merge possible,
# diff stat, AC manual checklist prompt. Exits 0 on PASS, 1 on FAIL.
#
# AC item is operator-confirmed (no automation). Tests/lint are AIL-stack
# specific — stubbed until a runner exists.

set -u
shopt -s lastpipe 2>/dev/null || true

branch="${1:-}"
base="${2:-main}"

if [ -z "$branch" ]; then
  echo "usage: $0 <member-branch> [base=main]" >&2
  exit 2
fi

repo_root="$(git rev-parse --show-toplevel 2>/dev/null)"
if [ -z "$repo_root" ]; then
  echo "FAIL: not in a git repo" >&2
  exit 1
fi

pass=()
fail=()

note_pass() { pass+=("$1"); printf '  [PASS] %s\n' "$1"; }
note_fail() { fail+=("$1"); printf '  [FAIL] %s\n' "$1"; }

printf 'MR validation: %s -> %s\n' "$branch" "$base"
printf 'Repo: %s\n\n' "$repo_root"

# 1. Branch exists.
if git rev-parse --verify --quiet "refs/heads/$branch" >/dev/null; then
  branch_sha="$(git rev-parse "$branch")"
  note_pass "branch exists: $branch ($branch_sha)"
else
  note_fail "branch does not exist locally: $branch"
  printf '\nMR-VALIDATION: FAIL %s -> %s (no branch)\n' "$branch" "$base"
  exit 1
fi

# 2. Base exists.
if git rev-parse --verify --quiet "refs/heads/$base" >/dev/null; then
  base_sha="$(git rev-parse "$base")"
  note_pass "base exists: $base ($base_sha)"
else
  note_fail "base does not exist locally: $base"
  printf '\nMR-VALIDATION: FAIL %s -> %s (no base)\n' "$branch" "$base"
  exit 1
fi

# 3. Ahead-of-base (something to merge).
ahead="$(git rev-list --count "$base..$branch")"
behind="$(git rev-list --count "$branch..$base")"
if [ "$ahead" -gt 0 ]; then
  note_pass "ahead of $base by $ahead commit(s)"
else
  note_fail "branch has no commits ahead of $base — nothing to merge"
fi

# 4. Linear history (no merge commits in branch range).
merges="$(git rev-list --count --merges "$base..$branch")"
if [ "$merges" -eq 0 ]; then
  note_pass "linear history (no merge commits in $base..$branch)"
else
  note_fail "linear history violated — $merges merge commit(s) in range"
fi

# 5. FF-merge possible (base is ancestor of branch tip).
if git merge-base --is-ancestor "$base" "$branch"; then
  note_pass "fast-forward merge possible ($base is ancestor of $branch)"
else
  note_fail "fast-forward NOT possible — branch is behind $base by $behind. Rebase required."
fi

# 6. Working tree of branch worktree clean (if a worktree is checked out on it).
wt_path="$(git worktree list --porcelain | awk -v b="$branch" '
  /^worktree / { p=$2 }
  /^branch refs\/heads\// { sub("refs/heads/", "", $2); if ($2 == b) print p }
')"
if [ -n "$wt_path" ]; then
  dirty="$(git -C "$wt_path" status --porcelain | wc -l | tr -d ' ')"
  if [ "$dirty" -eq 0 ]; then
    note_pass "branch worktree clean: $wt_path"
  else
    note_fail "branch worktree dirty ($dirty entries): $wt_path — commit or stash before MR"
  fi
fi

# 7. Diff stat.
printf '\nDiff stat (%s..%s):\n' "$base" "$branch"
git --no-pager diff --stat "$base..$branch" | sed 's/^/  /'

# 8. Test/lint stub. AIL test runner not yet wired.
printf '\n[STUB] tests/lint: AIL runner integration TODO — operator must verify manually.\n'

# 9. AC checklist prompt.
printf '\nAC checklist (operator confirms):\n'
printf '  - Acceptance criteria from MR letter satisfied? [y/N] '
if [ -t 0 ]; then
  read -r ac_ans || ac_ans=""
else
  ac_ans="${MR_AC_OK:-}"
  printf '%s (from $MR_AC_OK)\n' "${ac_ans:-N}"
fi
case "$ac_ans" in
  y|Y|yes|YES) note_pass "AC operator-confirmed" ;;
  *)           note_fail "AC not confirmed (set MR_AC_OK=y for non-interactive PASS)" ;;
esac

# Verdict.
printf '\n----\n'
printf 'PASS: %s\nFAIL: %s\n' "${#pass[@]}" "${#fail[@]}"
if [ "${#fail[@]}" -eq 0 ]; then
  printf 'MR-VALIDATION: PASS %s -> %s (head=%s behind=0 ahead=%s)\n' \
    "$branch" "$base" "$branch_sha" "$ahead"
  exit 0
else
  printf 'MR-VALIDATION: FAIL %s -> %s (head=%s behind=%s ahead=%s; %s failure(s))\n' \
    "$branch" "$base" "$branch_sha" "$behind" "$ahead" "${#fail[@]}"
  exit 1
fi
