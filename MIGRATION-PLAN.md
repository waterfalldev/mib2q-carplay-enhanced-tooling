# Separate application code from local packaging tools

Prepared 27 September 2026; implemented locally on the same date. The design and
starting-point accounting below are retained as the migration record. Packaging
now lives here, the application workflow is restored, and focused local
contribution branches are prepared. See [contribution scopes and validation](docs/upstream-contributions.md).

## Outcome and scope

Move the complete custom package preparation, M.I.B. deployment and recovery system into `mib2q-rgi-tooling`. Keep the CarPlay application, its component build commands and its runtime tests in `mib2q-carplay-rgi-nonfpk`. Restore the upstream installation workflow in the application tree. Prepare focused upstream contributions separately from the tooling extraction.

This is a repository-boundary change. Preserve the current runtime and the custom installer's behavior during extraction. Do not combine it with renderer optimization, removal of runtime tests, redesign of the installer or a new general-purpose build framework.

The tooling can remain local or be pushed to its own remote later. A separate repository is not inherently private; real firmware inputs, generated packages and vehicle logs remain outside both repositories regardless of remote visibility.

## Verified starting point

| Item | Baseline |
|---|---|
| Workspace | `<CarRoot>` |
| Application checkout | `<CarRoot>\Repositories\mib2q-carplay-rgi-nonfpk` |
| Application branch | `non-fpk-support` |
| Application commit | `237ded9a3249dba395f7ac11968ad43440c6f31d` |
| Application working tree | Clean when inspected |
| Upstream comparison baseline | `luka-dev/mib2q-carplay-rgi`, commit `72d321cc9f57bc2f3a1bb76021404c96b300f326` |
| Tooling checkout | `<CarRoot>\Repositories\mib2q-rgi-tooling` |
| Tooling remote | `https://github.com/waterfalldev/mib2q-rgi-tooling.git` |
| Tooling initial state | Empty remote successfully cloned; local unborn branch `main` |
| Existing local launcher | `<CarRoot>\Build\Prepare-CarPlayRGI.ps1` |

The application's configured origin still uses the old `waterfallriver` owner. Do not silently conflate changing that remote with this extraction; the new tooling origin has been verified and configured with `waterfalldev`.

The measured upstream-to-application difference is 103 files, **13,471 additions and 1,719 deletions**. The extraction below covers **20 new files containing 5,053 added lines (37.5% of additions)**:

| Group | Files | Added lines |
|---|---:|---:|
| PowerShell packaging, excluding tests | 11 | 2,868 |
| Packaging tests | 3 | 1,111 |
| M.I.B. templates and collector | 6 | 1,074 |
| Total | 20 | 5,053 |

Removing only those new files would leave 8,418 additions and 1,719 deletions against this pinned baseline. That is arithmetic, not the final projected diff: restoration of old installer files, test runners and documentation will also change the totals. The migration commit itself will show large deletions because code is moving between repositories; compare the final application tree with upstream to assess the reduced contribution size.

## Ownership and exact file moves

Retain the existing `packaging/` and `deploy/mib/` directory names in the tooling repository. This makes the first import easy to audit and avoids unnecessary path changes inside the packaging tests.

Each row below moves from the application repository to the same relative path in the tooling repository.

| File | Lines | Responsibility |
|---|---:|---|
| `packaging/Build-Package.ps1` | 87 | Export committed inputs, invoke the build and publish packages |
| `packaging/Build-Snapshot.ps1` | 532 | Validate firmware, build components, run checks and record evidence |
| `packaging/Build-Java.ps1` | 32 | PowerShell adapter for the application's Java build |
| `packaging/Check-Java.ps1` | 22 | PowerShell Java build/check entry point |
| `packaging/Test-Java.ps1` | 25 | PowerShell adapter for application Java checks |
| `packaging/JavaDocker.ps1` | 41 | Pass isolated settings to the application's Docker launcher |
| `packaging/BuildInputs.ps1` | 25 | Packaging input expectations and dependency identities |
| `packaging/Dependencies.ps1` | 65 | Obtain and verify external dependency JARs |
| `packaging/PackageTools.ps1` | 1,156 | Validation, process isolation, hashing, configuration and publication helpers |
| `packaging/Payloads.ps1` | 84 | Installed-file mapping, destinations and ownership keys |
| `packaging/Stage-Package.ps1` | 799 | Generate the SD overlay, plans and install/rollback scripts |
| `packaging/Tests/Test-Installer.ps1` | 811 | Simulated installation, faults, updates, rollback and collector checks |
| `packaging/Tests/Test-Preparation.ps1` | 260 | Package contents, resources, checksums and publication checks |
| `packaging/Tests/Test-Profile.ps1` | 40 | Firmware-profile schema checks using synthetic inputs |
| `deploy/mib/command.sh` | 202 | ACTION dispatch, locks, mount restoration and result reporting |
| `deploy/mib/common.sh` | 97 | Shared car-side checks and staging helpers |
| `deploy/mib/entry.sh` | 9 | M.I.B. compatibility entry point |
| `deploy/mib/install.sh` | 263 | Verified installation and ownership state |
| `deploy/mib/rollback.sh` | 206 | Restore verified backups and remove owned files |
| `deploy/mib/collect-logs.sh` | 297 | Bounded pre-rollback diagnostic capture |

Also transfer the substantive implementation of the existing workspace launcher into a tooling-root `Prepare-CarPlayRGI.ps1`. It currently manages workspace defaults, elapsed build logging, temporary directories and the package build call. Leave a short compatibility launcher at `<CarRoot>\Build\Prepare-CarPlayRGI.ps1` so the familiar command remains usable. That local launcher supplies workspace paths and forwards arguments; it must not retain a second implementation of build or archive logic.

Move the custom package instructions from the application's `docs/deploy/install.md` into tooling documentation, proposed as `docs/install-and-recovery.md`. Give tooling its own README covering prerequisites, explicit source selection, firmware input preparation, package creation, tests and recovery. Record the source repository/commit and original paths in an import note so the origin of the copied implementation is clear. Preserve existing author notices.

### Keep in the application repository

- All application code in `java_patch/`, `hook/`, `maneuver_render/`, `common/` and `java_resources/`.
- All runtime payload scripts and configuration in `deploy/smartphone_integrator/`. These are installed application components, not package-builder templates.
- Application component commands in `scripts/`, including `build_hook.sh`, `build_renderers.sh`, `build_java.sh`, `check_java.sh`, the shared implementation in `scripts/java/`, and application test/audit runners.
- Runtime tests and their fixtures in `tests/`, including MOST, native-guidance restoration, Java/native contracts, frame pacing and mask-cache tests. Keep the tests with the behavior they cover.
- `tests/Dockerfile.host`, because it provides the environment for application host tests. The tooling consumes an image built from this application-owned Dockerfile and records its immutable image ID.
- Runtime architecture, MOST behavior and validation-limit documentation.
- Source line-ending rules and appropriate exclusions for build outputs and private inputs. Remove obsolete packaging-specific documentation, not protective ignore rules indiscriminately.

The shared Java procedures remain application-owned. Moving them to tooling would make normal application compilation depend on the companion repository and create the opposite dependency from the one intended.

### Cross-platform Docker improvements are application contributions

These improvements are a positive upstream contribution, not part of the 20-file tooling extraction. Upstream already used Docker for both native compilation and the Java application build. The fork made the surrounding build and test workflow more portable and consistent:

| Improvement | What changed | Application-owned implementation |
|---|---|---|
| Windows Docker path handling | Convert Git Bash/MSYS paths to Docker-compatible host paths and prevent MSYS from rewriting container paths | `scripts/build_hook.sh`, `scripts/build_renderers.sh`, `scripts/java/docker.sh` |
| Native compilation on container storage | Copy native sources into Linux storage before compiling; copy outputs back. This avoids the old 32-bit QNX tools rejecting Docker Desktop bind-mount inode numbers | `scripts/build_hook.sh`, `scripts/build_renderers.sh` |
| Portable Java tests | Replace the hard-coded macOS ARM JDK location in upstream Java test runners with the shared Java 8 Docker workflow | `scripts/java/test.sh` and shell test/audit entry points |
| Configurable external inputs | Accept stock, bootstrap/runtime, dependency and output paths without editing scripts; retain upstream's default directory layout | `scripts/java/docker.sh` |
| One Java implementation | Shell commands and the PowerShell package adapter use the same compiler/test procedures, with no host JDK needed for those Java steps | `scripts/java/build.sh`, `scripts/java/test.sh`, `scripts/build_java.sh` |
| Consistent build outputs | Stable JAR entry order/timestamps, required resource/class-version checks, configurable images and recorded Java image identity | `scripts/java/PackageJar.java`, `scripts/java/build.sh`, `scripts/java/docker.sh` |
| Portable checks and source text | Linux host-test corrections, LF rules and regression coverage for spaces in paths and the original upstream input layout | `.gitattributes`, `scripts/run_tests.sh`, `scripts/test_java_build.sh` |

Keep all of these application-side changes during extraction. Move only the PowerShell adapter and package orchestration around them into tooling. Plan dedicated upstream PRs for native build/test portability and the shared Java build/test workflow; the latter is a larger change and should receive its own review rather than being treated as local-only packaging.

The intended hosts are Windows with Git Bash, macOS and Linux, with the required Docker images and stock inputs. Evidence currently establishes the Windows package workflow and tests running inside Linux containers. `scripts/test_java_build.sh` also simulates Darwin and checks the old macOS input layout, but explicitly does not demonstrate a real macOS run. Before claiming verified support across hosts, record actual Windows/Linux/macOS results, including Apple Silicon separately where applicable; the native build still requests `linux/amd64`. Distinguish native-host checks from Linux-container checks. This validation matrix belongs to the upstream build contributions and does not require moving the build implementation into tooling.

### Keep outside both repositories

| Existing location | Contents |
|---|---|
| `<CarRoot>\Build\Firmware\<name>` | Real `Firmware.psd1`, reconstructed `lsd.jar`, original `lsd.jxe` and stock JSON configurations |
| `<CarRoot>\Build\Dependencies` | Downloaded and verified OSGi/ASM dependency cache |
| System temporary directory / external work directory | Exports, compiler output and test fixtures |
| `<CarRoot>\Packages` and `Packages\Archive` | Completed SD overlays, validation records and build logs |
| Existing workspace log directories | Vehicle captures and diagnostic evidence |

Move firmware-profile validation and its tests into tooling, but leave real profile data at its existing external location. A documented schema and synthetic example are sufficient in Git. No firmware binaries, generated packages or real vehicle logs are needed to make the tooling repository useful.

## Build contract between the repositories

The dependency must be one-way: **tooling consumes an application source export; the application builds and tests without tooling installed**. No Git submodule, copied runtime tree, runtime plugin loader or package-manager framework is needed.

### Public entry points

Extend the extracted `packaging/Build-Package.ps1` with these explicit inputs:

| Parameter | Meaning |
|---|---|
| `-SourceRepository` | Required path to the application Git checkout |
| `-Ref` | Application ref; retain the existing name and default `HEAD` |
| `-ToolingRef` | Tooling ref; default `HEAD` in the tooling repository |
| Existing firmware/dependency/work/output parameters | Retain their purpose and external-directory requirements |
| Existing image, label, rebuild and rollback options | Preserve existing behavior; do not repurpose them |

Proposed direct invocation after implementation:

```powershell
& <CarRoot>\Repositories\mib2q-rgi-tooling\packaging\Build-Package.ps1 `
    -SourceRepository <CarRoot>\Repositories\mib2q-carplay-rgi-nonfpk `
    -Ref HEAD -ToolingRef HEAD `
    -FirmwareRoot <CarRoot>\Build\Firmware\MU1329 `
    -Dependencies <CarRoot>\Build\Dependencies `
    -WorkRoot <CarRoot>\Build\Validation\ToolingMigration\Work `
    -OutputRoot <CarRoot>\Build\Validation\ToolingMigration\Packages
```

The workspace compatibility command stays:

```powershell
& <CarRoot>\Build\Prepare-CarPlayRGI.ps1 -Firmware MU1329 -Label mu1329nfc24
```

The label above illustrates the existing syntax; migration verification uses a separate validation label and output directory rather than consuming a vehicle trial number. The substantive tooling launcher accepts explicit `CarRoot`, application and tooling paths. Only the workspace shim supplies this computer's defaults. Neither arbitrary current-directory assumptions nor an exact sibling checkout name may be required by the direct builder.

### Export and execution sequence

1. Resolve both selected refs to full commit IDs. Refuse a missing commit with the repository named in the error. The new, currently empty tooling repository needs its initial committed implementation before it can build a release package.
2. Apply the existing clean-checkout release policy to both repositories. Preserve ignored external inputs. Detect tracked or untracked source changes before release publication; do not silently build them.
3. Validate firmware, dependencies, work and output paths against **both** checkout roots. Reject equal, ancestor and descendant overlap and unsafe junction/symlink resolution. Work and output locations must not own or overwrite either checkout.
4. Export application and tooling commits separately into a fresh run directory, for example `application/`, `tooling/` and `scratch/`. Preserve LF line endings and the relative-tar-path workaround for Windows.
5. Run `packaging/Build-Snapshot.ps1` from the **exported tooling commit**. Supply explicit exported application and tooling roots and both commits. Never load a worker, helper or template from an unrecorded live checkout.
6. Build application components and execute their test runners from the application export. Run packaging tests and read M.I.B. templates from the tooling export. Preserve isolated process execution, child-only Java environment settings and the existing safe parallel steps.
7. Stage the package, verify all required checks and checksums, then publish it with the existing failure-safe archive behavior. Migration builds publish into a separate validation output root.

Use the recorded Java, QNX and host-test image IDs for the migration comparison. Do not resolve one mutable tag separately for different steps within a build.

### Concrete code changes required

| Location in extracted tooling | Required adaptation |
|---|---|
| `Build-Package.ps1` | Stop treating the parent of `packaging/` as the application repo; resolve/export two repositories; add separate source/tooling arguments and provenance |
| `Build-Snapshot.ps1` | Replace inferred `$WorkTree` with an explicit application export; use the tooling export for helper/test scripts and templates; carry both revisions through metadata |
| `Check-Java.ps1` | Accept an explicit application source root instead of using the parent of its own directory |
| `Build-Java.ps1`, `JavaDocker.ps1`, `Test-Java.ps1` | Continue invoking `scripts/java/docker.sh` in the explicit application source root; keep these as adapters |
| `Stage-Package.ps1` | Read payloads/resources from the application export, but templates and `deploy/mib/entry.sh` from tooling; preserve destinations and ownership rules |
| `Payloads.ps1` | Keep repository-source entries relative to the application root; package sources remain relative to the staged package |
| `Tests/Test-Preparation.ps1` | Compare the emitted collector with the selected tooling export; verify two-repository metadata and package identity |
| `Tests/Test-Installer.ps1` | Retain existing behavior checks and temporary fixture overlays; ensure any paths refer to tooling or the staged package explicitly |
| `PackageTools.ps1` | Extend path/provenance/publication support only as needed; preserve Windows console/stdin/output fixes |
| Tooling `Prepare-CarPlayRGI.ps1` and workspace shim | Resolve source/tooling independently, forward both refs, preserve logging and cleanup; update the host-test image prerequisite message |

Document the required application entry points and validate their presence before expensive work. The initial supported source is `237ded9` and the post-extraction application revision retaining those entry points. Missing `scripts/java/docker.sh` or MOST test runners is a compatibility error, not a reason to silently skip checks.

This does not claim the new tooling can build every historic revision or unmodified upstream. Old source revisions that predate the shared Java interface continue to use their original committed builder. Document an explicit legacy reproduction procedure from the old application commit and retain old package evidence. Do not introduce an automatic fallback that executes an unexpected builder or fetches code.

## Package identity and recovery compatibility

Keep application and tooling identities distinct:

- Preserve the meaning of `manifest.source.commit`, `nativeArtifacts.sourceCommit` and car-side `PACKAGE_COMMIT`: they identify the application source.
- Add a manifest `tooling` record containing its Git commit, export kind and the imported-from application commit where applicable. Record all six M.I.B. source templates, including the compatibility `entry.sh`, under tooling provenance.
- Bump the manifest schema from 5 to 6 and the package validation schema from 4 to 5. Update every reader and fixture in this repository. Review generated deployment/rollback metadata for the same ambiguity; add explicit tooling provenance where appropriate and version any changed schema.
- Record both full commits in `PACKAGE-VALIDATION.json`, `PREINSTALL.txt` and the build log. Continue recording firmware profile/input hashes, immutable image IDs and payload checksums.
- Include both abbreviated commits in the package directory and package tag, for example `mib2q-carplay-rgi_MU1329_source_<app12>_tooling_<tools12>_<label>`. Two tool revisions packaging the same application must not collide or require replacement of one another.
- Keep the application's embedded runtime build ID tied to the application commit for this extraction. A tooling-only change must not unnecessarily rebuild the Java identity as a different application version.
- Keep the existing owner marker, `CARPLAY_RGI_STATE_V1` header, file ownership keys, installed destinations and backup paths. Recording tooling metadata is not a reason to invalidate installed packages or abandon verified backups.

Preserve these installer behaviors: exact HMI-library check before installation; payload verification before writes; verified stock backups; mode preservation; runtime files committed before configuration and state; mount/lock cleanup; install result reported last; ACTION changes only after successful installation; pre-rollback capture; rollback proceeding despite diagnostic failure; recognized shader-cache cleanup; no automatic reboot.

The managed installer and upstream's `.carplay-stock` installer are different installation formats. Restoring upstream scripts to the source tree does not make the formats interchangeable. Keep instructions requiring removal with the installer that owns the existing installation before switching workflows. Do not let either uninstaller adopt the other's backups.

## Restore the independent upstream workflow

Restore these application paths from upstream baseline `72d321c` as the starting point:

| Files | Action |
|---|---|
| `install_MoreIncredibleBash/mod/command.sh`, `mod/custom.sh`, `mod/carplay/.gitkeep` | Restore upstream installation bundle |
| `uninstall_MoreIncredibleBash/mod/command.sh`, `mod/custom.sh` | Restore upstream removal bundle |
| `logging_MoreIncredibleBash/mod/command.sh`, `mod/custom.sh` | Restore upstream diagnostic bundle |
| `scripts/test_install_dio.sh` | Restore installer configuration regression test |
| `scripts/test_install_listing.sh` | Restore release-layout/listing regression test |
| `scripts/test_install_payload.sh` | Restore payload regression test, retaining the Linux portability correction from `6998acb` |
| `scripts/test_logging_mib.sh` | Restore upstream logger regression test |

Reinstate those four shell test invocations in `scripts/run_tests.sh` while preserving current application checks. Replace its comment saying installer tests run through the now-external package builder. The restored shell tests cover the restored upstream bundles; the PowerShell tests cover the custom tooling installer. Both have a reason to exist.

Documentation edits in the application:

- `README.md`: remove ownership of `packaging/` and `deploy/mib/`, restore standard installation/removal instructions, keep component build commands and MOST documentation. A short optional companion-tooling link may remain on the fork; an upstream PR must not require it.
- `docs/deploy/install.md`: restore the upstream workflow, retaining any verified corrections relevant to it. Move custom firmware/package/recovery details to tooling instead of maintaining two copies.
- `docs/INDEX.md` and `docs/architecture.md`: ensure install/build links and descriptions match the restored workflow.
- `docs/hmi/pdc-small-stage.md`: remove the dependency on `packaging/Test-Java.ps1` when describing application checks; retain application-owned test commands.
- Search all tracked documentation and scripts for references to removed paths. Historical analysis reports outside the repository remain dated evidence and do not need rewriting.

Do not restore old copies of all documentation wholesale: that would discard unrelated MOST and runtime corrections. Restore only the workflow sections affected by extraction.

## Implementation sequence and reviewable commits

Use four bounded stages. Preserve the current application branch and history; do not force-push or rewrite published commits. Before implementation, recheck both working trees and the application HEAD because another task may have advanced them. Reconcile any newer changes before importing files.

1. **Import and establish ownership.** Make a dedicated application extraction branch from the verified current fork tip. In tooling, import the 20 files with minimal changes, import the substantive workspace launcher, copy the relevant package documentation, and add README, import provenance, LF attributes and ignore rules. Make the initial tooling commit before testing clean-commit exports. Leave the application implementation available during this stage. Compare the imported files with their exact source blobs to verify the copy.
2. **Decouple and validate tooling.** Add explicit application/tooling roots, dual exports, provenance, package naming and the small compatibility checks above. Commit the adapted tooling so release tests can consume a clean revision. Build application `237ded9` through the new tooling into a dedicated validation directory. Fix only migration regressions and repeat affected checks.
3. **Cut over the application and workspace command.** Remove the imported `packaging/` and `deploy/mib/` trees from the application after the preceding build passes. Restore the upstream bundles/tests, update documentation and convert the workspace launcher to the compatibility shim. Commit the application extraction. Build that new clean application commit through the committed tooling and run the application's independent component/test workflow. Record the accepted pair of commits in local migration validation evidence outside both source trees.
4. **Prepare contribution branches.** Recompute the upstream diff and prepare separate branches from the then-current upstream baseline for the contributions below. Transfer selected changes and tests, resolving mixed commits by behavior rather than blindly cherry-picking the entire history. PR publication is a separate action from this plan and extraction; do not submit the large fork-wide comparison as a single PR.

Keep import and adaptation separate in tooling history. Keep application extraction separate from behavior-changing runtime commits. There is no atomic cross-repository commit, so the validated pair of commits is the handoff record. Do not delete old packages or their recovery materials as part of the cutover.

## Validation and acceptance

### Existing evidence, not a fresh test run

The completed package at `<CarRoot>\Packages\mib2q-carplay-rgi_MU1329_source_237ded9a3249_mu1329nfc23` records:

| Check | Recorded result |
|---|---|
| Firmware profile checks | 9 passed |
| Java host suites | 42 passed |
| Java build/linkage | 136 patch classes, Java 1.4 class version 48, zero linkage errors |
| Native MOST platform/render/mask checks | 451 / 184 / 42 checks, zero failures |
| Preparation checks | 39 assertions passed |
| Installer/rollback/collector fixtures | 605 assertions passed across 60 parallel units |
| Publication | Completed with staged checksum verification; recorded elapsed time 2:08 |
| Vehicle status | `LOCAL_CHECKS_PASSED_VEHICLE_TEST_PENDING` |

The package manifest records these immutable image IDs:

```text
Java:      sha256:5c25ccda5b0154fca89cbbca34afab0e0a198aa23e7f23b1169dee5577e33e03
QNX:       sha256:3dceb2f4f009873605558c39dd7995cda932b63c5627912fefe4a7e0d16604c0
Host test: sha256:ebb905e81049ef7e2fb376154e2841e235e9dc94ca089c967354ea138f260ff4
```

At implementation time, rerun the original builder once for the pinned baseline into a separate validation output root if the current environment has not already been validated for this migration. Record failures before changing code. Existing logs alone are not evidence that the extracted builder works.

### Required checks

1. **Independent application build:** run application component builds and application tests with tooling absent from their paths. Include the restored upstream installer/logger tests. Java/native runtime tests must not become optional because their launcher moved.
2. **Full extracted build:** for the same application commit, firmware inputs and image IDs, run all existing profile, Java, native, preparation and installer checks through tooling. Compare executed suite names and outcomes, not just total counts.
3. **Two-repository regression cases:** cover missing source/tooling refs, dirty application/tooling checkouts, paths containing spaces, arbitrary checkout locations, unsafe work/output overlap, and separate refs selecting different committed tooling. Use targeted fixtures at the boundary; do not duplicate the entire runtime suite.
4. **Provenance and collision checks:** prove the exported tooling revision supplies templates and worker code; both full commits are present; two tooling revisions against the same application produce distinct package identities; failed publication preserves earlier completed packages.
5. **Payload comparison:** compare application payload hashes between original and extracted builders at the same application commit. Expect unchanged runtime artifacts/resources/configuration results; explain any toolchain/path nondeterminism specifically. Compare changed package metadata against a narrow expected-change list. Do not require whole-package byte equality because preparation timestamps and the new provenance/tag deliberately differ.
6. **Recovery continuity:** use the existing installer fixture environment to test old managed package to new package update, interrupted update, new package rollback, HMI mismatch refusal with rollback still available, ACTION/result ordering, lock/mount failure paths and diagnostics failure. Verify old state/owner markers and backups remain recognized. Distinguish this from the unsupported switch from upstream `.carplay-stock` installations.
7. **Workspace compatibility:** the familiar local launcher works, forwards application and tooling refs, saves the build log, and cleans only its verified temporary run directory after success. A failed build retains its evidence.
8. **Post-cutover inspection:** no application build/runtime path reads `packaging/`, `deploy/mib/` or a required sibling tooling checkout; application HEAD is clean; tooling HEAD is clean after implementation commits; private inputs and generated outputs are untracked in both.
9. **Diff accounting:** regenerate file-level additions/deletions against the same pinned upstream baseline, then separately against current upstream if it advanced. Report moved code, restored files and remaining runtime/test changes explicitly.

Repository extraction does not establish FPK or additional firmware compatibility and does not resolve the known MOST ticking issue. Keep those existing validation limits. A vehicle installation is not required to prove the repository boundary; any later vehicle trial is a separately recorded validation of the produced package.

Acceptance is a working clean-commit build from both repositories, an independent application workflow, preserved managed recovery behavior, and a smaller accurately accounted upstream diff. No reduction in test coverage is accepted merely to lower the line count.

## Upstream contribution boundaries

| Contribution | Starting evidence | Include | Exclude / gate |
|---|---|---|---|
| Native-guidance restoration fixes | `a99ad32`, `79136a7`, `5b34a89` | Fail-safe takeover release, reopening/replay of native guidance, restoring latest native state, focused regression tests | Packaging replacement and MOST renderer changes; preserve explicit limits such as not resuming a route already cancelled by REPLACE mode |
| Small build/test portability fixes | `6998acb`, `2418f34` | Linux host checks, LF handling, Windows Docker native builds | Full PowerShell packaging dependency |
| Cross-platform Java build/test workflow (separate PR) | Selected changes from `8226e17`, `15f166a` and relevant later corrections | Configurable external stock inputs, Docker-based Java tests replacing hard-coded host JDK paths, shared compilation/tests and stable JAR output, with existing shell entry points and upstream defaults retained | Tooling orchestration and PowerShell-only adapter fixes; record actual host validation and do not hide a substantial Java workflow replacement inside the small native portability PR |
| MOST/non-FPK support | `46c5ac6`, `7d074ad`, later required fixes and current feature documentation | Coding-based selection, view ownership/handshake, native output geometry, KOMO text, current MOST-specific behavior and relevant tests | Custom packaging; unvalidated claims about other cluster types; shared renderer changes must be reviewed separately below |
| Individual upstream installer fixes | Findings demonstrated against the restored original scripts | Small, independently tested changes for error propagation, mount cleanup or permissions where warranted | Wholesale managed installer adoption, firmware-profile policy, archive framework and unrelated diagnostic collection |

The shared renderer frame pacing, mask caching and profiling changes are not automatically part of the initial MOST PR. They affect more than the new cluster path. Separate them for review and appropriate FPK validation; first establish which pieces the MOST implementation actually requires. Keep their implementation and tests together on the fork while that decision is made. Mixed commits such as `c2fcfa7` must be split by affected behavior rather than cherry-picked wholesale.

All full PowerShell packaging, custom deployment templates, firmware profile handling, package archiving and their tests belong to `mib2q-rgi-tooling`. Upstream can receive a useful runtime fix or feature without agreeing to maintain this local workflow.

## Completion checklist

- [x] Clone `waterfalldev/mib2q-rgi-tooling` into the requested `Repositories` folder.
- [x] Inspect application dependencies and current package evidence; record this plan.
- [x] Import the exact tooling files and document their origin.
- [x] Implement and commit independent application/tooling source selection.
- [x] Validate the extracted builder against the original pinned application.
- [x] Restore upstream installation bundles and tests in the application.
- [x] Remove application-owned copies and update the local compatibility launcher.
- [x] Validate the post-cutover application/tooling commit pair and recovery fixtures.
- [x] Recompute the upstream line accounting.
- [x] Prepare focused upstream contribution branches and their validation notes.

The application is on `extract-rgi-tooling`; its original `non-fpk-support` branch
is preserved. The extraction diff against the original upstream baseline is now
73 files, 8,317 additions and 636 deletions. The runtime source and runtime tests
are unchanged by extraction. The existing workspace command forwards to this
repository. All work is committed locally; no repositories have been pushed and
no PRs have been opened. Detailed local build evidence and package comparisons
are stored outside both repositories under `Build/Validation/ToolingMigration`.
