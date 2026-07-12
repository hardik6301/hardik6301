#!/usr/bin/env bash
# Publish hardik6301 profile + create/push portfolio and dsa-java.
# Requires auth as GitHub user hardik6301 (SSH host alias recommended).
set -euo pipefail

PROFILE_DIR="${PROFILE_DIR:-/Users/hardik/Desktop/hardik6301}"
PORTFOLIO_DIR="${PORTFOLIO_DIR:-/Users/hardik/Desktop/portfolio}"
DSA_DIR="${DSA_DIR:-/Users/hardik/Desktop/dsa-java}"
GH_USER="hardik6301"
SSH_HOST="${SSH_HOST:-github.com-hardik6301}"
export GIT_SSH_COMMAND="${GIT_SSH_COMMAND:-ssh -o StrictHostKeyChecking=accept-new}"

die() { echo "error: $*" >&2; exit 1; }

require_dir() {
  [[ -d "$1/.git" ]] || die "not a git repo: $1"
}

echo "==> Checking SSH identity (must be ${GH_USER})"
ssh_out="$(ssh -T "git@${SSH_HOST}" 2>&1 || true)"
echo "$ssh_out"
if echo "$ssh_out" | grep -qi "Hi ${GH_USER}!"; then
  echo "SSH OK as ${GH_USER}"
elif echo "$ssh_out" | grep -qiE 'Hi [^!]+!'; then
  die "SSH is authenticated as a different user. Switch to ${GH_USER} before publishing."
else
  echo "warning: could not confirm SSH user; continuing (gh may still work)"
fi

require_dir "$PROFILE_DIR"
require_dir "$PORTFOLIO_DIR"
require_dir "$DSA_DIR"

echo ""
echo "==> Pushing profile: ${GH_USER}/${GH_USER}"
git -C "$PROFILE_DIR" push "git@${SSH_HOST}:${GH_USER}/${GH_USER}.git" main
echo "Profile: https://github.com/${GH_USER}/${GH_USER}"

create_and_push() {
  local name="$1"
  local dir="$2"
  local url="https://github.com/${GH_USER}/${name}"

  echo ""
  echo "==> Publishing ${name} from ${dir}"

  if command -v gh >/dev/null 2>&1; then
    if gh repo view "${GH_USER}/${name}" >/dev/null 2>&1; then
      echo "Repo already exists: ${url}"
      git -C "$dir" remote remove origin 2>/dev/null || true
      git -C "$dir" remote add origin "git@${SSH_HOST}:${GH_USER}/${name}.git"
      git -C "$dir" push -u origin main
    else
      gh repo create "${GH_USER}/${name}" --public --source="$dir" --remote=origin --push
    fi
  else
    echo "gh not found — create the empty public repo on GitHub, then push:"
    echo ""
    echo "  # 1) Open: https://github.com/new"
    echo "     Owner: ${GH_USER}  Name: ${name}  Visibility: Public"
    echo "     Do NOT add README / .gitignore / license"
    echo ""
    echo "  # 2) Push:"
    echo "  git -C ${dir} remote remove origin 2>/dev/null || true"
    echo "  git -C ${dir} remote add origin git@${SSH_HOST}:${GH_USER}/${name}.git"
    echo "  git -C ${dir} push -u origin main"
    echo ""
    git -C "$dir" remote remove origin 2>/dev/null || true
    git -C "$dir" remote add origin "git@${SSH_HOST}:${GH_USER}/${name}.git"
    if git -C "$dir" push -u origin main; then
      echo "Pushed ${name}: ${url}"
    else
      echo "Push for ${name} failed (repo missing or no access). Use the manual steps above."
      return 1
    fi
  fi
  echo "${name}: ${url}"
}

create_and_push portfolio "$PORTFOLIO_DIR"
create_and_push dsa-java "$DSA_DIR"

echo ""
echo "Done."
echo "  Profile:   https://github.com/${GH_USER}/${GH_USER}"
echo "  Portfolio: https://github.com/${GH_USER}/portfolio"
echo "  DSA Java:  https://github.com/${GH_USER}/dsa-java"
