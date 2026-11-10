#!/usr/bin/python3
"""Downloads the wheels that aren't in Debian and checks their SHA256."""
import hashlib
import os
import sys
import urllib.request

WHEELS = [
    ("smbprotocol-1.17.0-py3-none-any.whl",
     "https://files.pythonhosted.org/packages/76/d3/250e13e7b3473a0f441f4d680d511ad30ce432d0180115dec9840d88fe89/smbprotocol-1.17.0-py3-none-any.whl",
     "bd1abff5417f5af83ca516a64ab8e5acece3dbdcf58d4e5e23e47f5165a77349"),
    ("pyspnego-0.12.4-py3-none-any.whl",
     "https://files.pythonhosted.org/packages/eb/4e/f6c1bb147890f246c3a24ce836be4f6cfc44fd7be08e0a229e3a1c08b560/pyspnego-0.12.4-py3-none-any.whl",
     "a29a34de1abe9e9b30d9aa1d363f8e49fc159eb7355b1f2ee86ccb3a2ce3bba9"),
]

dest = sys.argv[1]
os.makedirs(dest, exist_ok=True)
for name, url, sha256 in WHEELS:
    path = os.path.join(dest, name)
    if not os.path.exists(path):
        urllib.request.urlretrieve(url, path)
    with open(path, "rb") as f:
        if hashlib.sha256(f.read()).hexdigest() != sha256:
            sys.exit(f"{name}: wrong SHA256")
