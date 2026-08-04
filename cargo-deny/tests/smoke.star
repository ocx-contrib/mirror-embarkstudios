# cargo-deny/tests/smoke.star — stable across upstream releases, and OFFLINE.
# Assert on the contract (exit code, version shape, a real side effect on disk),
# never on help or banner prose.
#
# What is deliberately NOT asserted: anything reachable through `cargo-deny
# check` / `list`. Both shell out to `cargo metadata`, so they need a real cargo
# toolchain on PATH — which ubuntu:24.04, alpine:3.20 and fedora:40 do not ship
# and this bundle does not carry. A check-based assertion would red every
# container leg for a reason that has nothing to do with the artifact. What IS
# hermetic is `init`, which only reads the working directory and writes the
# config template.

DENY = "cargo-deny.exe" if ocx.target_platform.os == ocx.os.Windows else "cargo-deny"

# ── Tier 1 + 2: liveness on the composed PATH + version SHAPE ───────────────
# Measured: stdout is exactly "cargo-deny 0.20.2\n" on 0.20.2 and
# "cargo-deny 0.19.8\n" on 0.19.8. The digits are the contract; the exact
# version is not, and neither is the leading token — a rebrand must not red this.
r_version = ocx.run(DENY, "--version")
expect.ok(r_version)
expect.matches(r_version.stdout, r"\d+\.\d+\.\d+")

# ── The cargo-plugin argv contract ──────────────────────────────────────────
# cargo-deny is a CARGO SUBCOMMAND. When invoked as `cargo deny check`, cargo
# execs `cargo-deny deny check` — the plugin receives its own subcommand name as
# argv[1] and must absorb it. That absorption is a real interface this mirror
# ships, and it is testable without cargo present: the same command with and
# without the injected `deny` token must produce identical output.
# (Measured identical on 0.19.8 and 0.20.2.)
r_plugin = ocx.run(DENY, "deny", "--version")
expect.ok(r_plugin)
expect.eq(r_plugin.stdout, r_version.stdout)

# ── Tier 3: a hermetic functional operation with a provable side effect ─────
# `cargo-deny init` reads the working directory, refuses one without a
# Cargo.toml, and otherwise writes the full annotated config template. Both the
# refusal and the write happen entirely on the local filesystem — no registry, no
# network, no cargo.
#
# ocx.exists() resolves against SCRATCH, so a file the test itself caused to be
# created there is genuinely provable.
ocx.mkdir("proj")
ocx.write_file(
    "proj/Cargo.toml",
    "[package]\nname = \"ocx-smoke\"\nversion = \"0.1.0\"\nedition = \"2021\"\n",
)

r_init = ocx.run(DENY, "init", cwd="proj")
expect.ok(r_init)
expect.true(ocx.exists("proj/deny.toml"))

# The template's TOML section set IS cargo-deny's configuration schema — the
# five check families plus the graph and output roots. Asserting the sections
# (not the surrounding commentary, which is prose and does change) proves the
# binary emitted its real config surface rather than an empty or truncated file.
# All six measured present in 0.19.8 and 0.20.2.
cfg = ocx.read_file("proj/deny.toml")
expect.contains(cfg, "[graph]")
expect.contains(cfg, "[output]")
expect.contains(cfg, "[advisories]")
expect.contains(cfg, "[licenses]")
expect.contains(cfg, "[bans]")
expect.contains(cfg, "[sources]")

# ── Negative control ────────────────────────────────────────────────────────
# Without the negative control, "init wrote a file" is satisfied by anything
# that writes a file unconditionally. In a directory with no Cargo.toml the real
# binary refuses with exit 1 and writes NOTHING — measured on 0.19.8 and 0.20.2.
# An exact exit code, not "non-zero": a range would tolerate a crash.
ocx.mkdir("empty")
r_neg = ocx.run(DENY, "init", cwd="empty")
expect.eq(r_neg.exit_code, 1)
expect.false(ocx.exists("empty/deny.toml"))

# No Tier 4: metadata.json declares PATH only, and Tier 1 already proved it.
