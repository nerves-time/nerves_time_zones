#!/bin/bash

set -e

git config user.name "GitHub Actions"
git config user.email "actions@users.noreply.github.com"

IANA_VERSION=$(curl -fsSL "https://data.iana.org/time-zones/tzdata-latest.tar.gz" | tar --to-stdout -xz version)
CURRENT_VERSION=$(awk '$1 == "@tzdata_version" {gsub(/"/, "", $2); print $2; exit}' mix.exs)

if [[ "$CURRENT_VERSION" == "$IANA_VERSION" ]]; then
  echo "Version $CURRENT_VERSION is still the latest and greatest"
else
  git checkout outdated || git checkout -b outdated

  echo "Creating a PR to update from '$CURRENT_VERSION' to '$IANA_VERSION'"
  sed -i.bak -E "s/^  @tzdata_version \"[^\"]*\"$/  @tzdata_version \"$IANA_VERSION\"/" mix.exs
  rm mix.exs.bak
  git add mix.exs
  git commit -m "Update timezone database to $IANA_VERSION"
  git push -u origin outdated
  gh pr create --fill
fi
