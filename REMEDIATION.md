# Remediation - applicable vulns

jfrog audit found 3 applicable vulns. applicable means the vulnerable code is
actually reachable from our code, not just sitting in node_modules. so these are
the ones we care about. all 3 fixed by version bump, no need for code change.

## what applicable means

the scan first match our dependency versions to the CVE list (thats the huge
table). then the contextual analysis check if we really call the bad function
with input that can trigger it. if yes it say "Applicable". the rest is
"Not Applicable" / "Not Covered" and we can leave it for later.

so instead of going over ~70 rows we only deal with the 3 real ones.

## the findings

### 1. CVE-2022-31129 - moment - High
- package: `moment` 2.19.3
- fixed in: 2.29.4
- what: ReDoS. if you send a very long string to moment parser it blow the CPU.
- where its reachable: we parse user dates with `moment()`.
  - `src/utils/helpers.js:125` - `moment(user.updatedAt || user.createdAt)`
  - `src/utils/helpers.js:133-134` - `moment(user.createdAt)`
  this data can come from the request so its not trusted.
- fix: bump `moment` to `2.29.4`.
- link: https://github.com/moment/moment/security/advisories/GHSA-wc69-rhjr-hc9g

### 2. CVE-2018-16487 - lodash - Medium
- package: `lodash` 4.17.4
- fixed in: 4.17.11
- what: prototype pollution in `_.merge` / `_.mergeWith` / `_.defaultsDeep`.
- where its reachable: we `_.merge` request data into an object.
  - `src/routes/users.js:143` - `_.merge(users[userIndex], { ... })` on PUT body
  - `src/utils/helpers.js:112` - `_.merge(defaults, userData)`
  - `src/utils/helpers.js:153` - `_.merge({}, item)` on external data
  someone can put `__proto__` key in the body and pollute Object.prototype.
- fix: covered when we bump `lodash` to `4.17.21`.
- link: https://github.com/advisories/GHSA-4xc9-xhrj-v574

### 3. CVE-2020-28500 - lodash - Medium
- package: `lodash` 4.17.4
- fixed in: 4.17.21
- what: ReDoS in `_.trim` / `_.trimEnd` / `_.toNumber`.
- where its reachable: `src/utils/helpers.js:65` - `_.trim(input)` inside
  `sanitizeInput`, runs on user input.
- fix: bump `lodash` to `4.17.21`.
- link: https://github.com/advisories/GHSA-29mw-wpgm-hmr9

## the fix

two lines in `package.json`:

```
"lodash": "4.17.4"  ->  "4.17.21"
"moment": "2.19.3"  ->  "2.29.4"
```

lodash 4.17.21 fix both lodash CVEs (16487 fixed at 4.17.11, 28500 fixed at
4.17.21, so the higher one win). moment 2.29.4 fix the moment ReDoS.

no API change between these versions so the code stay the same.

## verify

ran `jf audit --npm` again after the changes and it confirm the project is now
clean from the applicable vulns. so we good.

## Notes

- the secrets issue (hardcoded JWT in `src/index.js:12`) will be fix also in the
  next commit. its not part of the assignment but its a build violation and it
  bother the eye.
