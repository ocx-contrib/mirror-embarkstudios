# mirror-embarkstudios

OCX mirrors for the cargo plugins published by
[Embark Studios](https://github.com/EmbarkStudios). One repository, one spec
directory per package.

| Package | Spec | Publishes to | Announced as | Upstream SPDX |
|---|---|---|---|---|
| [cargo-deny](https://github.com/EmbarkStudios/cargo-deny) | [`cargo-deny/mirror.yml`](cargo-deny/mirror.yml) | `ghcr.io/ocx-contrib/embarkstudios/cargo-deny` | [`ocx.sh/embarkstudios/cargo-deny`](https://index.ocx.sh/embarkstudios/cargo-deny) | `MIT OR Apache-2.0` |
| [cargo-about](https://github.com/EmbarkStudios/cargo-about) | [`cargo-about/mirror.yml`](cargo-about/mirror.yml) | `ghcr.io/ocx-contrib/embarkstudios/cargo-about` | [`ocx.sh/embarkstudios/cargo-about`](https://index.ocx.sh/embarkstudios/cargo-about) | `MIT OR Apache-2.0` |

Each upstream release is discovered, re-bundled, smoke-tested per
`(version, platform)` and only then pushed with cascade tags, after which the
result is announced into the OCX index.

## Layout

```
mirror-base.yml         repo-wide policy every spec inherits via `extends:`
cargo-deny/             one directory per package — same five files each
cargo-about/
├── mirror.yml          the spec — never at the repo root
├── metadata.json       bundle interface
├── CATALOG.md          → ocx package describe
├── logo.svg / logo.png describe assets, 512px PNG
└── tests/smoke.star    Starlark smoke test
```

`LICENSE` and `NOTICE.md` are shared at the root. Logos are **not** — each
package carries its own, because a repo-root `logo.*` sits in no workflow's
`paths:` filter, so replacing it would publish nothing until some unrelated
edit happened to fire.

⚠️ `extends:` is a **shallow** merge of top-level keys. A spec that restates
`platforms:` to change one runner drops every `containers:` entry with it, and
nothing reds — the legs simply stop existing, and every `os.features` claim
goes back to being asserted rather than verified. Restate a block in full or
not at all.

## Platforms

`mirror-base.yml` deliberately carries **no** `platforms:` block. The packages
here do not share a matrix, and the difference is not cosmetic — see each spec.

`cargo-deny` publishes five platform entries: both Linux arches, both macOS
arches and `windows/amd64`. It ships **no** `aarch64-pc-windows-msvc` asset in
any release, so `windows/arm64` is a deliberate, evidenced exclusion rather than
an omission; declaring it would boot a `windows-11-arm` runner that resolves
zero assets, skips every version and reports success having tested nothing.

Linux is **musl only** — upstream builds no `-gnu` asset for either arch — and
both musl builds are **fully static**: no `PT_INTERP`, no `DT_NEEDED`, not
UPX-packed. `os.features` states what an artifact requires *of the host*, so
both Linux keys are **bare**: tagging a static build `+libc.musl` would be a
false requirement that hid it from every glibc host. The `alpine:3.20` container
leg is what turns that universal claim into evidence; the measurement itself is
recorded above the `assets:` block in `cargo-deny/mirror.yml`.

`cargo-about` measures the same way — musl-only Linux, both builds fully static,
both keys bare with the alpine leg — but its matrix is the **mirror image** of
its sibling's, and neither was copied from the other:

| | `cargo-deny` | `cargo-about` |
|---|---|---|
| `darwin/amd64` | ✅ every release | ❌ **dropped at 0.9.0** |
| `windows/arm64` | ❌ never shipped | ✅ every release |

`cargo-about`'s `x86_64-apple-darwin` asset is present in 0.8.2/0.8.3/0.8.4 and
absent from 0.9.0 onward. With a floor of 0.8.4 the range spans that drop, so
declaring the platform would resolve zero assets for every current release and
be silently skipped forever; raising the floor does not recover it, because
0.9.x has no Intel macOS build at all. It is therefore an evidenced exclusion,
recorded above `assets:` in `cargo-about/mirror.yml`, and only Apple Silicon is
declared for that package.

Upstream ships `.tar.gz` on **Windows too**, not `.zip`, despite the
`-pc-windows-msvc` target triples.

## Archive layout and the binaries claim

Every upstream archive here is a **wrapper directory**
(`<tool>-<version>-<triple>/`) holding the executable next to `README.md`,
`LICENSE-APACHE` and `LICENSE-MIT`, with no `bin/` subdirectory. The wrapper's
name embeds both the version and the target triple, so `strip_components: 0`
would need a `PATH` of `${installPath}/cargo-deny-0.20.2-x86_64-unknown-linux-musl`
— a value that changes with every release and every platform, and therefore
cannot be written in `metadata.json` at all. `strip_components: 1` is forced,
which puts the executable at the content root and makes `PATH` a bare
`${installPath}`. `bin_scan` only looks *below* an `${installPath}/<dir>` entry,
so `auto`/`verify` is rejected at spec load with exit 65; `mirror-base.yml`
therefore sets `bin_scan: off` and each `metadata.json` hand-lists its
`binaries`.

## The smoke tests are offline, and do not need cargo

Both tools are cargo plugins, and their headline subcommands shell out to
`cargo metadata` — `cargo-deny check`/`list`, `cargo-about generate`/`init`. That
needs a Rust toolchain which neither `ubuntu:24.04`, `alpine:3.20`, `fedora:40`
nor these bundles provide, so neither smoke asserts on them. Each asserts
instead:

- the version *shape* (`\d+\.\d+\.\d+`), never the version or the banner text;
- the **cargo-plugin argv contract** — `cargo-deny deny --version` must equal
  `cargo-deny --version`, because cargo invokes a plugin with the plugin's own
  subcommand name as `argv[1]` and the binary has to absorb it;
- one genuinely hermetic operation with a provable result:
  `cargo-deny init` writing its real config template (all six TOML sections)
  into a scratch directory, and `cargo-about clarify` detecting `MIT` in a
  license file written by the test and reporting a sha256 that was computed
  independently by Python.

Each is paired with a **negative control**, because both positives are
passthrough-shaped: `init` writes a file (so would anything), and `clarify`
echoes its input before its verdict (so would `cat`). Handed a directory with no
`Cargo.toml`, and a file that is not a license, the real binaries exit 1 and
produce nothing.

`cargo-about`'s assertions are deliberately **quote-agnostic**: `clarify` emits
`license = "MIT"` on 0.8.4 and `license = 'MIT'` from 0.9.x, a surface change
inside the mirrored range.

## Editing

| File | Edit | Regenerate after |
|------|------|------------------|
| `mirror-base.yml`, `<pkg>/mirror.yml` | hand | yes — see below |
| `<pkg>/{metadata.json,CATALOG.md,logo.*}` | hand | — |
| `<pkg>/tests/smoke.star` | hand | — |
| `.github/workflows/*.yml` | **generated — never hand-edit** | re-run when a spec changes |

```bash
ocx-mirror package pipeline generate ci \
  --spec cargo-deny/mirror.yml \
  --spec cargo-about/mirror.yml
```

**Name every spec.** `--spec` *appends* rather than replaces, so a command
naming a subset silently stops rendering the rest while staying green — and the
drift guard reds on a generated workflow the current spec set no longer
produces.

`verify-generated.yml` exits 65 on drift. If a generated workflow is wrong, the
spec or the renderer template is wrong — fix it there and regenerate.

Run `direnv allow` once to put the pinned toolchain on `PATH`, and invoke
`ocx-mirror` directly — never `ocx run -- ocx-mirror`, which pins
`OCX_BINARY_PIN` to the bootstrap `ocx` and false-reds the nested push.

## Required secrets

| Secret | Use |
|--------|-----|
| `OCX_ANNOUNCE_TOKEN` | opens the index pull request from the `ocx-contrib/index` fork |
| `OCX_MIRROR_DISCORD_HOOK` | notify-stage Discord webhook URL |

(Inherited from the `ocx-contrib` org with visibility ALL. GHCR pushes use the
run's own `GITHUB_TOKEN` — no registry secret needed.)

## License

Apache-2.0 — see [`LICENSE`](LICENSE). Upstream assets are out of scope; each
package's redistribution license is recorded in [`NOTICE.md`](NOTICE.md).
