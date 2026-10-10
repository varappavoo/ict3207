#!/usr/bin/env bash
set -euo pipefail
FILE="${1:-$HOME/contiki-ng/os/lib/random.c}"
if [[ ! -f "$FILE" ]]; then
  echo "Error: file not found: $FILE" >&2
  exit 1
fi
python3 - "$FILE" <<'PY'
from pathlib import Path
import re
import shutil
import sys
p = Path(sys.argv[1])
s = p.read_text()
header = '#include <inttypes.h>'
fallback = '#ifndef PRIx64\n#define PRIx64 "llx"\n#endif'
if re.search(r'^\s*#\s*define\s+PRIx64\b', s, re.M):
    print('PRIx64 definition already present; no changes made.')
    sys.exit(0)
if re.search(r'^\s*#\s*include\s*<inttypes\.h>', s, re.M):
    # Place fallback immediately after the existing header.
    updated = re.sub(r'(^\s*#\s*include\s*<inttypes\.h>[^\n]*\n)', lambda m: m.group(1) + fallback + '\n', s, count=1, flags=re.M)
else:
    # Prepend standard header and fallback before all use sites.
    updated = header + '\n' + fallback + '\n' + s
shutil.copy2(p, str(p) + '.bak')
p.write_text(updated)
print('Patched:', p)
print('Backup:', str(p) + '.bak')
PY
