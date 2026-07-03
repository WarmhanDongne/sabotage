import google.generativeai as genai
import os
import glob
import time
import json

# read api key from ask_gemini.py
api_key = ""
with open("ask_gemini.py", "r") as f:
    for line in f:
        if "api_key=" in line and "TODO" not in line:
            api_key = line.split("=")[1].strip().strip('"').strip("'")
            break

genai.configure(api_key=api_key)
model = genai.GenerativeModel('gemini-1.5-pro')

dead_ends = []

# Let's get all path cards
folders = [
    r"c:\workspace\git\sabotage\assets\board_info\004_path",
    r"c:\workspace\git\sabotage\assets\board_info\005_path",
    r"c:\workspace\git\sabotage\assets\board_info\006_path",
    r"c:\workspace\git\sabotage\assets\board_info\007_path"
]

images = []
for folder in folders:
    images.extend(glob.glob(os.path.join(folder, "*.png")))

print(f"Found {len(images)} path cards. Analyzing...")

for img_path in images:
    basename = os.path.basename(img_path)
    # Skip if it's not a path card (e.g. action cards might be mixed? No, folders are strictly paths)
    if not basename.startswith("00"): continue
    
    try:
        sample_file = genai.upload_file(path=img_path)
        prompt = """
You are an expert at Saboteur. Look at this single path card from Saboteur.
A dead-end card (막힌 굴) is a card where the path(s) abruptly end in solid rock, a wooden gate, or some blockage in the middle of the card, meaning you cannot travel completely through the card from one edge to another.
A normal path card has a continuous uninterrupted route connecting its edges.

Reply with EXACTLY ONE WORD: "DEAD_END" if it is a dead end card, or "NORMAL" if it is a normal path card.
"""
        response = model.generate_content([prompt, sample_file])
        result = response.text.strip().upper()
        print(f"{basename}: {result}")
        if "DEAD_END" in result:
            dead_ends.append(basename)
        time.sleep(2) # rate limit
    except Exception as e:
        print(f"Error on {basename}: {e}")

print("\n--- Summary of Dead Ends ---")
for d in dead_ends:
    print(d)

with open("dead_ends.json", "w") as f:
    json.dump(dead_ends, f)
