from PIL import Image, ImageDraw, ImageOps
import os

input_path = r'C:\Users\hp\.gemini\antigravity-ide\brain\fa64d146-5b92-46e2-88c7-c23ad2489922\.user_uploaded\media_1788362411005.png'
output_dir = r'C:\Users\hp\.gemini\antigravity-ide\brain\fa64d146-5b92-46e2-88c7-c23ad2489922'

img = Image.open(input_path).convert('RGBA')
w, h = img.size
print(f"Original size: {w}x{h}")

# Find bounding box using alpha channel
bbox = img.getbbox()
print(f"Detected bounding box: {bbox}")

# Crop to bounding box
cropped = img.crop(bbox)
cw, ch = cropped.size

# Make square crop based on the circular medallion
min_dim = min(cw, ch)
left = (cw - min_dim) / 2
top = (ch - min_dim) / 2
right = left + min_dim
bottom = top + min_dim
square_cropped = cropped.crop((left, top, right, bottom))

# Upscale to 4096 (4x supersampling of 1024)
large_size = 4096
target_size = 1024

large_img = square_cropped.resize((large_size, large_size), Image.Resampling.LANCZOS)

# Create high-res circular anti-aliased mask
mask = Image.new('L', (large_size, large_size), 0)
draw = ImageDraw.Draw(mask)
draw.ellipse((0, 0, large_size - 1, large_size - 1), fill=255)

# Apply mask
large_img.putalpha(mask)

# Downscale to 1024x1024 with Lanczos for smooth subpixel anti-aliasing
final_1024 = large_img.resize((target_size, target_size), Image.Resampling.LANCZOS)

out_path_1024 = os.path.join(output_dir, 'hifz_al_quran_master_1024.png')
final_1024.save(out_path_1024, 'PNG')
print(f"Saved master 1024x1024 transparent icon to: {out_path_1024}")

# Update app emblem asset
app_asset_path = r'D:\AL Quran\al_quran_app\assets\images\app_logo_emblem.png'
final_1024.save(app_asset_path, 'PNG')
print(f"Updated app emblem asset at: {app_asset_path}")

# Update mipmap sizes
mipmap_configs = {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
}

res_dir = r'D:\AL Quran\al_quran_app\android\app\src\main\res'
for folder, size in mipmap_configs.items():
    folder_path = os.path.join(res_dir, folder)
    if os.path.exists(folder_path):
        resized = final_1024.resize((size, size), Image.Resampling.LANCZOS)
        resized.save(os.path.join(folder_path, 'ic_launcher.png'), 'PNG')
        resized.save(os.path.join(folder_path, 'ic_launcher_round.png'), 'PNG')
        print(f"Generated {size}x{size} icons for {folder}")

print("Processing complete!")
