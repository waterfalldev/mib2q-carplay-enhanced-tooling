# MIB2Q RGI tooling

Local package preparation and managed M.I.B. installation/recovery for the
CarPlay RGI application. Application compilation and runtime tests remain in
the application repository; this repository orchestrates them and creates the
SD overlay from external stock firmware inputs.

See [the migration plan](MIGRATION-PLAN.md), [import provenance](IMPORT-PROVENANCE.json)
and [installation and recovery](docs/install-and-recovery.md).

The initial import records the existing implementation before adapting it to
separate source repositories. Keep firmware, dependency caches, build work,
packages and vehicle logs outside this repository.
