import json
import sys
import re

sys.stdout.reconfigure(encoding='utf-8')

def clean_html(text):
    if not text:
        return ""
    s = re.sub(r'</p>|<br\s*/?>|</div>', '\n', str(text), flags=re.IGNORECASE)
    s = re.sub(r'<[^>]*>', '', s)
    s = s.replace('&nbsp;', ' ').replace('&quot;', '"').replace('&amp;', '&').replace('&lt;', '<').replace('&gt;', '>').replace('&#39;', "'")
    s = re.sub(r'\n\s*\n+', '\n\n', s)
    return s.strip()

def resolve_tafseer_text(tafseer_dict, key, depth=0):
    if depth > 10:
        return ""
    val = tafseer_dict.get(key)
    if not val:
        return ""
    if isinstance(val, dict):
        return val.get('text', '')
    if isinstance(val, str):
        val_str = val.strip()
        if ':' in val_str and val_str in tafseer_dict:
            return resolve_tafseer_text(tafseer_dict, val_str, depth + 1)
        return val_str
    return str(val)

with open(r'D:\AL Quran\tafssir\arabic\ar-tafsir-ibn-kathir.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

for k in ['4:1', '4:2', '4:3', '4:4', '4:5']:
    raw = resolve_tafseer_text(data, k)
    cleaned = clean_html(raw)
    print(f'=== {k} ===\n{cleaned[:200]}\n')
