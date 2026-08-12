import urllib.request, json, sys
sys.stdout.reconfigure(encoding='utf-8')

url = 'https://api.alquran.cloud/v1/edition/format/audio'
req = urllib.request.urlopen(url)
data = json.loads(req.read().decode('utf-8'))['data']

print('Sample item keys:', list(data[0].keys()))
for item in data[:15]:
    identifier = item.get('identifier', '')
    lang = item.get('language', '')
    name = item.get('name') or item.get('englishName', '')
    print(f'{identifier:<35} | Lang: {lang:<4} | Name: {name}')
