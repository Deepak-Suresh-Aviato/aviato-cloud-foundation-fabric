#!/bin/sh

# This script posts a comment to a GitHub Pull Request.
# It requires the following environment variables to be set:
# - GITHUB_TOKEN: A GitHub token with permissions to write comments on pull requests.
# - _PR_NUMBER: The number of the pull request (provided by Cloud Build).
# - _REPO_FULL_NAME: The full name of the repository (e.g., "my-org/my-repo").
# - TF_PLAN: The Terraform plan output.

set -e

if [ -z "$GITHUB_TOKEN" ]; then
  echo "Error: GITHUB_TOKEN is not set."
  exit 1
fi

if [ -z "$_PR_NUMBER" ]; then
  echo "Error: _PR_NUMBER is not set."
  exit 1
fi

if [ -z "$_REPO_FULL_NAME" ]; then
  echo "Error: _REPO_FULL_NAME is not set."
  exit 1
fi

if [ -z "$TF_PLAN" ]; then
  echo "Error: TF_PLAN is not set."
  exit 1
fi

# Format the plan for a PR comment
COMMENT_BODY="#### Terraform Plan Output
\`\`\`terraform
${TF_PLAN}
\`\`\`"

# Create the JSON payload for the GitHub API
JSON_PAYLOAD=$(printf '{"body": "%s"}' "$(echo "$COMMENT_BODY" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/`/\\`/g' -e 's/\$/\\$/g' -e 's/\r//g' | tr -d '\n')")

# Post the comment to the GitHub PR
curl -s -S -H "Authorization: token ${GITHUB_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "${JSON_PAYLOAD}" \
  "https://api.github.com/repos/${_REPO_FULL_NAME}/issues/${_PR_NUMBER}/comments" > /dev/null
