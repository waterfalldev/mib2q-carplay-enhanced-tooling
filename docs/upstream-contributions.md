# Contribution branches in the application fork

These branches belong to
[`waterfalldev/mib2q-carplay-rgi-nonfpk`](https://github.com/waterfalldev/mib2q-carplay-rgi-nonfpk).
The `upstream/` prefix describes their intended contribution scope; it does not
place them in Luka's repository. Pushing them to the fork does not open PRs or
change upstream. No upstream PR has been opened for this extraction.

They form a review stack so each comparison has a focused diff. Start from
upstream `72d321cc9f57bc2f3a1bb76021404c96b300f326`, which was still upstream main
when checked during implementation.

The fork's `main` contains the complete application after tooling extraction,
at `186baf76c50c05a633b4ee28aee33f01b182ec50`. The redundant extraction,
`non-fpk-support` and local `improvements` branch names have been removed;
their commits remain in `main`. The
contribution stack reorganizes changes already in `main` for focused review;
it should not be merged into `main` again merely to include those same changes.

`main`'s `d7024f5` takes the portability branch's later Java script cleanup
(two JVMs by default, no OSGi JAR overrides, the default-layout build
regression, executable `scripts/java/*.sh`). `main` keeps the `javap` action
that the branch dropped, because this tooling reads the stock DisplayManager
bytecode through it. The contribution branches are review branches, not
package sources: the lower two lack the MOST test runner the builder requires,
and the upper two lack `javap`. Car packages come from `main`.
When a review changes a contribution branch, carry the same change to `main`.

| Branch | Review base | Scope |
|---|---|---|
| `upstream/build-portability` | upstream `72d321c` | Native and Java Docker builds/tests, Windows paths/container storage, image selection, configurable stock/dependency inputs, stable JARs, Linux host checks and LF rules |
| `upstream/native-guidance-restoration` | `upstream/build-portability` | Three original guidance teardown/gate/state fixes and their regression tests |
| `upstream/most-support` | `upstream/native-guidance-restoration` | MOST view/text ownership, readiness handshake, native-size FXAA output, fallback fixes and 30 fps arrows stream selection |
| `review/shared-renderer-performance` | `upstream/most-support` | Shared frame pacing, mask caching and profiling; hold for separate review and FPK validation |

Native and Java build portability share one contribution branch, keeping their
two implementation commits together. The former `upstream/docker-java` branch
is superseded. The three guidance test registrations belong to the guidance
branch, alongside their runtime changes and test sources; the first PR runs
against unchanged upstream application runtime code.

| Branch | Current commit | Files | Added / deleted against review base |
|---|---|---:|---:|
| `upstream/build-portability` | `d564b25764ed27e4d68953530cd5ba9c5a776156` | 22 | 756 / 353 |
| `upstream/native-guidance-restoration` | `55487a08f3e854b1c8d078f1e061da1e07adb4fc` | 8 | 456 / 18 |
| `upstream/most-support` | `40ce8311a96b308c56590e61639fb9b940a3f6e6` | 39 | 5,828 / 69 |
| `review/shared-renderer-performance` | `eb5e76c4a1fb19e701bfefa11e85b8b086976b12` | 12 | 1,250 / 116 |

The MOST branch uses the existing renderer loop and mask painting, with the
MOST-specific 1x/FXAA path and the same-size fallback fix. It includes the current
Java feature/tests but excludes shared caching/pacing/profiling. Its documentation
describes that exact scope. The fork's `main` retains
the entire existing runtime unchanged, including the shared performance work.

## Validation already performed

- The combined portability branch builds both native artifacts and the Java JAR
  from an application-only export. All 35 Java suites and stock linkage pass,
  along with the native/shell checks and restored M.I.B. tests.
- A cleanup pass verified Luka's existing MU1316 layout and preserved his public
  entry points. The direct Java build-regression command now uses that default
  layout, with a dedicated fixture checking the documented invocation. Java
  tests default to two concurrent JVMs, and line-ending rules cover shell
  scripts only. An unused Java inspection action was removed.
  The host-test Dockerfile is on `main` only, because this tooling builds from it.
  The cleanup's last application commit only changes README documentation;
  its preceding commit `82b25a2f84f72fb629914ca8f8a74a248939abd2` passed the
  complete native, Java, shell and build-regression run.
- Pre-PR review (28 Sept 2026; the branch is squashed into `b9b97de` native and
  `d564b25` Java, same final tree): the car class library (`jcl.jar`)
  is optional for the build, as it was upstream; without it the patch compiles
  against JDK 8 and produced a byte-identical JAR. The linkage audit still
  requires it. Fork-only packaging references and `tests/Dockerfile.host` were
  removed from the branch. The upper three branches were rebased onto it, each
  changing by exactly that commit. Portability passes native builds, host C and
  shell checks, 35 Java suites, linkage and 9 build contracts; guidance passes 38
  suites; `main` (`8036805`) passes 42 suites and the build contracts.
- Guidance pre-PR review (28 Sept 2026): the three commits were rewritten
  without the transient comment-encoding damage and with explanatory messages.
  `ScreenNavStatusGate.describe()` moved to the MOST commit, which adds its only
  caller. `NativeGuidanceStateTest` no longer reads the new fields by
  reflection, so on unfixed upstream code it fails on the actual defect.
  Without the fixes, all three new tests fail on upstream behaviour. With them,
  guidance passes 38 suites and MOST 42, both with linkage `errors=0`.
  The fix stops writing the placeholder `{1}` into data model 68, which only
  `ClusterService` writes. That change is untested on a Virtual Cockpit.
- The reordered guidance branch passes all 38 Java suites, including the three
  guidance regressions, plus stock linkage and native/shell checks. Its complete
  tree matches the previously validated portability/restoration/Java stack.
- Java build contracts pass: reproducible JARs, paths with spaces, missing or
  conflicting resources, missing/invalid bootstrap libraries, and the simulated
  original macOS input layout without host Java or PowerShell.
- The separated MOST branch builds both native artifacts and the Java JAR.
  All 42 Java suites and stock linkage pass, plus native/shell/M.I.B. checks.
  Its two native MOST suites report 451 platform checks and 158 render checks,
  with zero failures. The shared-cache suite belongs to the performance branch.
- Reordering changes no final files or file modes in the guidance, MOST or
  performance trees compared with their previously validated counterparts.
  Their Git tree IDs were compared, and a separate read-only review confirmed
  the contribution boundaries. The fork's `main` is unchanged.
- These are Windows-host/Docker-Linux checks. No actual macOS, Apple Silicon or
  vehicle test has been performed on the separated contribution branches.

Fresh combined-build and guidance evidence is under the workspace's
`Build/Validation/ContributionReorder/Build-Portability` and `Guidance`. Previous
MOST evidence remains under `Build/Validation/ToolingMigration/Contributions-MOST`.
Each validation folder records its source commit and preserves its log. The
reordering folder also preserves the original branch commits in a Git bundle.

## Submission order

Review and submit combined native/Java portability first, then restoration,
then MOST. Keep renderer performance for a later, separately validated PR.
Use the relevant fork branch as the source and Luka's `main` as the target.
Submit one at a time: when an earlier PR merges, move the next branch's own
changes onto the updated upstream base and revalidate its diff and tests.
This needs particular care after a squash merge. Use the review bases above
for comparisons before merging; comparing every branch directly with upstream
would include its dependencies.

Do not include tooling code or its tests in these application PRs. Keep the
performance branch held until its effect on existing FPK behavior is assessed.
Small installer reliability fixes remain potential future contributions: this
extraction restores the upstream implementation and its tests without silently
changing its behavior or adopting the managed installer.
