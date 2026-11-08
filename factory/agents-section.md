<!-- factory:start (managed by monedasegura-infra factory/bin/install; edit it there) -->
## Software factory

`/factory run` builds every open GitHub issue labeled `factory` **and assigned to you** through intake → spec → build → gate → review → approve, one PR per issue. A person always reviews and merges the PR: the factory never merges. State is in `factory/jobs/` (gitignored, local to your machine); `factory/bin/job` is its only writer. Checks: `factory/checks.sh`. Dashboard: `cd factory && python3 -m http.server`, then open http://localhost:8000/dashboard.html.

| Command | What it does |
|---|---|
| `/factory run` | release the issues whose dependencies are merged, then build your queue (3 at a time) |
| `/factory run <n>` | build issue `<n>` now (it must be assigned to you) |
| `/factory divide <#n, file or text>` | split a large request into PR-sized issues, each with an owner; shows the plan before creating anything |
| `/factory <anything>` | ask about jobs, give feedback on a PR waiting for you, or file a new feature |

- **Who builds what.** Every factory issue is assigned to one person, and each person's factory only takes their own issues, so two people never build the same issue. Never take an issue assigned to someone else.
- **Order.** A task that needs another one says `Depends on #n` and stays unlabeled; `/factory run` labels it once `#n` is closed by a merged PR.
- **Record.** Each PR carries the job's record (intake, spec, build, reviews, checks, decision) in `docs/factory-history/issue-<n>/`. Only the factory writes there.
- **Branches.** The factory pushes `factory/<job-id>` branches and opens PRs against `develop`; this is the only exception to the branch-name rule above.
- **Worktrees.** Each job works in its own git worktree, a full checkout of the repo at `.worktrees/<job-id>` (gitignored). A tool run from the repo root that doesn't read `.gitignore` sees those copies too; exclude `.worktrees/` in its config. **Sibling repos are relative to the main checkout, not to the worktree**: from a worktree, the shared docs are at `<main checkout>/../monedasegura-infra/docs/`.
- **Antigravity.** Use the App or the CLI (custom subagents aren't in the IDE yet), from the repo root: `agy --model <id>`, with an id from `agy models` (Gemini 4 Argon if your plan has it, otherwise Gemini 3.8 Flash), then the same `/factory` commands. The agents in `.agents/agents/` are generated from `.claude/agents/` by `factory/bin/sync-agents`; edit the `.claude/agents/` file and run it, never edit `.agents/agents/` by hand.
- **License.** The factory comes from ZazenCodes' software factory v2 (GPLv3, see `factory/LICENSE`).
<!-- factory:end -->
