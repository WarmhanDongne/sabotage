import google.generativeai as genai
import os
import sys

api_key = os.environ.get("GEMINI_API_KEY")
if not api_key:
    sys.exit(1)

genai.configure(api_key=api_key)
model = genai.GenerativeModel('gemini-1.5-pro')

brain_dir = r"C:\Users\USER\.gemini\antigravity-ide\brain\6958689a-021d-4e6d-ac2e-02e71fbaf3db"
img1 = os.path.join(brain_dir, "media__1783069758484.png")
img2 = os.path.join(brain_dir, "media__1783070601966.png")

try:
    file1 = genai.upload_file(path=img1)
    file2 = genai.upload_file(path=img2)
    
    prompt = """
You are an expert on the Saboteur board game rules.
The user provided these two images. 
Image 1 (media__1783069758484) is a placement they claim is INVALID and violates the rules.
Image 2 (media__1783070601966) is a placement they claim is VALID.

Please analyze the exact card placements in BOTH images.
Identify exactly WHAT rule is being violated in Image 1. 
Look at the edges where the cards meet. Look at the grid alignment. Look at the paths and walls.
Why is Image 1 a bad placement in Saboteur? What is the subtle error? Be extremely precise.
"""
    response = model.generate_content([prompt, file1, file2])
    print(response.text)
except Exception as e:
    print(e)
