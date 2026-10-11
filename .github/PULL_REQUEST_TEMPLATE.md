## What and why
<!-- One or two sentences. Link the finding or issue if there is one. -->

## Done when
- [ ] Measured first: a failing test or a measurement shows the problem. For a bug fix, the test fails before the fix and passes after (output pasted below).
- [ ] CI is green (`app / test`).
- [ ] New or changed API call? `test/contract/app_endpoints.txt` and the backend's `contract/endpoints.txt` updated together; response fixture refreshed from the backend if the shape changed.
- [ ] No `expected-fail` marker left on something that now works, and none added without a one-line reason.
- [ ] The app tolerates missing or extra fields; the backend change it depends on is already deployed.
- [ ] No secrets or personal data in code, tests, logs or this description (environment variables by NAME only).
- [ ] Docs updated if behaviour or commands changed (`AGENTS.md`, `docs/`).
- [ ] Human steps listed below, or "none".

## Human steps
<!-- Environment variables to set (names only), Render redeploy, device test. -->

## Evidence
<!-- Trimmed command output: tests before and after, analyzer count. -->
