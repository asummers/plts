#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

git clone https://github.com/elixir-lang/elixir.git
cd elixir
git tag -l --sort=-version:refname v* | \
  sed 's/^v//' | \
  sed 's/-.*//' | \
  uniq | \
  sort -t. -k 1,1n -k 2,2n -k 3,3n -k 4,4n | \
  sed -n '/^1.9.0$/,$p' > ../../elixir.txt
cd ..
rm -rf elixir

echo "Read elixir versions"

git clone https://github.com/erlang/otp.git
cd otp
git tag -l --sort=-version:refname OTP-* | \
  sed 's/^OTP-//' | \
  sed 's/-.*//' | \
  uniq | \
  sort -t. -k 1,1n -k 2,2n -k 3,3n -k 4,4n > ../../erlang.txt
cd ..
rm -rf otp

echo "Read erlang versions"

git config --global user.email "$GITHUB_EMAIL"
git config --global user.name "$GITHUB_NAME"

repo="https://github.com/$GITHUB_REPOSITORY.git"

max_iterations=1
counter=0

git remote set-url origin https://x-access-token:$GITHUB_TOKEN@github.com/$GITHUB_REPOSITORY

while read -r elixirversion
do
  major_version=$(echo "$elixirversion" | cut -d'.' -f1)
  minor_version=$(echo "$elixirversion" | cut -d'.' -f2)
  min_erlang_version=$(cat ./versions/$major_version.$minor_version)

  cat ../erlang.txt | sed -n '/^'"$min_erlang_version"'$/,$p' > filtered_erlang.txt

  while read -r erlangversion
  do
    version=$elixirversion-$erlangversion
    echo "Checking if branch exists for $version"

    exists=$(git ls-remote --heads $repo $version | wc -l)

    if [[ "$exists" -eq "0" ]]
    then
      echo "Branch does not exist."

      git checkout -b $version

      echo $elixirversion > elixir.txt
      git add elixir.txt

      echo $erlangversion > erlang.txt
      git add erlang.txt

      git commit -m "chore: Created version $version version files"
      git push --set-upstream origin $version

      git checkout main

      counter=$(($counter + 1))
    else
      echo "Branch exists. Skipping."
    fi

    if [[ $counter -ge $max_iterations ]]
    then
        exit 0
    fi
  done < filtered_erlang.txt

  if [[ $counter -ge $max_iterations ]]
  then
      exit 0
  fi
done < ../elixir.txt
