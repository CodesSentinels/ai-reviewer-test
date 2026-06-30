# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Purpose

This is a **test harness** for the `CodesSentinels/ai-reviewer` GitHub Action. It is a Nuxt 3 app that exists solely to trigger real PRs so the reviewer bot can be exercised against realistic code. The app itself is never deployed.

## Dev Commands

```bash
npm run dev       # start dev server (Nuxt 3)
npm run build     # production build
npm run generate  # static site generation
```

Linting (used by the CI reviewer, not in package scripts):
```bash
npx eslint .                          # uses eslint.config.js (Flat Config)
npx biome check utils/ composables/  # biome.json scopes to utils/** and composables/**
```

## Architecture

**Nuxt 3 + Pinia** app with a `base-layer` extension pattern:

- `nuxt.config.ts` — extends `./base-layer`, which provides shared composables/components/utils. Anything in `base-layer/` is auto-available in the main app.
- `stores/` — Pinia stores (e.g. `userStore.ts`)
- `composables/` — app-level composables; `base-layer/composables/` has shared ones
- `server/api/` — Nuxt server routes (e.g. `webhook.ts`)
- `utils/` — utility functions; intentionally contains security and logic bugs for review testing

## CI / Reviewer Integration

`.github/workflows/ai-reviewer.yml` — the only workflow. It:
1. Creates a GitHub App installation token
2. Dynamically resolves which `ai-reviewer` branch to use (PR base branch or push ref name)
3. Checks out `CodesSentinels/ai-reviewer` at that branch into `.github/ai-reviewer-action`
4. Runs the action with ESLint + Biome + shell + web-search enabled

**Key config** (`ai-reviewer.yml` `with:` block):
- `enable_lint_tools: true` — triggers Phase 0b linter scan (ESLint + Biome installed by the action into `/tmp/ai-reviewer-lint-tools/`, not from project `node_modules`)
- `enable_shell: true`, `enable_web_search: true`, `enable_dependency_analysis: true`
- `path_filters` — only `*.ts`, `*.vue`, `*.js`, `*.md`, `*.yml`, `*.yaml`, `package.json`

**`.codesentinel.yaml`** — optional per-repo tool config read by the action in Phase 0b. Controls which linters are enabled and whether to use the project's own config file.

## Test Cases

`test_cases/` contains end-to-end test scenarios for the reviewer. Each subdirectory has a `code-changes/` folder with an `apply-changes.sh` script that writes intentionally buggy code and creates a PR branch.

Matching test documentation lives in `docs/`:
- `docs/07-iteration3-linter-sast-test-case.md` — Linter/SAST integration scenarios (ESLint + Biome, zero project-side install, sandbox caching, graceful degradation)
- `docs/08-iteration2-member-d-test-case.md` — Conversational review interaction and noise control
- `docs/run-iter2-member-d-test.sh` — Script to drive multi-turn @bot conversations on a PR

When adding new test cases, write intentionally flawed but **compilable** TypeScript/Vue. The bugs are the point.
