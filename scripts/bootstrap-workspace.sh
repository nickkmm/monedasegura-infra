#!/bin/sh
# Clones the four MonedaSegura repos as siblings, which is the layout the docs,
# AGENTS.md files and docker-compose.yml rely on:
#
#   SecureMoney/
#   ├── monedasegura-infra/
#   ├── monedasegura-decision-service/
#   ├── monedasegura-scoring-service/
#   └── monedasegura-app/
#
# Usage, from inside monedasegura-infra:  sh scripts/bootstrap-workspace.sh
# Repos that already exist are left untouched.
set -e
WORKSPACE="$(cd "$(dirname "$0")/../.." && pwd)"
OWNER="nickkmm"
for repo in monedasegura-infra monedasegura-decision-service monedasegura-scoring-service monedasegura-app; do
  if [ -d "$WORKSPACE/$repo/.git" ]; then
    echo "ok       $repo (already cloned)"
  else
    git clone "https://github.com/$OWNER/$repo.git" "$WORKSPACE/$repo"
    echo "cloned   $repo"
  fi
done
echo "Workspace ready at $WORKSPACE"
