#!/usr/bin/env bash
# version_web_assets.sh — give every exported Web asset a per-build name, so a browser can
# never show a stale copy of the game.
#
#   scripts/version_web_assets.sh build/web <version>        (make export-web runs this)
#
# Godot's Web export writes index.html plus index.js / .wasm / .pck / .png ... with FIXED
# names. Hosts cache them (GitHub Pages: 10 minutes at the CDN, and browsers keep a 39 MB
# .wasm for as long as they like), so a new release can look like nothing changed —
# 2026-09-05: strawberries shipped, the browser showed the old level for hours.
#
# We cannot set cache headers on GitHub Pages, so we version the URLs instead: rename every
# index.<ext> (except index.html) to index-<version>.<ext> and patch index.html. The engine
# derives the .wasm / .pck / .audio.*.js names from GODOT_CONFIG.executable, so that key is
# patched too. Then PROVE it: no unversioned reference may survive (it would 404 and break
# the page instead of refreshing it), and every versioned reference must exist on disk.
#
# Run once per export; re-versioning an already-versioned directory is refused.
set -euo pipefail

usage() {
	echo "usage: $0 <export-dir> <version>   e.g. $0 build/web abc1234" >&2
	exit 2
}
[ $# -eq 2 ] || usage
dir="$1"
version="$2"
[ -d "$dir" ] || { echo "ERROR: $dir is not a directory" >&2; exit 1; }
[ -f "$dir/index.html" ] || { echo "ERROR: $dir/index.html not found - export first" >&2; exit 1; }
case "$version" in
	"" | *[!A-Za-z0-9._-]*) echo "ERROR: version must match [A-Za-z0-9._-]+, got '$version'" >&2; exit 1 ;;
esac
stem="index-$version"
html="$dir/index.html"
# Asset references the HTML contains, by extension. The engine derives the rest from `executable`.
exts='js|wasm|pck|png|icon\.png|apple-touch-icon\.png'

if grep -q '"executable":"index-' "$html"; then
	echo "ERROR: $html is already versioned; export again before re-running" >&2
	exit 1
fi

# 1. Rename the assets: everything named index.* except the HTML itself.
renamed=0
for f in "$dir"/index.*; do
	name=$(basename "$f")
	[ "$name" = "index.html" ] && continue
	mv "$f" "$dir/$stem.${name#index.}"
	renamed=$((renamed + 1))
done

# 2. Patch every reference. sed to a temp file, then move: portable across BSD and GNU
#    (BSD sed has no \b and a different -i), and atomic.
sed -E \
	-e "s/\"executable\":\"index\"/\"executable\":\"$stem\"/" \
	-e "s/(^|[^-A-Za-z0-9_])index\.($exts)/\1$stem.\2/g" \
	"$html" >"$html.tmp"
mv "$html.tmp" "$html"

# 3. Prove it.
if grep -qE "(^|[^-A-Za-z0-9_])index\.($exts)" "$html"; then
	echo "ERROR: unversioned asset references survived in $html:" >&2
	grep -nE "(^|[^-A-Za-z0-9_])index\.($exts)" "$html" >&2
	exit 1
fi
grep -q "\"executable\":\"$stem\"" "$html" || { echo "ERROR: GODOT_CONFIG.executable was not patched" >&2; exit 1; }
missing=0
while read -r ref; do
	[ -f "$dir/$ref" ] || { echo "ERROR: $html references $ref but it does not exist" >&2; missing=1; }
done < <(grep -oE 'index-[A-Za-z0-9._-]+\.[A-Za-z][A-Za-z.-]*[A-Za-z]' "$html" | sort -u)
[ "$missing" -eq 0 ] || exit 1

echo "versioned $renamed web assets as $stem.* and patched index.html"
