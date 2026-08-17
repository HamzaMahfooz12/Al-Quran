import json
import sys, io

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

with open(r"D:\AL Quran\indopak-nastaleeq.json", "r", encoding="utf-8") as f:
    data = json.load(f)

for surah, ayah in [(2, 127), (2, 133), (2, 137), (2, 150), (2, 159)]:
    print(f"\n=== Surah {surah}:{ayah} in indopak-nastaleeq.json ===")
    w_idx = 1
    while True:
        k = f"{surah}:{ayah}:{w_idx}"
        if k not in data:
            break
        val = data[k]
        code_units = [f"0x{ord(c):X} ('{c}')" for c in val['text']]
        print(f"  {k} id={val.get('id')} text='{val.get('text')}' code={code_units}")
        w_idx += 1

