# MIB2Q CarPlay Enhanced tooling

Local package preparation and managed M.I.B. installation/recovery for the
[mib2q-carplay-enhanced-nonfpk](https://github.com/waterfalldev/mib2q-carplay-enhanced-nonfpk)
CarPlay application, which carries no installer of its own. Application
compilation and runtime tests remain in the application repository; this
repository orchestrates them and creates the SD overlay from external stock
firmware inputs.

See [the migration plan](MIGRATION-PLAN.md), [import provenance](IMPORT-PROVENANCE.json)
and [installation and recovery](docs/install-and-recovery.md).

## Build

Use PowerShell 7, Git (including Git Bash on Windows), Docker, a built
`qnx65-armv7-toolchain:latest` image and the application's host-test image:

```sh
docker build --platform linux/amd64 -t carplay-rgi-host-tests:local -f tests/Dockerfile.host .
```

Run that image preparation command in the application checkout. Prepare external
firmware inputs as described in the [package guide](docs/install-and-recovery.md).
Both source repositories must be clean and have committed revisions.

```powershell
./packaging/Build-Package.ps1 -SourceRepository <application-checkout> `
    -Ref HEAD -ToolingRef HEAD -FirmwareRoot <firmware-directory> `
    -Dependencies <dependency-cache> -WorkRoot <scratch-directory> `
    -OutputRoot <package-directory>
```

Both refs resolve locally without fetching. Each is exported separately; the
selected tooling commit supplies the worker, helpers, tests and templates. The
application supplies its own `scripts/` component builds, Java procedures,
runtime tests and installed runtime files. Package names and manifests identify
both commits; the application's embedded build ID identifies only its source.
Keep all input, cache and output directories outside both repositories. Links
and junctions in build paths and overlapping scratch/output roots are refused.

For the existing Car workspace, `Prepare-CarPlayRGI.ps1 -CarRoot <workspace>
-RepoRoot <application-checkout> -Firmware MU1329` supplies the conventional
external input/output paths and saves a timed build log. The existing
`Build/Prepare-CarPlayRGI.ps1` workspace shim supplies those defaults for you.
`-JavaImage`, `-ExpectedToolchainImageId` and `-HostTestImage` select or check images;
their resolved immutable IDs are recorded. `-Label`, `-ForceRebuild` and
`-ArmRollback` retain their existing meanings.

## Checks and compatibility

```powershell
./packaging/Tests/Test-SourceExports.ps1
./packaging/Check-Java.ps1 -SourceRoot <application-checkout> `
    -StockJar <stock-jar> -Dependencies <dependency-cache> -OutputRoot <fresh-output>
```

Full package preparation runs application Java/native checks, profile validation,
package checks and installer/recovery fixtures. `Test-SourceExports.ps1` checks
the real Git export and publication boundary without Docker or firmware. To
check migration from an existing managed package, run:

```powershell
./packaging/Tests/Test-Installer.ps1 -PackageDirectory <new-package> `
    -PreviousPackageDirectory <old-managed-package>
```

Application revisions with the MOST MAP view run its extra checks. See
[the MOST MAP view](docs/install-and-recovery.md#most-map-view).

The initial supported application is commit `237ded9` and later revisions that
retain its component build interface. Missing required entry points fail before
compilation. The original tooling import predates this interface and is not a
valid `-ToolingRef` for the new builder. There is no implicit historical fallback.

To reproduce an older package that used an in-application builder, check out
its recorded application commit in a clean checkout and run **that commit's**
`packaging/Build-Package.ps1` with its original parameters and recorded inputs.
Older Java builders may require their original host JDK. Keep the original
package and its recovery materials; do not overwrite them during reproduction.

Windows builds and Linux-container checks are validated locally. macOS input
conventions have fixture coverage; actual macOS/Apple Silicon execution still
needs validation. Local checks do not claim vehicle compatibility.
