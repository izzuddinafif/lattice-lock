#!/usr/bin/env python3

import sys
import os

# Add the current directory to Python path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from main import PDFGenerator, PDFMetadata
from datetime import datetime

def test_pdf_generation():
    # Create test metadata
    metadata = PDFMetadata(
        filename="test.pdf",
        title="Test Pattern",
        batch_code="TEST001",
        algorithm="sequential",
        material_profile="standard",
        timestamp=datetime.now(),
        pattern=[[0,1,2,3,4,5,0,1],[0,1,2,3,4,5,0,1],[0,1,2,3,4,5,0,1],[0,1,2,3,4,5,0,1],[0,1,2,3,4,5,0,1],[0,1,2,3,4,5,0,1],[0,1,2,3,4,5,0,1],[0,1,2,3,4,5,0,1]],
        grid_size=8
    )

    try:
        pdf_generator = PDFGenerator()
        print("Creating PDF...")
        pdf_bytes = pdf_generator.create_professional_pdf(metadata)
        print(f"Success! Generated {len(pdf_bytes)} bytes")

        # Save to file for inspection
        with open("debug_test.pdf", "wb") as f:
            f.write(pdf_bytes)
        print("Saved as debug_test.pdf")

    except Exception as e:
        import traceback
        print(f"Error: {e}")
        print("Full traceback:")
        traceback.print_exc()

if __name__ == "__main__":
    test_pdf_generation()