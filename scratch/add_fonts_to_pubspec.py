pubspec_path = r"D:\AL Quran\al_quran_app\pubspec.yaml"

with open(pubspec_path, "r", encoding="utf-8") as f:
    content = f.read()

# Generate the 47 QCF fonts YAML block
fonts_block = "\n  fonts:\n"
for i in range(1, 48):
    font_name = f"QCF_P{str(i).zfill(3)}"
    fonts_block += f"    - family: {font_name}\n"
    fonts_block += f"      fonts:\n"
    fonts_block += f"        - asset: assets/fonts/{font_name}.ttf\n"

# Remove existing commented fonts section
import re
pattern = r"  # fonts:\s*(?:  #.*\n?)*"
content_cleaned = re.sub(pattern, "", content)

# Append the fonts block at the end of the file
content_new = content_cleaned.rstrip() + "\n" + fonts_block

with open(pubspec_path, "w", encoding="utf-8") as f:
    f.write(content_new)

print("Successfully added 47 QCF v4 font registrations to end of pubspec.yaml!")
