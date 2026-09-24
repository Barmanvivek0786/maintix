#!/usr/bin/env python3
"""Idempotent codemod that makes the app's neutral colours theme-aware.

1. Removes `const` from any const expression that now contains a
   theme-aware AppTheme getter (they are no longer compile-time constants).
2. Turns `const x = <theme-aware>` declarations into `final`.
3. Maps hard-coded copies of the old light palette (Color(0xFF1A2B3C) ...)
   to the theme-aware tokens.
4. Text / icon colours that were navy become AppTheme.onSurfaceStrong so
   they stay readable on dark cards.
5. Writes theme_audit.txt: hard-coded light/dark colours that still need a
   manual look.
"""
import bisect
import os
import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parent.parent
LIB = ROOT / 'lib'
THEME_FILE = LIB / 'theme' / 'app_theme.dart'

DYNAMIC = ['primaryNavy', 'headerAlt', 'tealLight', 'background',
           'surfaceWhite', 'surfaceAlt', 'textPrimary', 'textSecondary',
           'textMuted', 'divider', 'cardShadow', 'onSurfaceStrong']
DYN_RE = re.compile(r'\bAppTheme\.(?:' + '|'.join(DYNAMIC) + r')\b')

# hex (upper-case) -> AppTheme token
HEX_MAP = {
    '1A2B3C': 'textPrimary',
    '6B7A8D': 'textSecondary',
    '9EAAB8': 'textMuted',
    'E8EDF3': 'divider',
    'F4F7FC': 'background',
    '0F2942': 'primaryNavy',
    '1A3F5C': 'headerAlt',
    'E0F6FB': 'tealLight',
}
HEX_RE = re.compile(
    r'(?:\bconst\s+)?\bColor\(0xFF(' + '|'.join(HEX_MAP) + r')\)',
    re.IGNORECASE)

IDENT_RE = re.compile(r'[A-Za-z_]\w*(?:\.[A-Za-z_]\w*)*')
DECL_RE = re.compile(
    r'\s+(?:[A-Za-z_][\w.]*(?:<[^;=(){}]*>)?\??\s+)?[A-Za-z_]\w*\s*=(?!=)')


def mask(src):
    """Blank out comments and string literals (same length / offsets)."""
    out = list(src)
    n = len(src)

    def blank(a, b):
        for k in range(a, min(b, n)):
            if out[k] != '\n':
                out[k] = ' '

    i = 0
    while i < n:
        ch = src[i]
        if src.startswith('//', i):
            j = src.find('\n', i)
            j = n if j == -1 else j
            blank(i, j)
            i = j
        elif src.startswith('/*', i):
            j = src.find('*/', i + 2)
            j = n if j == -1 else j + 2
            blank(i, j)
            i = j
        elif ch in '"\'' or (
                ch == 'r' and i + 1 < n and src[i + 1] in '"\'' and
                (i == 0 or not (src[i - 1].isalnum() or src[i - 1] == '_'))):
            raw = ch == 'r'
            s = i + 1 if raw else i
            q = src[s]
            if src.startswith(q * 3, s):
                delim, j = q * 3, s + 3
            else:
                delim, j = q, s + 1
            while j < n:
                if not raw and src[j] == '\\':
                    j += 2
                    continue
                if src.startswith(delim, j):
                    j += len(delim)
                    break
                if len(delim) == 1 and src[j] == '\n':
                    break
                j += 1
            blank(i, j)
            i = j
        else:
            i += 1
    return ''.join(out)


def skip_ws(m, i):
    while i < len(m) and m[i].isspace():
        i += 1
    return i


def match_bracket(m, i):
    stack = []
    while i < len(m):
        c = m[i]
        if c in '([{':
            stack.append(c)
        elif c in ')]}':
            if not stack:
                return -1
            stack.pop()
            if not stack:
                return i
        i += 1
    return -1


def skip_angle(m, i):
    depth = 0
    while i < len(m):
        c = m[i]
        if c == '<':
            depth += 1
        elif c == '>':
            depth -= 1
            if depth == 0:
                return i + 1
        elif c in ';{}':
            return -1
        i += 1
    return -1


def const_span(m, i):
    """Span (start, end) of the expression that follows a `const` keyword."""
    i = skip_ws(m, i)
    n = len(m)
    if i >= n:
        return None
    if m[i] == '<':
        i = skip_angle(m, i)
        if i < 0:
            return None
        i = skip_ws(m, i)
        if i < n and m[i] in '[{(':
            e = match_bracket(m, i)
            return (i, e) if e > 0 else None
        return None
    if m[i] in '[{':
        e = match_bracket(m, i)
        return (i, e) if e > 0 else None
    mo = IDENT_RE.match(m, i)
    if not mo:
        return None
    j = skip_ws(m, mo.end())
    if j < n and m[j] == '<':
        j = skip_angle(m, j)
        if j < 0:
            return None
        j = skip_ws(m, j)
    if j < n and m[j] == '(':
        e = match_bracket(m, j)
        return (i, e) if e > 0 else None
    return None


def enclosing_call(m, pos):
    depth = 0
    i = pos - 1
    while i >= 0:
        c = m[i]
        if c in ')]}':
            depth += 1
        elif c in '([{':
            if depth == 0:
                if c == '(':
                    k = i
                    while k > 0 and (m[k - 1].isalnum() or m[k - 1] in '_.'):
                        k -= 1
                    return m[k:i]
            else:
                depth -= 1
        i -= 1
    return ''


def is_text_ctx(m, pos):
    before = m[max(0, pos - 40):pos]
    if re.search(r'\biconColor\s*:\s*$', before):
        return True
    if re.search(r'\bcolor\s*:\s*$', before):
        call = enclosing_call(m, pos)
        return call in ('TextStyle', 'Icon') or call.startswith('GoogleFonts.')
    return False


def process(path):
    src = path.read_text(encoding='utf-8')
    m = mask(src)
    edits = []          # (start, end, replacement)
    dyn = []            # positions of theme-aware tokens (for const checks)
    hex_starts = set()

    for mo in DYN_RE.finditer(m):
        dyn.append(mo.start())
        if mo.group(0) == 'AppTheme.primaryNavy' and is_text_ctx(m, mo.start()):
            edits.append((mo.start(), mo.end(), 'AppTheme.onSurfaceStrong'))

    for mo in HEX_RE.finditer(m):
        token = HEX_MAP[mo.group(1).upper()]
        if token == 'primaryNavy' and is_text_ctx(m, mo.start()):
            token = 'onSurfaceStrong'
        edits.append((mo.start(), mo.end(), 'AppTheme.' + token))
        dyn.append(mo.start())
        hex_starts.add(mo.start())

    dyn.sort()

    def has_dyn(a, b):
        k = bisect.bisect_right(dyn, a)
        return k < len(dyn) and dyn[k] < b

    for mo in re.finditer(r'\bconst\b', m):
        if mo.start() in hex_starts:
            continue
        span = const_span(m, mo.end())
        if span and has_dyn(*span):
            e = mo.end()
            while e < len(src) and src[e] in ' \t':
                e += 1
            edits.append((mo.start(), e, ''))
            continue
        d = DECL_RE.match(m, mo.end())
        if d:
            semi, depth = -1, 0
            for k in range(d.end(), len(m)):
                c = m[k]
                if c in '([{':
                    depth += 1
                elif c in ')]}':
                    depth -= 1
                elif c == ';' and depth <= 0:
                    semi = k
                    break
            if semi > 0 and has_dyn(d.end(), semi):
                edits.append((mo.start(), mo.end(), 'final'))

    if not edits:
        return 0

    out = src
    for a, b, rep in sorted(edits, reverse=True):
        out = out[:a] + rep + out[b:]

    if 'AppTheme.' in out and not re.search(
            r"import\s+['\"][^'\"]*theme/app_theme\.dart['\"]", out):
        rel = os.path.relpath(THEME_FILE, path.parent).replace(os.sep, '/')
        line = "import '%s';\n" % rel
        imports = list(re.finditer(r'^import [^\n]*;\s*$', out, re.M))
        if imports:
            pos = imports[-1].end()
            out = out[:pos] + '\n' + line.rstrip('\n') + out[pos:]
        else:
            out = line + out

    path.write_text(out, encoding='utf-8')
    return len(edits)


AUDIT = [
    ('WHITE-BG', re.compile(
        r'\b(?:color|backgroundColor|fillColor)\s*:\s*(?:const\s+)?'
        r'Colors\.white\s*[,)]')),
    ('LIGHT-HEX', re.compile(r'Color\(0xFF[D-F][0-9A-Fa-f]{5}\)')),
    ('DARK-HEX', re.compile(r'Color\(0xFF[0-2][0-9A-Fa-f]{5}\)')),
]


def main():
    total = 0
    files = sorted(p for p in LIB.rglob('*.dart')
                   if p != THEME_FILE and not p.name.endswith('.g.dart'))
    changed = []
    for p in files:
        n = process(p)
        if n:
            changed.append((p.relative_to(ROOT), n))
            total += n
    audit = []
    for p in files:
        for ln, line in enumerate(p.read_text(encoding='utf-8').splitlines(), 1):
            s = line.strip()
            if s.startswith('//'):
                continue
            for name, rx in AUDIT:
                if rx.search(s):
                    audit.append('%s:%d: %s: %s' % (p.relative_to(ROOT), ln, name, s[:110]))
    (ROOT / 'theme_audit.txt').write_text('\n'.join(audit) + '\n', encoding='utf-8')
    warn_rx = re.compile(r'\bthis\.\w+\s*=\s*(?:const\s+)?AppTheme\.(?:' + '|'.join(DYNAMIC) + r')\b')
    warnings = []
    for p in files:
        for ln, line in enumerate(p.read_text(encoding='utf-8').splitlines(), 1):
            if warn_rx.search(line):
                warnings.append('%s:%d: default parameter must be const -> fix by hand: %s'
                                % (p.relative_to(ROOT), ln, line.strip()[:100]))
    log = ['%d edits in %d files' % (total, len(changed))]
    log += warnings
    log += ['  %s: %d' % c for c in changed]
    (ROOT / 'codemod_log.txt').write_text('\n'.join(log) + '\n', encoding='utf-8')
    print('\n'.join(log))


if __name__ == '__main__':
    main()
