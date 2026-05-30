#!/usr/bin/env bash
# Bump PINGSWEEP_VERSION in pingsweep using conventional commits since the last tag.
#
# Semver rules (highest matching bump wins):
#   major - BREAKING CHANGE footer or type! scope (e.g. feat!:)
#   minor - feat:
#   patch - fix:, perf:, refactor:, revert:, or any other non-release commit
#
# Outputs (for GitHub Actions):
#   bumped=true|false
#   version=X.Y.Z
#   tag=vX.Y.Z

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$ROOT/pingsweep"

current_version() {
  grep -m1 '^PINGSWEEP_VERSION=' "$SCRIPT" | sed -E 's/^PINGSWEEP_VERSION="([^"]+)".*/\1/'
}

set_version() {
  local version="$1"
  sed -i.bak -E "s/^PINGSWEEP_VERSION=\"[^\"]+\"/PINGSWEEP_VERSION=\"${version}\"/" "$SCRIPT"
  rm -f "${SCRIPT}.bak"
}

CURRENT="$(current_version)"
LAST_TAG="$(git -C "$ROOT" describe --tags --abbrev=0 --match 'v*' 2>/dev/null || true)"

if [[ -z "$LAST_TAG" ]]; then
  {
    echo "bumped=false"
    echo "version=${CURRENT}"
    echo "tag=v${CURRENT}"
    echo "action=initial_tag"
  }
  echo "No release tag found; tag v${CURRENT} without changing the script." >&2
  exit 0
fi

BASE_VERSION="${LAST_TAG#v}"
COMMITS="$(git -C "$ROOT" log "${LAST_TAG}..HEAD" --pretty=format:%s --no-merges \
  | grep -Ev '^chore\(release\):' || true)"

if [[ -z "$COMMITS" ]]; then
  {
    echo "bumped=false"
    echo "version=${CURRENT}"
    echo "tag=v${CURRENT}"
    echo "action=none"
  }
  echo "No releasable commits since ${LAST_TAG}." >&2
  exit 0
fi

bump_major=0
bump_minor=0
bump_patch=0

while IFS= read -r subject; do
  [[ -z "$subject" ]] && continue

  if [[ "$subject" =~ BREAKING[[:space:]]CHANGE ]] || [[ "$subject" =~ ^[a-zA-Z]+(\([^)]+\))?!: ]]; then
    bump_major=1
  elif [[ "$subject" =~ ^feat(\([^)]+\))?: ]]; then
    bump_minor=1
  elif [[ "$subject" =~ ^(fix|perf|refactor|revert)(\([^)]+\))?: ]]; then
    bump_patch=1
  else
    bump_patch=1
  fi
done <<< "$COMMITS"

IFS=. read -r major minor patch <<< "$BASE_VERSION"
major="${major:-0}"
minor="${minor:-0}"
patch="${patch:-0}"

if (( bump_major )); then
  NEW_VERSION="$((major + 1)).0.0"
elif (( bump_minor )); then
  NEW_VERSION="${major}.$((minor + 1)).0"
else
  NEW_VERSION="${major}.${minor}.$((patch + 1))"
fi

if [[ "$NEW_VERSION" == "$CURRENT" && "$LAST_TAG" == "v${CURRENT}" ]]; then
  {
    echo "bumped=false"
    echo "version=${CURRENT}"
    echo "tag=v${CURRENT}"
    echo "action=none"
  }
  echo "Version already at ${CURRENT} for ${LAST_TAG}." >&2
  exit 0
fi

set_version "$NEW_VERSION"

{
  echo "bumped=true"
  echo "version=${NEW_VERSION}"
  echo "tag=v${NEW_VERSION}"
  echo "action=bump"
}
echo "Bumped ${BASE_VERSION} -> ${NEW_VERSION} based on commits since ${LAST_TAG}." >&2
