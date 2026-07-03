import google.generativeai as genai
import os

try:
    api_key = os.environ.get("GEMINI_API_KEY")
    if not api_key:
        print("NO API KEY")
    else:
        print("HAS API KEY")
except Exception as e:
    print(f"Error: {e}")
