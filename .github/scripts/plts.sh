#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

mix dialyzer --plt

mkdir ../generated_plts

cp ./_build/dev/*.plt ../generated_plts
cp ./_build/dev/*.plt.hash ../generated_plts

rm -rf _build
rm -rf deps

git rm -r ./*
git rm -r .github

cp ../generated_plts/* .
git add *.plt
git add *.plt.hash

git config --global user.email "$GITHUB_EMAIL"
git config --global user.name "$GITHUB_NAME"
git remote set-url origin https://x-access-token:$GITHUB_TOKEN@github.com/$GITHUB_REPOSITORY

VERSION=$(echo $GITHUB_REF | sed 's/refs\/heads\///')

git commit -m "chore: Created PLTs for version $VERSION"
git tag $VERSION

git push --set-upstream origin refs/heads/$VERSION:refs/heads/$VERSION --tags
