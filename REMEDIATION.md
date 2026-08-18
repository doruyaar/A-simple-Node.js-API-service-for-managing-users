# Remediation

## The high applicable issues

all come from one `jf audit` contextual scan:

1. **moment ReDoS** - CVE-2022-31129 - High - dependency CVE, CA verdict
   **Applicable**. `moment` 2.19.3, a long user string to the parser burns CPU.
2. **hardcoded JWT secret** - High - Secrets Detection at `src/index.js:12`. a
   real signing secret committed in the source; anyone with the repo can forge
   tokens.
3. **lodash prototype pollution** - CVE-2018-16487 - CA **Applicable**,
   SAST-confirmed. the live sink is `_.merge(users[userIndex], req.body)` at
   `src/routes/users.js:143`, so a `__proto__` key in the PUT body can pollute
   `Object.prototype`. severity is Medium (not a "high"), but it is the clearest
   real reach in the report, so i fixed it too.

some of these paths look not reachable at first because they sit in exported
helper functions that are never called (dead code) - i fixed them anyway rather
than rely on that.

## What "applicable" means

the scan matches dependency versions to the CVE list, then contextual analysis
checks if the vulnerable function is actually called with input that can trigger
it. only those are **Applicable**; the rest are Not Applicable / Not Covered /
Missing Context. this changes prioritisation: instead of chasing every CVE row, i
fix the few that are truly reachable and deprioritise the noise.

## What i fixed

```
moment  2.19.3 -> 2.29.4                  (High applicable ReDoS)
JWT secret     -> process.env.JWT_SECRET   (High secret; fails fast in prod)
lodash  4.17.4 -> 4.17.21                  (reachable prototype pollution + ReDoS)
```

no API change for the version bumps, so the code stays the same.

## Verify

- app boots: `node src/index.js` serves `/health` and `/api/auth/login` returns
  a JWT.
- `jf audit --npm` after the fix: **0 Applicable** dependency vulns and
  **no secrets found**.

## Note - missing dependencies

the app could not run as-is: the code `require`s two packages that were not
declared in `package.json` - `bcrypt` (`src/index.js`) and `validator`
(`src/routes/users.js`, `src/utils/helpers.js`) - so `npm start` crashed with
`MODULE_NOT_FOUND`. i added both to `package.json`, reinstalled, and confirmed the
app now runs.
