#!/bin/sh

set -o errexit
set -o nounset
set -o xtrace

git config --global --add safe.directory /github/workspace
if case $INPUT_DIRECTORY in "/"*) ;; *) false;; esac; then
  git config --global --add safe.directory "$INPUT_DIRECTORY"
else
  git config --global --add safe.directory "/github/workspace/$INPUT_DIRECTORY"
fi

cd "$INPUT_DIRECTORY" || exit 1

TARGET_BRANCH=$INPUT_BRANCH
case $TARGET_BRANCH in "refs/heads/"*)
  TARGET_BRANCH=$(echo "$TARGET_BRANCH"|sed -E "s@refs/heads/@@")
esac

if [ "$INPUT_FORCE" != "0" ]; then
  FORCE='--force'
fi

# https://everything.curl.dev/usingcurl/netrc
cat <<EOF >| "$HOME/.netrc"
machine github.com
  login $GITHUB_ACTOR
  password $INPUT_TOKEN

machine api.github.com
  login $GITHUB_ACTOR
  password $INPUT_TOKEN
EOF

git config user.email "$INPUT_EMAIL"
git config user.name "$INPUT_NAME"

git fetch "$INPUT_REPOSITORY" "$GITHUB_REF:actions-x-temp-branch"
git switch actions-x-temp-branch
# shellcheck disable=SC2086
git add $INPUT_FILES -v
git commit -m "$INPUT_MESSAGE"
git rebase "$TARGET_BRANCH"
git push "$INPUT_REPOSITORY" "actions-x-temp-branch:$TARGET_BRANCH" "${FORCE:-}"
