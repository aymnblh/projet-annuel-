
import re

try:
    with open('android/android_signing_report.txt', 'r', encoding='utf-16le') as f:
        content = f.read()

    # Find debug variant section
    # The file format is usually:
    # Variant: debug
    # Config: debug
    # Store: ...
    # Alias: ...
    # MD5: ...
    # SHA1: ...
    # SHA-256: ...
    
    # We'll split by "Variant:" to separate sections
    variants = content.split("Variant:")
    
    debug_section = None
    for v in variants:
        if v.strip().startswith("debug"):
             debug_section = v
             break
    
    if debug_section:
        with open('keys.txt', 'w') as kf:
            kf.write("FOUND DEBUG KEYS:\n")
            sha1 = re.search(r"SHA1:\s*([A-Fa-f0-9:]+)", debug_section)
            sha256 = re.search(r"SHA-256:\s*([A-Fa-f0-9:]+)", debug_section)
            
            if sha1:
                kf.write(f"SHA1: {sha1.group(1)}\n")
            else:
                kf.write("SHA1 not found\n")
                
            if sha256:
                 kf.write(f"SHA256: {sha256.group(1)}\n")
            else:
                 kf.write("SHA256 not found\n")
            print("Keys written to keys.txt")
    else:
        print("Debug variant not found in report.")

except Exception as e:
    print(f"Error: {e}")
