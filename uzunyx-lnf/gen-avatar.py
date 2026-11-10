#!/usr/bin/python3
"""Scale an image to a user avatar: gen-avatar.py IN.png OUT SIZE"""
import os
import sys

import gi

gi.require_version("GdkPixbuf", "2.0")
from gi.repository import GdkPixbuf

source, target, size = sys.argv[1:4]
os.makedirs(os.path.dirname(target), exist_ok=True)
pixbuf = GdkPixbuf.Pixbuf.new_from_file_at_scale(source, int(size), int(size), True)
pixbuf.savev(target, "png", [], [])
os.chmod(target, 0o644)
