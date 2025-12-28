import requests
import json
import base64
from datetime import datetime

url = "http://localhost:8001/generate-pdf"

payload = {
    "metadata": {
        "filename": "test_lattice.pdf",
        "title": "Test LatticeLock PDF",
        "batch_code": "TEST-2024-001",
        "algorithm": "chaos_logistic",
        "material_profile": "Standard Set",
        "timestamp": datetime.now().isoformat(),
        "grid_size": 8,
        "pattern": [
            [1, 2, 3, 4, 5, 1, 2, 3],
            [2, 3, 4, 5, 1, 2, 3, 4],
            [3, 4, 5, 1, 2, 3, 4, 5],
            [4, 5, 1, 2, 3, 4, 5, 1],
            [5, 1, 2, 3, 4, 5, 1, 2],
            [1, 2, 3, 4, 5, 1, 2, 3],
            [2, 3, 4, 5, 1, 2, 3, 4],
            [3, 4, 5, 1, 2, 3, 4, 5]
        ]
    }
}

print("=" * 60)
print("Testing LatticeLock Backend API")
print("=" * 60)
print(f"\nTarget URL: {url}")
print(f"Grid size: 8x8")
print(f"Pattern: {len(payload['metadata']['pattern'])} rows")
print("\nSending POST request...")
print("=" * 60)

try:
    response = requests.post(url, json=payload, timeout=30)

    print(f"\n[OK] Status Code: {response.status_code}")

    if response.status_code == 200:
        data = response.json()
        print(f"[OK] Success: {data.get('success')}")
        print(f"[FILE] Filename: {data.get('filename')}")
        print(f"[SIZE] PDF Size: {data.get('size')} bytes")

        if data.get('success') and data.get('pdf_base64'):
            pdf_base64 = data['pdf_base64']
            base64_data = pdf_base64.split(',')[1] if ',' in pdf_base64 else pdf_base64
            pdf_bytes = base64.b64decode(base64_data)

            import os
            filename = f'test_backend_output_{os.getpid()}.pdf'
            with open(filename, 'wb') as f:
                f.write(pdf_bytes)

            print(f"\n[OK] PDF saved to {filename} ({len(pdf_bytes)} bytes)")
            print("=" * 60)
            print("[SUCCESS] Backend API test PASSED")
            print("=" * 60)
            print(f"\nGenerated PDF: {filename}")
            print(f"Open location: backend/{filename}")
        else:
            error = data.get('error') or data.get('message')
            print(f"\n[ERROR] {error}")
    else:
        print(f"\n[ERROR] HTTP {response.status_code}")
        print(f"Response: {response.text[:500]}")

except requests.exceptions.Timeout:
    print("\n[ERROR] Request timed out after 30 seconds")
except requests.exceptions.ConnectionError as e:
    print(f"\n[ERROR] Could not connect to backend")
    print(f"Details: {e}")
    print("\nMake sure the backend is running:")
    print("  docker-compose -f docker-compose.local.yml up -d")
except Exception as e:
    print(f"\n[ERROR] {e}")
