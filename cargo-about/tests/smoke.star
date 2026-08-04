# cargo-about/tests/smoke.star — stable across upstream releases, and OFFLINE.
# Assert on the contract (exit code, version shape, a COMPUTED result), never on
# help or banner prose.
#
# What is deliberately NOT asserted: `cargo-about generate` and `cargo-about
# init`. Both shell out to `cargo metadata`, so they need a real cargo toolchain
# on PATH — which ubuntu:24.04, alpine:3.20 and fedora:40 do not ship and this
# bundle does not carry. (Measured: `init` in a directory holding only a
# Cargo.toml exits 1 with "`cargo metadata` exited with an error".) What IS
# hermetic is `clarify`, which reads a file off disk, matches it against the
# SPDX license corpus and hashes it — no cargo, no registry, no network.

ABOUT = "cargo-about.exe" if ocx.target_platform.os == ocx.os.Windows else "cargo-about"

# ── Tier 1 + 2: liveness on the composed PATH + version SHAPE ───────────────
# Measured: stdout is exactly "cargo-about 0.9.1\n" on 0.9.1 and
# "cargo-about 0.8.4\n" on 0.8.4. The digits are the contract; the exact version
# is not, and neither is the leading token — a rebrand must not red this.
r_version = ocx.run(ABOUT, "--version")
expect.ok(r_version)
expect.matches(r_version.stdout, r"\d+\.\d+\.\d+")

# ── The cargo-plugin argv contract ──────────────────────────────────────────
# cargo-about is a CARGO SUBCOMMAND. When invoked as `cargo about generate`,
# cargo execs `cargo-about about generate` — the plugin receives its own
# subcommand name as argv[1] and must absorb it. That absorption is a real
# interface this mirror ships, and it is testable without cargo present: the
# same command with and without the injected `about` token must produce
# identical output. (Measured identical on 0.8.4 and 0.9.1.)
r_plugin = ocx.run(ABOUT, "about", "--version")
expect.ok(r_plugin)
expect.eq(r_plugin.stdout, r_version.stdout)

# ── Tier 3: a real computation on hermetic input ────────────────────────────
# `cargo-about clarify <file> path <root>` reads the file, scores it against the
# SPDX license corpus and emits a TOML clarification carrying the detected
# license id AND the sha256 of the file's bytes.
#
# The expected checksum below was computed INDEPENDENTLY, by Python's hashlib,
# over exactly the bytes written here — so a match is a cross-implementation
# agreement, not a self-consistency check. It is also what makes the assertion
# immune to the passthrough failure mode: a tool that merely echoed its input
# could never produce it.
MIT = (
    "MIT License\n\n" +
    "Copyright (c) 2026 OCX Smoke Test\n\n" +
    "Permission is hereby granted, free of charge, to any person obtaining a copy " +
    "of this software and associated documentation files (the \"Software\"), to deal " +
    "in the Software without restriction, including without limitation the rights " +
    "to use, copy, modify, merge, publish, distribute, sublicense, and/or sell " +
    "copies of the Software, and to permit persons to whom the Software is " +
    "furnished to do so, subject to the following conditions:\n\n" +
    "The above copyright notice and this permission notice shall be included in all " +
    "copies or substantial portions of the Software.\n\n" +
    "THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR " +
    "IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, " +
    "FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE " +
    "AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER " +
    "LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, " +
    "OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE " +
    "SOFTWARE.\n"
)
MIT_SHA256 = "694f31523d9ef1ccd41cd30155c59f44e78e33f726016235affef6205e99e55c"

ocx.mkdir("lic")
ocx.write_file("lic/LICENSE-MIT", MIT)

r_clarify = ocx.run(ABOUT, "clarify", "LICENSE-MIT", "path", ".", cwd="lic")
expect.ok(r_clarify)

# Quote style is NOT part of the contract and it DID drift inside this version
# range: 0.8.4 emits `license = "MIT"`, 0.9.x emits `license = 'MIT'`. Both
# assertions are therefore quote-agnostic — pinning either spelling would red a
# legitimate release.
expect.matches(r_clarify.stdout, r"license\s*=\s*['\"]MIT['\"]")
expect.contains(r_clarify.stdout, MIT_SHA256)

# ── Negative control ────────────────────────────────────────────────────────
# `clarify` echoes the analysed text back before its verdict, so the positive
# case above is passthrough-SHAPED: a tool that only `cat`-ed its input would
# reproduce the license text and satisfy a naive substring check. This control
# is what rules that out. Handed text that is not a license, the real binary
# exits 1, writes NOTHING to stdout, and reports "failed to discern license" on
# stderr — measured identically on 0.8.4 and 0.9.1. A `cat` would exit 0 and
# echo. An exact exit code, not "non-zero": a range would tolerate a crash.
ocx.write_file(
    "lic/NOTALICENSE.txt",
    "this file is not a license\nit is a haiku about cheese\nwensleydale, gromit\n",
)

r_neg = ocx.run(ABOUT, "clarify", "NOTALICENSE.txt", "path", ".", cwd="lic")
expect.eq(r_neg.exit_code, 1)
expect.eq(r_neg.stdout, "")

# No Tier 4: metadata.json declares PATH only, and Tier 1 already proved it.
