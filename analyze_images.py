import google.generativeai as genai
import os
import sys

# Get API key from environment
api_key = os.environ.get("GEMINI_API_KEY")
if not api_key:
    print("GEMINI_API_KEY not found in environment.")
    sys.exit(1)

genai.configure(api_key=api_key)

# The model to use
model = genai.GenerativeModel('gemini-1.5-pro')

# The images are in the brain directory, but wait, the prompt says the user provided them in the current turn.
# Let's check the directory for recent files.
import glob
brain_dir = r"C:\Users\USER\.gemini\antigravity-ide\brain\6958689a-021d-4e6d-ac2e-02e71fbaf3db"
png_files = glob.glob(os.path.join(brain_dir, "*.png"))

print(f"Found {len(png_files)} PNG files.")

for f in png_files:
    try:
        sample_file = genai.upload_file(path=f)
        response = model.generate_content([
            "You are an expert Saboteur board game player. Look at this image of Saboteur cards placed on a grid. Describe exactly what cards are placed, their orientation, and their relative positions. Identify if there is any rule violation according to the official Saboteur rules (e.g., path touching wall, off-grid placement, landscape orientation). Look extremely closely at the edges between cards. Is there any edge where a path touches a wall? Describe it in detail.", 
            sample_file
        ])
        print(f"--- Analysis of {os.path.basename(f)} ---")
        print(response.text)
    except Exception as e:
        print(f"Error analyzing {f}: {e}")
