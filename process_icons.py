from PIL import Image
import os
import sys

source_path = r"c:/Users/sanad/.gemini/antigravity/brain/a8024690-d16d-4b00-97bf-63022ead8dc6/media__1770906059576.png"
output_dir = r"c:/Users/sanad/OneDrive/Desktop/Project ITPASS/assets/icon"

if not os.path.exists(source_path):
    print(f"Error: Source file not found at {source_path}")
    sys.exit(1)

try:
    img = Image.open(source_path)
    width, height = img.size
    print(f"Original size: {width}x{height}")

    # Split in half
    half_width = width // 2
    
    # Left: Main Icon
    # Check if there is transparency or background. usually main icon should be opaque for iOS/Legacy, 
    # but adaptive icon foreground can be transparent.
    # The user image likely has them side by side.
    
    icon_main = img.crop((0, 0, half_width, height))
    icon_mono = img.crop((half_width, 0, width, height))

    # Save
    main_path = os.path.join(output_dir, "icon_main.png")
    mono_path = os.path.join(output_dir, "icon_monochrome.png")
    
    icon_main.save(main_path)
    icon_mono.save(mono_path)
    
    print(f"Saved main icon to {main_path}")
    print(f"Saved monochrome icon to {mono_path}")

except Exception as e:
    print(f"Error processing image: {e}")
    sys.exit(1)
