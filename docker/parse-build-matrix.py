#!/usr/bin/env python3
"""Print build.yaml's matrix for ci-pipeline.sh, one entry per line, with fields
separated by the ASCII unit separator (0x1f):

    index <US> board <US> shield <US> snippet <US> cmake-args <US> artifact-name

0x1f is used (not tab) because bash `read` treats tab as IFS-whitespace and
coalesces runs of it, which would drop/misalign empty fields. The ZMK build
image has python3 + pyyaml but no yq, so we parse it here.
"""
import sys
import yaml

path = sys.argv[1] if len(sys.argv) > 1 else "/repo/build.yaml"
with open(path) as f:
    doc = yaml.safe_load(f) or {}

for i, entry in enumerate(doc.get("include", [])):
    fields = [
        str(i),
        entry.get("board", "") or "",
        entry.get("shield", "") or "",
        entry.get("snippet", "") or "",
        entry.get("cmake-args", "") or "",
        entry.get("artifact-name", "") or "",
    ]
    print("\x1f".join(fields))
