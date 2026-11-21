#!/usr/bin/env bash

set -e

REPO="ardia-browser/ardia"
declare -A UPDATED_VERSIONS

AUTH=()
if [ -n "$GITHUB_TOKEN" ]; then
  AUTH=(-H "Authorization: Bearer $GITHUB_TOKEN")
fi

# Latest release (stable or nightly) that actually ships the Linux .deb:
# some releases only contain macOS assets.
latest_tag() {
  local PRERELEASE=$1
  curl -s "${AUTH[@]}" "https://api.github.com/repos/$REPO/releases?per_page=100" | \
    jq -r --argjson pre "$PRERELEASE" '
      map(select(
        .draft == false and .prerelease == $pre and
        (.assets | any(.name | test("^Ardia-.*-linux-x64\\.deb$")))
      ))
      | sort_by(.published_at)
      | reverse
      | .[0].tag_name // empty
    '
}

update_package() {
  local LABEL=$1
  local TARGET_FILE=$2
  local PRERELEASE=$3

  echo "Updating $LABEL..."

  local VERSION
  VERSION=$(latest_tag "$PRERELEASE" | sed 's/^v//')

  if [ -z "$VERSION" ]; then
    echo "Error: Could not find a Linux release for $LABEL"
    return 1
  fi
  echo "Latest $LABEL version: $VERSION"

  local ASSET_URL="https://github.com/$REPO/releases/download/v${VERSION}/Ardia-${VERSION}-linux-x64.deb"
  echo "Asset URL: $ASSET_URL"

  local HTTP_CODE
  HTTP_CODE=$(curl -s -L -o /dev/null -w "%{http_code}" "$ASSET_URL")
  if [ "$HTTP_CODE" != "200" ]; then
    echo "Warning: $LABEL $VERSION not available (HTTP $HTTP_CODE), skipping."
    return 0
  fi

  echo "Prefetching hash..."
  local HASH
  HASH=$(nix-prefetch-url "$ASSET_URL")
  echo "Hash: $HASH"

  sed -i "s|version = \".*\";|version = \"$VERSION\";|" "$TARGET_FILE"
  sed -i "s|hash = \".*\";|hash = \"$HASH\";|" "$TARGET_FILE"

  echo "Updated $TARGET_FILE with version $VERSION and hash $HASH"
  UPDATED_VERSIONS["$LABEL"]="$VERSION"
  echo "--------------------------------------------------"
}

update_package "Ardia Stable"  "pkgs/ardia.nix"         false
update_package "Ardia Nightly" "pkgs/ardia-nightly.nix" true

echo "All done!"
echo "Updated versions:"
for key in "${!UPDATED_VERSIONS[@]}"; do
  echo "  $key: ${UPDATED_VERSIONS[$key]}"
done
