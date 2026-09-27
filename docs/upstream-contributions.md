# Prepared local contribution branches

The application checkout contains the branches below. They form a review stack
so each comparison has a focused diff. They have not been pushed and no PR has
been opened. Start from upstream `72d321cc9f57bc2f3a1bb76021404c96b300f326`, which
was still upstream main when checked during implementation.

| Branch | Review base | Scope |
|---|---|---|
| `upstream/build-portability` | upstream `72d321c` | Windows Docker paths/container storage, native image selection, Linux host checks, LF rules and host-test image |
| `upstream/native-guidance-restoration` | `upstream/build-portability` | Three original guidance teardown/gate/state fixes and their regression tests |
| `upstream/docker-java` | `upstream/native-guidance-restoration` | Shared Java 8 Docker compiler/tests, configurable stock/dependency paths, stable JARs and build-contract tests |
| `upstream/most-support` | `upstream/docker-java` | MOST view/text ownership, readiness handshake, native-size FXAA output, fallback fixes and 30 fps arrows stream selection |
| `review/shared-renderer-performance` | `upstream/most-support` | Shared frame pacing, mask caching and profiling; hold for separate review and FPK validation |

The MOST branch uses the existing renderer loop and mask painting, with the
MOST-specific 1x/FXAA path and the same-size fallback fix. It includes the current
Java feature/tests but excludes shared caching/pacing/profiling. Its documentation
describes that exact scope. This separation does not change the user's fork:
`extract-rgi-tooling` retains the entire existing runtime unchanged.

## Validation already performed

- The portability, restoration and Java stack builds both native artifacts and
  the Java JAR from an application-only export. All 38 Java suites and stock
  linkage pass, along with the native/shell checks and restored M.I.B. tests.
- Java build contracts pass: reproducible JARs, paths with spaces, missing or
  conflicting resources, missing/invalid bootstrap libraries, and the simulated
  original macOS input layout without host Java or PowerShell.
- The separated MOST branch builds both native artifacts and the Java JAR.
  All 42 Java suites and stock linkage pass, plus native/shell/M.I.B. checks.
  Its two native MOST suites report 451 platform checks and 158 render checks,
  with zero failures. The shared-cache suite belongs to the performance branch.
- These are Windows-host/Docker-Linux checks. No actual macOS, Apple Silicon or
  vehicle test has been performed on the separated contribution branches.

Local evidence is under the workspace's
`Build/Validation/ToolingMigration/Contributions-Java` and `Contributions-MOST`.
Each folder records the exact source commit and preserves its validation log.

## Submission order

Review and submit portability first, then restoration, Java workflow and MOST.
When an earlier PR merges, rebase its dependants onto upstream and revalidate
the resulting diffs. Use the review base above for each local comparison;
comparing every branch directly with upstream would include its dependencies.

Do not include tooling code or its tests in these application PRs. Keep the
performance branch held until its effect on existing FPK behavior is assessed.
Small installer reliability fixes remain potential future contributions: this
extraction restores the upstream implementation and its tests without silently
changing its behavior or adopting the managed installer.
