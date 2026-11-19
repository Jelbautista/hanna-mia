#!/usr/bin/env bash
# Renderiza cada bloque ```mermaid de docs/ con mermaid-cli para detectar errores de sintaxis.
# Requisitos: Node 18+ y Chrome/Chromium.
#   MMDC=/ruta/a/mmdc   (por defecto: npx -y @mermaid-js/mermaid-cli@11.4.2)
#   CHROME=/ruta/a/chrome (por defecto: /opt/pw-browsers/chromium si existe)
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

MMDC="${MMDC:-npx -y @mermaid-js/mermaid-cli@11.4.2}"
CHROME="${CHROME:-$(readlink -f /opt/pw-browsers/chromium 2>/dev/null || true)}"
if [[ -n "$CHROME" ]]; then
  printf '{"executablePath":"%s","args":["--no-sandbox"]}' "$CHROME" > "$WORK/puppeteer.json"
else
  echo '{"args":["--no-sandbox"]}' > "$WORK/puppeteer.json"
fi

python3 -I - "$ROOT" "$WORK" <<'PY'
import re, sys
from pathlib import Path
root, work = Path(sys.argv[1]), Path(sys.argv[2])
n = 0
for md in sorted((root / "docs").rglob("*.md")):
    for i, m in enumerate(re.finditer(r"^```mermaid\n(.*?)^```", md.read_text(encoding="utf-8"), flags=re.M | re.S)):
        n += 1
        (work / f"{n:02d}__{md.relative_to(root).as_posix().replace('/', '__')}__{i}.mmd").write_text(m.group(1))
print(f"Diagramas encontrados: {n}")
PY

fail=0; ok=0
for f in "$WORK"/*.mmd; do
  name="$(basename "$f" .mmd)"
  if $MMDC -q -p "$WORK/puppeteer.json" -i "$f" -o "$WORK/$name.svg" >"$WORK/$name.log" 2>&1; then
    ok=$((ok + 1)); echo "OK   $name"
  else
    fail=$((fail + 1)); echo "FAIL $name"; grep -m2 -E "Error|Expecting" "$WORK/$name.log" | cut -c1-200 || true
  fi
done
echo "Renderizados: $ok OK, $fail con error"
[[ $fail -eq 0 ]]
