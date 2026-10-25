#!/bin/sh
# Deploys the latest `main` of the four repos on the server.
# Run on the server by .github/workflows/deploy.yml (over SSH) after every merge to `main`
# in any repo, or by hand:  sh monedasegura-infra/scripts/deploy.sh
#
# It clones any missing repo, moves every repo to the latest `main`, then rebuilds and
# restarts the stack. The `.env` file is created once by hand on the server and is never
# touched here. Deploys are serialized with a lock, so merges in two repos at the same
# time do not overlap.
set -e

# Everything runs inside main(), so the file is fully read before `git pull` can update it.
main() {
  WORKSPACE="$(cd "$(dirname "$0")/../.." && pwd)"
  INFRA="$WORKSPACE/monedasegura-infra"

  if [ ! -f "$INFRA/.env" ]; then
    echo "Missing $INFRA/.env: create it once from .env.example (see README, Deployment)"; exit 1
  fi

  sh "$INFRA/scripts/bootstrap-workspace.sh"

  for repo in monedasegura-infra monedasegura-decision-service monedasegura-scoring-service monedasegura-app; do
    git -C "$WORKSPACE/$repo" fetch --quiet origin main
    git -C "$WORKSPACE/$repo" checkout --quiet main
    git -C "$WORKSPACE/$repo" merge --quiet --ff-only origin/main
    echo "main     $repo @ $(git -C "$WORKSPACE/$repo" rev-parse --short HEAD)"
  done

  cd "$INFRA"
  docker compose --profile apps up -d --build --remove-orphans
  docker image prune -f >/dev/null
  echo "Deployed"
}

LOCK="${TMPDIR:-/tmp}/monedasegura-deploy.lock"
if command -v flock >/dev/null 2>&1; then
  exec 9>"$LOCK"
  flock 9
fi
main "$@"
