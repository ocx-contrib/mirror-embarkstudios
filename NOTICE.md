# NOTICE

This repository packages and redistributes upstream software published by
[Embark Studios](https://github.com/EmbarkStudios). The Apache-2.0 license in
[`LICENSE`](LICENSE) covers the OCX pipeline files authored here. It does
**not** cover any upstream-derived asset — each package's redistributed bytes
carry their own license, recorded below.

Each package's logo is an original mark authored for this catalog, not an
upstream asset — neither project ships a logo file. Upstream names are used for
identification only, under nominative fair use; no endorsement is implied.

| Package | GHCR path | Upstream SPDX |
|---|---|---|
| `cargo-deny` | `ghcr.io/ocx-contrib/embarkstudios/cargo-deny` | `MIT OR Apache-2.0` |
| `cargo-about` | `ghcr.io/ocx-contrib/embarkstudios/cargo-about` | `MIT OR Apache-2.0` |

---

## `cargo-deny`

Upstream: <https://github.com/EmbarkStudios/cargo-deny>
Published to `ghcr.io/ocx-contrib/embarkstudios/cargo-deny`.

| Component | SPDX | Holder |
|---|---|---|
| cargo-deny (`cargo-deny`) | **MIT OR Apache-2.0** | Copyright (c) 2019 Embark Studios |

Permissive, dual-licensed at the recipient's option. Redistribution of the
compiled binary is granted under either
<https://github.com/EmbarkStudios/cargo-deny/blob/main/LICENSE-MIT> or
<https://github.com/EmbarkStudios/cargo-deny/blob/main/LICENSE-APACHE>.

> The GitHub license API reports only one half of the grant
> (`gh api repos/EmbarkStudios/cargo-deny/license --jq '.license.spdx_id'` →
> `Apache-2.0`) because it detects a single license per repository. The
> repository root in fact carries **both** `LICENSE-APACHE` and `LICENSE-MIT`
> — verified by listing `repos/EmbarkStudios/cargo-deny/contents/` — which is
> Embark's standard Rust dual-license convention, so the SPDX expression above
> is `MIT OR Apache-2.0` rather than the API's single id.

Both license files ship **inside** every upstream release archive, alongside the
executable and `README.md`, so the terms travel with the redistributed bytes as
well as being referenced here.

The published binaries statically link third-party Rust crates under permissive
licenses, enumerated in upstream's `Cargo.lock` — and audited by cargo-deny
itself in upstream's own CI.

No modifications are made to any upstream artifact in this repository; they are
republished byte-for-byte inside an OCX bundle.

---

## `cargo-about`

Upstream: <https://github.com/EmbarkStudios/cargo-about>
Published to `ghcr.io/ocx-contrib/embarkstudios/cargo-about`.

| Component | SPDX | Holder |
|---|---|---|
| cargo-about (`cargo-about`) | **MIT OR Apache-2.0** | Copyright (c) 2019 Embark Studios |

Permissive, dual-licensed at the recipient's option. Redistribution of the
compiled binary is granted under either
<https://github.com/EmbarkStudios/cargo-about/blob/main/LICENSE-MIT> or
<https://github.com/EmbarkStudios/cargo-about/blob/main/LICENSE-APACHE>.

As with `cargo-deny`, the GitHub license API reports only `Apache-2.0` because
it detects a single license per repository; the root in fact carries **both**
`LICENSE-APACHE` and `LICENSE-MIT`, verified by listing
`repos/EmbarkStudios/cargo-about/contents/`. Both ship **inside** every upstream
release archive, so the terms travel with the redistributed bytes.

The published binaries statically link third-party Rust crates under permissive
licenses, enumerated in upstream's `Cargo.lock`.

No modifications are made to any upstream artifact in this repository; they are
republished byte-for-byte inside an OCX bundle.
