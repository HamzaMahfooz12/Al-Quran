import json

with open(r"D:\AL Quran\indopak-nastaleeq.json", "r", encoding="utf-8") as f:
    data = json.load(f)

print("Type of data:", type(data))
if isinstance(data, dict):
    print("Top-level keys sample:", list(data.keys())[:10])
elif isinstance(data, list):
    print("List length:", len(data))
    print("Sample item:", data[0] if len(data) > 0 else None)
    # Search for surah 2 ayah 127
    matches = [x for x in data if x.get('surah') == 2 and x.get('ayah') == 127]
    print(f"Matches for 2:127: {len(matches)}")
    for m in matches:
        print(m)

