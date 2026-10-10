"""Converts docs/REPORT.md to a PDF with Microsoft Edge (no pandoc needed).

    python tool/report/md_to_pdf.py                      # docs/REPORT.md -> docs/REPORT.pdf
    python tool/report/md_to_pdf.py in.md out.pdf        # other files
    python tool/report/md_to_pdf.py --font-pt 10.5       # bigger text

It understands the small Markdown subset used by the report: headings, rules,
tables, bullet / numbered lists, bold, italic, inline code, links, images
(`![](screenshots/x.png)`, path relative to the .md file) and paragraphs. It prints the number of pages so the 2-4 page limit can be
checked. Needs Windows with Edge (or set EDGE=<path to msedge.exe>) and Python 3.
"""

import html
import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path

EDGE_CANDIDATES = [
    os.environ.get('EDGE', ''),
    r'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe',
    r'C:\Program Files\Microsoft\Edge\Application\msedge.exe',
]

CSS = """
@page { size: A4; margin: 12mm 13mm; }
body { font-family: 'Segoe UI', Arial, sans-serif; font-size: %(pt)spt; line-height: 1.32; color: #111; }
h1 { font-size: 15pt; margin: 0 0 4px; text-align: center; }
h2 { font-size: 11.5pt; margin: 9px 0 3px; border-bottom: 1px solid #2c4570; color: #2c4570; }
p { margin: 3px 0; }
ul, ol { margin: 2px 0 2px 16px; padding: 0; }
li { margin: 1px 0; }
hr { border: 0; border-top: 1px solid #bbb; margin: 5px 0; }
table { border-collapse: collapse; width: 100%%; margin: 4px 0; font-size: %(small)spt; }
th, td { border: 1px solid #999; padding: 2px 4px; vertical-align: top; }
th { background: #e8edf5; }
code { font-family: Consolas, monospace; font-size: 0.92em; background: #f1f1f1; padding: 0 2px; }
img { max-width: 100%%; max-height: 62mm; display: block; margin: 0 auto; }
td img { width: 100%%; max-height: none; }
blockquote { margin: 3px 0; padding-left: 8px; border-left: 3px solid #bbb; color: #444; }
"""


# Folder of the Markdown file: relative image paths are resolved from it.
BASE = Path('.')


def image(match):
    alt, path = match.group(1), match.group(2)
    src = (BASE / path).resolve().as_uri() if not path.startswith('http') else path
    return f'<img src="{src}" alt="{alt}">'


def inline(text):
    text = html.escape(text, quote=False)
    text = re.sub(r'!\[([^\]]*)\]\(([^)\s]+)\)', image, text)
    text = re.sub(r'`([^`]+)`', r'<code>\1</code>', text)
    text = re.sub(r'\*\*([^*]+)\*\*', r'<b>\1</b>', text)
    text = re.sub(r'(?<![*\w])\*([^*\n]+)\*(?!\w)', r'<i>\1</i>', text)
    text = re.sub(r'\[([^\]]+)\]\((https?://[^)\s]+)\)', r'<a href="\2">\1</a>', text)
    return text


def split_row(line):
    cells = line.strip().strip('|').split('|')
    return [c.strip() for c in cells]


def convert(md):
    lines = md.splitlines()
    out = []
    i = 0
    while i < len(lines):
        line = lines[i]
        stripped = line.strip()
        if not stripped:
            i += 1
        elif stripped == '---':
            out.append('<hr>')
            i += 1
        elif stripped.startswith('#'):
            level = len(stripped) - len(stripped.lstrip('#'))
            out.append(f'<h{level}>{inline(stripped[level:].strip())}</h{level}>')
            i += 1
        elif stripped.startswith('|'):
            rows = []
            while i < len(lines) and lines[i].strip().startswith('|'):
                rows.append(lines[i])
                i += 1
            header = split_row(rows[0])
            body = [split_row(r) for r in rows[2:]]
            out.append('<table><tr>' + ''.join(f'<th>{inline(c)}</th>' for c in header) + '</tr>')
            for r in body:
                out.append('<tr>' + ''.join(f'<td>{inline(c)}</td>' for c in r) + '</tr>')
            out.append('</table>')
        elif re.match(r'^\s*([*-]|\d+\.)\s+', line):
            ordered = bool(re.match(r'^\s*\d+\.', line))
            items = []
            while i < len(lines) and re.match(r'^\s*([*-]|\d+\.)\s+', lines[i]):
                body = re.sub(r'^\s*([*-]|\d+\.)\s+', '', lines[i])
                i += 1
                # indented continuation / nested items are merged into the item
                while i < len(lines) and lines[i].startswith('  ') and lines[i].strip() \
                        and not re.match(r'^\s*([*-])\s+', lines[i]):
                    body += ' ' + lines[i].strip()
                    i += 1
                items.append(body)
                while i < len(lines) and re.match(r'^\s{2,}\d+\.\s+', lines[i]):
                    items.append(re.sub(r'^\s*\d+\.\s+', '', lines[i]))
                    i += 1
            tag = 'ol' if ordered else 'ul'
            out.append(f'<{tag}>' + ''.join(f'<li>{inline(t)}</li>' for t in items) + f'</{tag}>')
        elif stripped.startswith('>'):
            out.append(f'<blockquote>{inline(stripped.lstrip("> "))}</blockquote>')
            i += 1
        else:
            para = [stripped]
            i += 1
            while i < len(lines) and lines[i].strip() and not re.match(
                    r'^(#|\||---|\s*([*-]|\d+\.)\s+|>)', lines[i].strip()):
                para.append(lines[i].strip())
                i += 1
            # The header block of the report keeps one field per line.
            if len(para) > 1 and para[0].startswith('**Course'):
                out.append('<p>' + '<br>'.join(inline(t) for t in para) + '</p>')
            else:
                out.append('<p>' + inline(' '.join(para)) + '</p>')
    return '\n'.join(out)


def page_count(pdf_path):
    data = Path(pdf_path).read_bytes()
    counts = [int(m) for m in re.findall(rb'/Type\s*/Pages[^>]*?/Count\s+(\d+)', data)]
    if not counts:
        counts = [int(m) for m in re.findall(rb'/Count\s+(\d+)', data)]
    return max(counts) if counts else len(re.findall(rb'/Type\s*/Page[^s]', data))


def main(argv):
    pt = '10'
    args = []
    it = iter(argv)
    for a in it:
        if a == '--font-pt':
            pt = next(it)
        else:
            args.append(a)
    global BASE
    root = Path(__file__).resolve().parents[2]
    src = Path(args[0]) if args else root / 'docs' / 'REPORT.md'
    BASE = src.resolve().parent
    dst = Path(args[1]) if len(args) > 1 else src.with_suffix('.pdf')
    if float(pt) < 10:
        sys.exit('Font below 10pt is not allowed for the report.')

    edge = next((c for c in EDGE_CANDIDATES if c and Path(c).exists()), None)
    if not edge:
        sys.exit('Microsoft Edge not found. Set EDGE=<path to msedge.exe>, or use Word / VS Code (see docs/HANDOVER.md).')

    css = CSS % {'pt': pt, 'small': f'{float(pt) - 0.5:g}'}
    doc = f'<!doctype html><html lang="vi"><head><meta charset="utf-8"><style>{css}</style></head><body>{convert(src.read_text(encoding="utf-8"))}</body></html>'
    with tempfile.TemporaryDirectory() as tmp:
        page = Path(tmp) / 'report.html'
        page.write_text(doc, encoding='utf-8')
        subprocess.run([
            edge, '--headless=new', '--disable-gpu', '--no-pdf-header-footer',
            f'--user-data-dir={tmp}/profile', f'--print-to-pdf={dst.resolve()}',
            page.as_uri(),
        ], check=True, capture_output=True, timeout=120)
    pages = page_count(dst)
    print(f'{dst}  {pages} page(s), body {pt}pt')
    if not 2 <= pages <= 4:
        print('WARNING: the report must be 2-4 pages.')
        sys.exit(1)


if __name__ == '__main__':
    main(sys.argv[1:])
