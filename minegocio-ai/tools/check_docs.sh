#!/usr/bin/env bash
# Verifica la documentación de MiNegocio AI:
#   1. existen los documentos obligatorios del prompt maestro (§14);
#   2. todos los enlaces relativos de los .md apuntan a archivos existentes (y anclas de archivo, no de sección);
#   3. los bloques ```mermaid están cerrados y empiezan con un tipo de diagrama conocido.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
exec python3 -I - "$ROOT" <<'PY'
import re, sys
from pathlib import Path

root = Path(sys.argv[1])
required = [
    "README.md",
    "docs/requirements/PRD.md",
    "docs/architecture/SYSTEM_ARCHITECTURE.md",
    "docs/architecture/C4.md",
    "docs/architecture/DATABASE_DESIGN.md",
    "docs/architecture/SYNC_STRATEGY.md",
    "docs/requirements/USER_STORIES.md",
    "docs/requirements/BACKLOG.md",
    "docs/security/THREAT_MODEL.md",
    "docs/sunat/INTEGRATION_PLAN.md",
    "docs/decisions/ADR-001.md",
    "docs/ROADMAP.md",
    "docs/TEST_PLAN.md",
    "docs/PROGRESS.md",
]
errors = []
for rel in required:
    p = root / rel
    if not p.is_file() or p.stat().st_size < 200:
        errors.append(f"falta o está vacío: {rel}")

link_re = re.compile(r"(?<!!)\[[^\]]*\]\(([^)\s]+)\)")
mermaid_types = ("C4Context", "C4Container", "C4Component", "flowchart", "sequenceDiagram",
                 "erDiagram", "stateDiagram-v2", "gantt")
md_files = sorted(root.rglob("*.md"))
links = 0
diagrams = 0
for md in md_files:
    text = md.read_text(encoding="utf-8")
    # enlaces
    for target in link_re.findall(text):
        if re.match(r"^[a-z]+:", target) or target.startswith("#"):
            continue
        path = target.split("#", 1)[0]
        if not path:
            continue
        links += 1
        if not (md.parent / path).resolve().exists():
            errors.append(f"{md.relative_to(root)}: enlace roto -> {target}")
    # bloques de código
    fences = re.findall(r"^```(.*)$", text, flags=re.M)
    if len(fences) % 2:
        errors.append(f"{md.relative_to(root)}: bloque de código sin cerrar")
    for m in re.finditer(r"^```mermaid\n(.*?)^```", text, flags=re.M | re.S):
        diagrams += 1
        first = next((l.strip() for l in m.group(1).splitlines() if l.strip()), "")
        if not first.startswith(mermaid_types):
            errors.append(f"{md.relative_to(root)}: diagrama mermaid con tipo desconocido: {first!r}")

print(f"Documentos .md: {len(md_files)} | obligatorios: {len(required)} | enlaces internos: {links} | diagramas mermaid: {diagrams}")
if errors:
    print("ERRORES:")
    for e in errors:
        print(" -", e)
    sys.exit(1)
print("OK: documentos obligatorios presentes, enlaces internos válidos, bloques mermaid bien formados")
PY
