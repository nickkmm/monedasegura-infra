#!/usr/bin/env bash
# The checks for monedasegura-infra. Exit 0 only when the branch is fit to review.
#
# The gate runs this script with the job's worktree as the working directory.
# Same steps as .github/workflows/ci.yml, except the Docker smoke test, which
# stays in CI because it starts the whole stack.
set -euo pipefail

echo "== No third-party papers or datasets are tracked"
if git ls-files | grep -E '^data/02_references/|\.(csv|parquet)$'; then
  echo "These files must never be committed (see AGENTS.md)" >&2
  exit 1
fi

echo "== Lint OpenAPI contracts"
npx --yes @redocly/cli@1.34.0 lint

echo "== Check shell scripts"
for f in scripts/*.sh; do sh -n "$f"; done

echo "== Validate docker-compose for every profile"
docker compose --env-file .env.example config --quiet
docker compose --env-file .env.example --profile apps --profile seed --profile tools config --quiet

echo "== Factory scripts"
# compile() checks the syntax without writing __pycache__ into the worktree
for f in factory/bin/*; do python3 -c 'import sys; compile(open(sys.argv[1]).read(), sys.argv[1], "exec")' "$f"; done
factory/bin/sync-agents --check
