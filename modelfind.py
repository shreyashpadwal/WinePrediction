import google.generativeai as genai

# Configure API key directly
genai.configure(api_key="AIzaSyBO2yC20Mki7TzuLki6IvlxcJeTWX7-SG8")

# List available models
models = genai.list_models()

# Print model names
for m in models:
    print(m.name)
