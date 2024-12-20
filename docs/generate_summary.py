#!/usr/bin/env python3
import glob, re, sys

if len(sys.argv) < 2:
  print(f"Usage: {sys.argv[0]} <docs_dir>")
  sys.exit(1)

def generate_section_body(root_dir:str, sub_dir:str) -> list[str]:
  mds_path = glob.glob(f"{sub_dir}/**/*.md", root_dir=root_dir, recursive=True)
  mds_path = sorted(mds_path, key=lambda path: path.rstrip("index.md"))
  entries: list[str] = []
  levels: list[int] = []
  for md_path in mds_path:
    level = md_path.count('/')
    if md_path.endswith("index.md"):
      level -= 1
    title: str
    with open(f"{root_dir}/{md_path}", 'r') as f: title = (re.findall("^# (.*)", f.readline())+[""])[0]
    entries.append(f"{'  '*level}* [{title}]({md_path})")
    levels.append(level)
  min_level = min(levels)
  well_indented_entries = [entry[2*min_level:] for entry in entries]
  return well_indented_entries

print("# Summary")
print("")
print("# 入门（Get Started）")
print("")
print("* [🏠README.md](./index.md)")
print("")
print("# 使用（Usages）")
print("")
for line in generate_section_body(sys.argv[1], "usages/"):
  print(line)
print("")
print("# 设计（Designs）")
print("")
for line in generate_section_body(sys.argv[1], "designs/"):
  print(line)
print("")
print("# 参考（References）")
print("")
for line in generate_section_body(sys.argv[1], "references/"):
  print(line)
