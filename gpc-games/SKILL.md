---
name: gpc-games
description: "Use when managing Google Play Games Services achievement and leaderboard configurations with GPC. Make sure to use this skill whenever the user mentions gpc games, games achievements, games leaderboards, achievement config, leaderboard config, Play Games, Play Games Services, gamesconfiguration, achievement CRUD, leaderboard CRUD, points value, incremental achievement, stepsToUnlock, score order, score format, --game-id, GPC_GAME_ID, games.applicationId, or wants to create, update, delete, list, or diff achievement and leaderboard definitions for a game. Also trigger when someone wants to sync local achievement/leaderboard JSON against the remote Play Games configuration, read the runtime (player-facing) leaderboards or achievements, or find a game's numeric application ID. For app releases and tracks, see gpc-release-flow. For in-app purchases and subscriptions, see gpc-monetization."
compatibility: "GPC v0.9.86+ (Games Configuration API: gpc games achievements/leaderboards CRUD + diff, gpc games runtime). Requires authenticated GPC setup (see gpc-setup) and a numeric game application ID. Breaking in v0.9.86: gpc games events removed; runtime list commands moved under gpc games runtime."
metadata:
  version: 1.0.0
---

# gpc-games

Manage Google Play Games Services achievement and leaderboard **configurations** with GPC, through the Games Configuration API (`gamesconfiguration v1configuration`).

## When to use

Use this skill when defining or syncing the achievements and leaderboards for a game: creating, updating, deleting, listing, or diffing their configuration. This is publisher-side configuration (the catalog of achievements/leaderboards), not the player-facing runtime that unlocks them in a session.

Do NOT use this skill for app releases, tracks, or AAB uploads (see `gpc-release-flow`), or for in-app purchases and subscriptions (see `gpc-monetization`).

## Inputs required

- An authenticated GPC setup (`gpc-setup`). The same service account / OAuth used for publishing works here.
- A **numeric game application ID** (the Play Games "Application ID", distinct from the Android package name). Resolve it once and reuse it (see Procedure step 1).
- For create/update: a JSON config file. See `references/games-config-schema.md` for the achievement and leaderboard shapes.

## Procedure

### 0. Verify setup

```sh
gpc doctor
```

Confirm auth is configured before any games command. All write operations support `--dry-run`.

### 1. Resolve and set the game ID

`gpc games` needs the numeric game application ID. Provide it one of three ways (highest precedence first):

```sh
# Per-command flag
gpc games achievements list --game-id 1234567890

# Environment variable (CI-friendly)
export GPC_GAME_ID=1234567890

# Config file: set games.applicationId in .gpcrc.json
gpc config set games.applicationId 1234567890
```

The numeric ID is shown in the Play Console under Play Games Services > Configuration. It is NOT the `com.example.mygame` package name.

### 2. Achievements

```sh
# List (supports --limit / --next-page; --json returns the standard envelope)
gpc games achievements list
gpc games achievements list --limit 10 --json

# Get one by its achievement ID
gpc games achievements get CgkI1234567890

# Create from a JSON file (preview first)
gpc games achievements create --file achievement.json --dry-run
gpc games achievements create --file achievement.json

# Update an existing achievement
gpc games achievements update CgkI1234567890 --file achievement.json

# Delete (prompts for confirmation; --yes to skip)
gpc games achievements delete CgkI1234567890 --yes
```

Achievement config is `STANDARD` or `INCREMENTAL`. Incremental achievements add `stepsToUnlock`. `initialState` is `HIDDEN` or `REVEALED`. See `references/games-config-schema.md`.

### 3. Leaderboards

```sh
# List / get
gpc games leaderboards list --json
gpc games leaderboards get CgkI9876543210

# Create / update from a JSON file
gpc games leaderboards create --file leaderboard.json --dry-run
gpc games leaderboards create --file leaderboard.json
gpc games leaderboards update CgkI9876543210 --file leaderboard.json

# Delete (prompts for confirmation)
gpc games leaderboards delete CgkI9876543210
```

Leaderboard config sets `scoreOrder` (`LARGER_IS_BETTER` / `SMALLER_IS_BETTER`) and a `scoreFormat.numberFormatType` (`NUMERIC`, `TIME_DURATION`, or `CURRENCY`).

### 4. Diff and sync workflow

`diff` compares a local JSON file against the remote configuration field-by-field, so you can review drift before pushing it. Use it as the dry-run for a sync:

```sh
gpc games achievements diff CgkI1234567890 --file achievement.json
gpc games leaderboards diff CgkI9876543210 --file leaderboard.json
```

Pattern: keep each achievement/leaderboard as a versioned JSON file in the repo, `diff` in CI to detect config drift, then `update --file` to apply.

### 5. Runtime (read-only)

The runtime commands read the player-facing definitions for a published game. They are read-only and keyed by the app package, not the game ID:

```sh
gpc games runtime leaderboards --app com.example.mygame
gpc games runtime achievements --app com.example.mygame
```

## Verification

- `gpc games achievements list --json` / `leaderboards list --json` return the standard list envelope: `{ <key>, nextPageToken, meta.count, message? }`.
- After a `create`/`update`, re-run `diff` with the same file: a clean diff confirms the remote matches local.
- Use `--dry-run` on every create/update to preview the request without writing.

## Failure modes / debugging

- "No game ID" / missing application ID: set `--game-id`, `GPC_GAME_ID`, or `games.applicationId` (step 1). Remember it is the numeric Play Games ID, not the package name.
- `gpc games events` no longer exists (removed in v0.9.86) — events are configured in the Play Console UI only.
- Runtime commands moved under `gpc games runtime` in v0.9.86; the old top-level runtime list commands are gone.
- Permission errors: the service account needs access to the game in Play Games Services; see `gpc-troubleshooting` for the error catalog.

## Related skills

- `gpc-setup` — authentication and configuration.
- `gpc-release-flow` — app releases, tracks, and AAB uploads for the game binary.
- `gpc-monetization` — in-app purchases and subscriptions inside the game.
- `gpc-troubleshooting` — exit codes and the error catalog.
