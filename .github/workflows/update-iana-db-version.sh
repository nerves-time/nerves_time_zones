#!/bin/bash

set -e

git config user.name "GitHub Actions"
git config user.email "actions@users.noreply.github.com"
git checkout outdated || git checkout -b outdated

IANA_VERSION=$(wget -q -O - "https://data.iana.org/time-zones/tzdata-latest.tar.gz" | tar --to-stdout -xz version)
CURRENT_VERSION=$(awk '/@tzdata_version\s/{print $NF}' mix.exs | sed -e 's/^"//' -e 's/"$//')

if [[ "$CURRENT_VERSION" == "$IANA_VERSION" ]]; then
  echo "Version $CURRENT_VERSION is still the latest and greatest"
else
  echo "Creating a PR to update from '$CURRENT_VERSION' to '$IANA_VERSION'"
  sed -i "/@tzdata_version\s\"/c\  @tzdata_version \"$IANA_VERSION\"" mix.exs
  git add mix.exs
  git commit -m "Update timezone database to $IANA_VERSION"
  git push -u origin outdated

  if [[ $(gh pr list --state open --label "outdated check") == "" ]]; then
    gh pr create --fill --label "outdated check"
  fi
fi
