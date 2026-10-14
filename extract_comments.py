#!/usr/bin/env python3
import re, sys, os

if len(sys.argv) < 2:
  print(f"Usage: {sys.argv[0]} <source_file> <output_file>")
  sys.exit(1)

source_file = sys.argv[1]
output_file = sys.argv[2] if len(sys.argv)>2 else os.path.splitext(source_file)[0] + ".md"

file_contentntent: str
with open(source_file, 'r') as f: file_contentntent = f.read()

matched: list[tuple[str,str]] = re.findall(r"([^\n]*/\*\*)(.*?)\*/", file_contentntent, re.DOTALL)
processed_comments_content: list[str] = []
for groups in matched:
  # replace the leading .../** with spaces
  comment_content = len(groups[0])*" " + groups[1]
  lines = comment_content.split('\n')

  # remove leading and tailing empty lines
  if len(lines[0].strip(' '))==0: lines = lines[1:]
  if len(lines[-1].strip(' '))==0: lines = lines[:-1]

  # get indent of each line
  indents = map(lambda line: len(line) - len(line.lstrip(' ')), lines)
  min_indent = min(indents)

  processed_lines = lines
  # remove min indent
  processed_lines = map(lambda line: line[min_indent:], processed_lines)
  # remove tailing spaces
  processed_lines = map(lambda line: line.rstrip(' '), processed_lines)

  processed_comments_content.append('\n'.join(processed_lines))

with open(output_file, "w") as f: f.write('\n\n'.join(processed_comments_content))
