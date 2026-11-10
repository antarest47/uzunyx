#!/usr/bin/env python3
"""Writes the Starship theme of each edition: Powerline bands from the accent to
the neutral of Uzunyx. Git, languages and the time share the last band, so an
empty module never leaves a sliver. Usage: gen-starship.py outdir
"""
import os
import sys

# The round cap on the left; Hack has the triangle, and the round one comes from
# "Uzunyx Powerline" (gen-powerline-font.py), made to Hack's cell, or it would
# come smaller from another fallback font.
LEFT, SEP = "", ""
BAND3, TEXT3 = "#343944", "#f2f2f7"  # Neutrals of uzunyx-colors
EDITIONS = {
    "akane": {"band1": "#e62967", "text1": "#ffffff", "band2": "#8f1d45", "text2": "#ffe6ee", "soft": "#ff8fb3"},
    "sora": {"band1": "#16cde0", "text1": "#111318", "band2": "#0d7c8c", "text2": "#e2fbfd", "soft": "#7fe9f3"},
}
LANGUAGES = {
    "python": "", "nodejs": "", "rust": "", "golang": "",
    "java": "", "c": "", "docker_context": "",
}


def theme(c):
    modules = "".join(f"${name}\\\n" for name in LANGUAGES)
    out = f'''"$schema" = 'https://starship.rs/config-schema.json'

format = """
[{LEFT}](fg:{c["band1"]})\\
$username\\
[{SEP}](fg:{c["band1"]} bg:{c["band2"]})\\
$directory\\
[{SEP}](fg:{c["band2"]} bg:{BAND3})\\
$git_branch\\
$git_status\\
{modules}$time\\
[{SEP} ](fg:{BAND3})\\
"""

[username]
show_always = true
style_user = "bg:{c["band1"]} fg:{c["text1"]} bold"
style_root = "bg:{c["band1"]} fg:{c["text1"]} bold"
format = "[ $user ]($style)"

[directory]
style = "bg:{c["band2"]} fg:{c["text2"]}"
format = "[ $path ]($style)"
truncation_length = 3
truncation_symbol = "…/"

[git_branch]
symbol = ""
style = "bg:{BAND3} fg:{c["soft"]}"
format = "[ $symbol $branch ]($style)"

[git_status]
style = "bg:{BAND3} fg:{c["soft"]}"
format = "[($all_status$ahead_behind )]($style)"

[time]
disabled = false
time_format = "%R"
style = "bg:{BAND3} fg:{TEXT3}"
format = "[ ♥ $time ]($style)"
'''
    for name, symbol in LANGUAGES.items():
        value = "$context" if name == "docker_context" else "($version)"
        out += f'''
[{name}]
symbol = "{symbol}"
style = "bg:{BAND3} fg:{TEXT3}"
format = "[ $symbol {value} ]($style)"
'''
    return out


for edition, colours in EDITIONS.items():
    with open(os.path.join(sys.argv[1], edition + ".toml"), "w") as f:
        f.write(theme(colours))
