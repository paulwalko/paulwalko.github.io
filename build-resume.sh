#!/usr/bin/env bash
# Build Paul_Walko-Resume.pdf and Paul_Walko-Resume.docx from Paul_Walko-Resume.tex.
#
# The .docx exists because Workday-style resume parsers read .docx far more
# reliably than PDF; upload whichever the application accepts, preferring .docx.

set -euo pipefail

cd "$(dirname "$0")"

SRC=Paul_Walko-Resume.tex
PREAMBLE=resume-docx-preamble.tex
BASE=Paul_Walko-Resume

# Re-exec inside nix-shell with only the tools that are actually missing;
# a full TeX Live closure is a big download to pull in for no reason.
missing=()
command -v pdflatex &> /dev/null || missing+=(texliveMedium)
command -v pandoc   &> /dev/null || missing+=(pandoc)
if [[ ${#missing[@]} -gt 0 ]]; then
    exec nix-shell -p "${missing[@]}" --run "$0 $*"
fi

echo "==> PDF"
# Twice, so hyperref/fancyhdr settle.
pdflatex -interaction=nonstopmode "$SRC" > /dev/null
pdflatex -interaction=nonstopmode "$SRC" > /dev/null
echo "    $BASE.pdf"

echo "==> DOCX"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# Swap the PDF preamble for the docx one, keeping the document body verbatim.
{
    cat "$PREAMBLE"
    sed -n '/^\\begin{document}/,$p' "$SRC"
} > "$tmp/resume-docx.tex"

pandoc "$tmp/resume-docx.tex" \
    --from=latex \
    --to=docx \
    --output="$BASE.docx"
echo "    $BASE.docx"

echo "==> Extracted text (what a resume parser sees)"
pandoc "$BASE.docx" --to=plain --wrap=none | head -12
