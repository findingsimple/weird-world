#!/usr/bin/env bash
# scripts/setup.sh — one-shot developer setup for macOS.
#
# Installs (asking before each install unless --yes; the git hook and the first
# resource import run automatically):
#   1. Godot (Homebrew cask)                -> `godot` on PATH
#   2. gdtoolkit (gdformat, gdlint) via uv  -> lint/format
#   3. pre-commit via uv, + git hook        -> lint on every commit
#   4. Godot export templates               -> needed for `make export-*`
#   5. First resource import                -> `.godot/` cache
#
# Idempotent: every step is skipped when already satisfied. Re-run any time.
set -euo pipefail

cd "$(dirname "$0")/.."
GODOT_VERSION="$(tr -d '[:space:]' < .godot-version)"
[[ "$GODOT_VERSION" =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?$ ]] || { echo "ERROR: .godot-version must look like 4.7.2, got '${GODOT_VERSION}'" >&2; exit 1; }
GDTOOLKIT_VERSION="4.5.0"   # keep equal to the gdtoolkit `rev` in .pre-commit-config.yaml
TEMPLATES_DIR="$HOME/Library/Application Support/Godot/export_templates/${GODOT_VERSION}.stable"
RELEASE_URL="https://github.com/godotengine/godot-builds/releases/download/${GODOT_VERSION}-stable"
TPZ_NAME="Godot_v${GODOT_VERSION}-stable_export_templates.tpz"
GODOT_OK=0
ASSUME_YES=0
[[ "${1:-}" == "--yes" || "${1:-}" == "-y" ]] && ASSUME_YES=1

info()  { printf '\033[36m==>\033[0m %s\n' "$*"; }
ok()    { printf '\033[32m ok\033[0m %s\n' "$*"; }
warn()  { printf '\033[33mwarn\033[0m %s\n' "$*"; }
fail()  { printf '\033[31mERROR\033[0m %s\n' "$*" >&2; exit 1; }

confirm() {
	[[ "$ASSUME_YES" == 1 ]] && return 0
	read -r -p "    $1 [y/N] " reply
	[[ "$reply" =~ ^[Yy]$ ]]
}

[[ "$(uname -s)" == "Darwin" ]] || fail "This script targets macOS. See docs/getting-started.md for other platforms."
command -v brew >/dev/null || fail "Homebrew is required: https://brew.sh"
command -v uv >/dev/null || fail "uv is required (brew install uv): https://docs.astral.sh/uv/"

# 1. Godot -------------------------------------------------------------------
info "Godot ${GODOT_VERSION}"
if command -v godot >/dev/null; then
	ok "godot found: $(godot --version)"
else
	if confirm "Install Godot via 'brew install --cask godot'?"; then
		brew install --cask godot
	else
		warn "Skipped. Install Godot ${GODOT_VERSION} manually and ensure 'godot' is on PATH."
	fi
fi
if command -v godot >/dev/null; then
	if godot --version | grep -q "^${GODOT_VERSION}\."; then
		ok "version matches .godot-version"
		GODOT_OK=1
	else
		warn "Installed Godot ($(godot --version)) does not match .godot-version (${GODOT_VERSION})."
		warn "Download the exact build: https://github.com/godotengine/godot-builds/releases/tag/${GODOT_VERSION}-stable"
	fi
fi

# 2. gdtoolkit ----------------------------------------------------------------
info "gdtoolkit (gdformat / gdlint)"
if command -v gdlint >/dev/null; then
	ok "gdlint found: $(gdlint --version)"
else
	if confirm "Install gdtoolkit ${GDTOOLKIT_VERSION} via 'uv tool install'?"; then
		uv tool install "gdtoolkit==${GDTOOLKIT_VERSION}"
	else
		warn "Skipped. 'make lint' will not work until gdtoolkit is installed."
	fi
fi

# 3. pre-commit ---------------------------------------------------------------
info "pre-commit"
if command -v pre-commit >/dev/null; then
	ok "pre-commit found: $(pre-commit --version)"
else
	if confirm "Install pre-commit via 'uv tool install pre-commit'?"; then
		uv tool install pre-commit
	else
		warn "Skipped. Commits will not be linted automatically."
	fi
fi
if command -v pre-commit >/dev/null; then
	if [[ -f .git/hooks/pre-commit ]] && grep -q pre-commit .git/hooks/pre-commit; then
		ok "git hook already installed"
	else
		pre-commit install
	fi
fi

# 4. Export templates ---------------------------------------------------------
info "Export templates (${TEMPLATES_DIR})"
if [[ -f "${TEMPLATES_DIR}/version.txt" ]]; then
	ok "already installed: $(cat "${TEMPLATES_DIR}/version.txt")"
elif [[ "$GODOT_OK" != 1 ]]; then
	warn "Skipped: templates must match the installed editor, which is not ${GODOT_VERSION}."
	warn "Install Godot ${GODOT_VERSION} from ${RELEASE_URL} and re-run."
else
	if confirm "Download export templates (~1.3 GB) from godot-builds and verify their SHA-512?"; then
		tmp="$(mktemp -d)"
		trap 'rm -rf "$tmp"' EXIT
		curl --proto '=https' --tlsv1.2 -fL --progress-bar -o "${tmp}/${TPZ_NAME}" "${RELEASE_URL}/${TPZ_NAME}"
		curl --proto '=https' --tlsv1.2 -fsSL -o "${tmp}/SHA512-SUMS.txt" "${RELEASE_URL}/SHA512-SUMS.txt"
		grep " ${TPZ_NAME}\$" "${tmp}/SHA512-SUMS.txt" > "${tmp}/expected.sha512" \
			|| fail "No checksum for ${TPZ_NAME} in SHA512-SUMS.txt"
		(cd "$tmp" && shasum -a 512 -c expected.sha512 >/dev/null) || fail "Checksum mismatch for ${TPZ_NAME} - download aborted"
		ok "checksum verified"
		unzip -q "${tmp}/${TPZ_NAME}" -d "${tmp}/tpz"
		mkdir -p "$TEMPLATES_DIR"
		cp -R "${tmp}/tpz/templates/." "$TEMPLATES_DIR/"
		ok "installed: $(cat "${TEMPLATES_DIR}/version.txt")"
	else
		warn "Skipped. 'make export-*' will not work until templates are installed."
	fi
fi

# 5. First import -------------------------------------------------------------
if command -v godot >/dev/null; then
	info "Importing project resources"
	make import >/dev/null
	ok "imported"
fi

cat <<'MSG'

Setup complete. Next:
  make run     # play the example game
  make ci      # lint + compile check + tests (what CI runs)
  make help    # all targets
MSG
