# ukg-projects-sync

Mule 4 application that syncs UKG project code-table entries from Sage activity
data, then reloads a snapshot table in KCApps.

## Systems
- **UKG** REST API â€” the only external REST system; projects are read, created, updated.
- **DataWarehouse DB** â€” holds `COA_Activity_Sage`, populated by a separate job. Read only.
- **KCApps DB** â€” holds `UKG_Project`, truncated and reloaded each run.

## Flow (ukg-projects-sync-main, cron `schedule.cron`, no overlapping runs)
1. Fetch all UKG projects (bounded paging, see below).
2. Select UKG-flagged Sage activities from the warehouse.
3. Compute create + update lists (pure DataWeave, unit-tested).
4. POST creates / PUT updates in parallel (`ukg.maxConcurrency`). Transient errors
   (429, 500, 502, 503, timeout, connectivity) are retried `ukg.retry.maxRetries` times;
   other errors fail that record immediately. Each record yields an OK/FAILED result.
5. Re-fetch UKG for the fresh state.
6. Call `LP_UKG_REFRESH_PROJECTS(:data)` with the list as JSON.
7. If any write failed: log one `UKG_WRITE_FAILURES` JSON entry and fail the run
   (`APP:UKG_WRITE_FAILURES`) so monitoring alerts. The snapshot is still reloaded first.

## Rules
- UKG code = Sage key with dashes and spaces removed.
- Description = Sage name, sanitized, max 44 chars.
- Inactive/missing in Sage -> description prefixed `DO NOT USE ` (idempotent).

## Paging
Loops pages 1..`ukg.maxPages` and stops calling once a page is shorter than `ukg.pageSize`.
If the last allowed page is still full, the run fails with `APP:PAGINATION_LIMIT` instead of
syncing a partial list (a partial list would cause duplicate creates).

## Configuration
- `config.yaml` — non-secret settings.
- `secure-${env}.yaml` — secrets (`ukg.oauth.clientSecret`, `dw.password`, `kcapps.password`),
  referenced as `${secure::...}`. Encrypt values with the MuleSoft Secure Properties Tool
  (AES/CBC) and wrap them as `![...]`. Only `secure-local.yaml` (plain placeholders) is included.
- Runtime properties: `-Denv=<env>` (default `local`) and `-Dsecure.key=<key>` (required;
  in CloudHub set it as a protected property).

## Before running
1. Open in Anypoint Studio (File > Import > Anypoint Studio project from File System, or Maven import).
2. Fill `config.yaml`; create and encrypt `secure-<env>.yaml` for each environment.
3. Confirm the UKG auth scheme. The app uses OAuth client credentials (`ukg.oauth.*`); the token is
   fetched and refreshed by the OAuth module. If your tenant uses Basic auth + `US-Customer-Api-Key`
   instead (common for UKG Pro web services), swap `<http:authentication>` in `global.xml`.
4. Run `src/main/resources/LP_UKG_REFRESH_PROJECTS.sql` on KCApps; confirm the `UKG_Project` column widths.
5. Confirm UKG GET field names (`code`/`description`) and PUT body format match your tenant.
6. `mvn clean test` runs the MUnit suites; `mvn clean package` builds the deployable jar.
   Tests override `ukg.pageSize`, `ukg.maxPages`, retry delay and `secure.key` via the munit plugin config in `pom.xml`.

## Known checks
- First run marks every UKG project not currently flagged in Sage as DO NOT USE — review the update count, or run against a test tenant first.
- Set an Anypoint Monitoring / Runtime Manager alert on failed executions of `ukg-projects-sync-main`.
