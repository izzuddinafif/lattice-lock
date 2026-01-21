#!/usr/bin/env python3
"""
LatticeLock Unified Backend
FastAPI backend with ReportLab for PDF generation and OpenCV for pattern verification
"""

from fastapi import FastAPI, HTTPException, File, UploadFile
from fastapi.exceptions import RequestValidationError
from fastapi.requests import Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field, model_validator, field_validator
from typing import List, Optional, Dict, Any
import io
import base64
from datetime import datetime
import uuid
import os
import json
import random
import numpy as np
import qrcode
from reportlab.lib.pagesizes import letter, A4
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, KeepTogether, Image
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch, mm
from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_LEFT, TA_RIGHT
import logging
import traceback
import hashlib
import numpy as np

# OpenCV imports for scanner functionality
import cv2
from PIL import Image as PILImage
from io import BytesIO

# Database imports
import sys
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from database.sqlite_db import PatternRepository, VerificationRepository

# Configure logging with UTF-8 encoding
import sys
import io

# Set UTF-8 encoding for Windows console
if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8', errors='replace')

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('backend.log', encoding='utf-8'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

# Initialize FastAPI app
app = FastAPI(
    title="LatticeLock Unified API",
    description="Combined PDF generation and pattern verification backend for LatticeLock security patterns",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

# CORS configuration - Allow all origins in development
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allow all origins
    allow_credentials=False,  # Must be False when using "*"
    allow_methods=["*"],
    allow_headers=["*"],
    expose_headers=["*"],
)

# Catch-all OPTIONS handler for all routes (ensures CORS works for all endpoints)
@app.options("/{path:path}")
async def catch_all_options(path: str):
    """Handle CORS preflight for all endpoints"""
    from fastapi.responses import Response
    return Response(
        status_code=200,
        headers={
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
            "Access-Control-Allow-Headers": "*",
        }
    )

# Exception handler for validation errors
@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    """Log detailed validation errors"""
    logger.error(f"Validation error on {request.url}: {exc.errors()}")

    # Extract error details safely
    error_details = []
    for error in exc.errors():
        error_details.append({
            "field": ".".join(str(loc) for loc in error.get("loc", [])),
            "message": error.get("msg", "Validation error"),
            "type": error.get("type", "unknown")
        })

    return JSONResponse(
        status_code=422,
        content={
            "success": False,
            "error": "Validation error",
            "details": error_details
        },
    )

# Color definitions matching the Flutter UI exactly
INK_COLORS = {
    0: colors.CMYKColor(0.84, 0, 0.05, 0, spotName='CyanAccent'),  # #00E5FF - 75°C Reactive
    1: colors.CMYKColor(1, 0, 0.12, 0.15, spotName='Cyan'),        # #00BCD4 - 75°C Protected
    2: colors.CMYKColor(0.82, 0, 0.35, 0, spotName='TealAccent'), # #1DE9B6 - 55°C Reactive
    3: colors.CMYKColor(1, 0, 0.35, 0.24, spotName='Teal'),       # #009688 - 55°C Protected
    4: colors.CMYKColor(0.79, 0.49, 0, 0, spotName='Blue'),        # #2196F3 - 35°C Marker
    5: colors.CMYKColor(0.84, 0, 0.05, 0, spotName='CyanAccent'),  # #00E5FF - Default
}

# Helper function to create hex colors for ReportLab
def HexColor(hex_string):
    """Convert hex color string to ReportLab Color object"""
    hex_string = hex_string.lstrip('#')
    if len(hex_string) == 6:
        r = int(hex_string[0:2], 16) / 255.0
        g = int(hex_string[2:4], 16) / 255.0
        b = int(hex_string[4:6], 16) / 255.0
        return colors.Color(r, g, b)
    return colors.black

# Pydantic models for data validation
class PDFMetadata(BaseModel):
    filename: str = Field(..., description="PDF filename")
    title: str = Field(..., description="PDF title")
    batch_code: str = Field(..., description="Batch identifier")
    algorithm: str = Field(..., description="Algorithm used")
    material_profile: str = Field(..., description="Material profile")
    timestamp: datetime = Field(..., description="Generation timestamp")
    pattern: List[List[int]] = Field(..., description="Grid pattern data")
    grid_size: int = Field(default=8, description="Grid size (e.g., 8 for 8x8)")
    additional_data: Dict[str, Any] = Field(default_factory=dict, description="Additional metadata")
    material_colors: Optional[Dict[str, Dict[str, int]]] = Field(None, description="Dynamic material colors (ink_id -> {r, g, b})")

    # Digital signature fields for verification
    signature: Optional[str] = Field(None, description="Digital signature (Base64)")
    pattern_hash: Optional[str] = Field(None, description="SHA-256 hash of pattern")
    manufacturer_id: Optional[str] = Field(None, description="Manufacturer identifier")
    num_inks: Optional[int] = Field(5, description="Number of ink types")

    @model_validator(mode='after')
    def validate_pattern(self):
        grid_size = self.grid_size
        pattern = self.pattern
        material_colors = self.material_colors

        if len(pattern) != grid_size:
            raise ValueError(f"Pattern must have exactly {grid_size} rows")
        for i, row in enumerate(pattern):
            if len(row) != grid_size:
                raise ValueError(f"Row {i} must have exactly {grid_size} columns")
            for cell in row:
                # Only validate against INK_COLORS if custom material_colors NOT provided
                if material_colors is None and cell not in INK_COLORS.keys():
                    raise ValueError(f"Invalid ink value {cell}. Must be one of {list(INK_COLORS.keys())}")
                # Ensure cell value is non-negative
                if cell < 0:
                    raise ValueError(f"Invalid ink value {cell}. Must be non-negative")
        return self

    @field_validator('grid_size')
    @classmethod
    def validate_grid_size(cls, v):
        if v < 3 or v > 32:
            raise ValueError("Grid size must be between 3 and 32")
        return v

class PDFGenerationRequest(BaseModel):
    metadata: PDFMetadata = Field(..., description="PDF generation metadata")

class PDFGenerationResponse(BaseModel):
    success: bool = Field(..., description="Generation success status")
    pdf_base64: Optional[str] = Field(None, description="Base64-encoded PDF data")
    filename: Optional[str] = Field(None, description="Generated filename")
    size: Optional[int] = Field(None, description="PDF size in bytes")
    message: Optional[str] = Field(None, description="Status message")
    error: Optional[str] = Field(None, description="Error message")

class PatternStorageResponse(BaseModel):
    success: bool = Field(..., description="Storage success status")
    pattern_id: Optional[int] = Field(None, description="Database pattern ID")
    uuid: Optional[str] = Field(None, description="Pattern UUID")
    message: Optional[str] = Field(None, description="Status message")
    error: Optional[str] = Field(None, description="Error message")

# ============================================================================
# Scanner Models for Image Analysis and Pattern Verification
# ============================================================================

class ColorRGB(BaseModel):
    """RGB color representation"""
    r: int
    g: int
    b: int

class MaterialInk(BaseModel):
    """Material ink definition with visual color"""
    id: int
    name: str
    visual_color: ColorRGB

class MaterialProfile(BaseModel):
    """Material profile containing ink definitions"""
    name: str
    inks: List[MaterialInk]

class ScannerRequest(BaseModel):
    """Request model for pattern verification"""
    pattern: List[int] = Field(..., description="Pattern array (3x3 to 8x8 grid)")
    algorithm: str = Field(default="auto-detect", description="Algorithm used for generation")
    extracted_colors: Optional[List[List[List[int]]]] = Field(default=None, description="Extracted RGB colors from image [row][col][rgb]")

class PatternMatch(BaseModel):
    """Represents a matching pattern found in database"""
    id: str
    inputText: str
    algorithm: str
    timestamp: str
    confidence: float

class ScannerResponse(BaseModel):
    """Response model for pattern verification"""
    found: bool
    matches: List[PatternMatch]
    partial_matches: List[PatternMatch]

class ImageAnalysisResponse(BaseModel):
    """Response model for image analysis"""
    success: bool
    grid_detected: bool
    pattern: Optional[List[int]] = None
    extracted_colors: Optional[List[List[List[int]]]] = None  # 3D array: [row][col][rgb]
    message: str
    error: Optional[str] = None

class PDFGenerator:
    def __init__(self):
        # Ink names for legend (matching Flutter UI)
        self.ink_names = {
            0: ("75°C Reactive (Data High)", "#00E5FF", colors.CMYKColor(0.84, 0, 0.05, 0, spotName='CyanAccent')),
            1: ("75°C Protected (Fake)", "#00BCD4", colors.CMYKColor(0.79, 0, 0.18, 0, spotName='Cyan')),
            2: ("55°C Reactive (Data Low)", "#1DE9B6", colors.CMYKColor(0.71, 0, 0.31, 0, spotName='Teal')),
            3: ("55°C Protected (Fake)", "#009688", colors.CMYKColor(0.72, 0, 0.33, 0.18, spotName='TealDark')),
            4: ("35°C Marker (Metadata)", "#2196F3", colors.CMYKColor(0.81, 0.38, 0, 0, spotName='Blue')),
            5: ("Special Ink", "#9C27B0", colors.CMYKColor(0.63, 0.76, 0, 0, spotName='Purple')),
        }

    def _generate_qr_code(self, metadata: PDFMetadata) -> io.BytesIO:
        """Generate QR code containing verification data"""
        # Create verification data payload
        verification_data = {
            "batch_code": metadata.batch_code,
            "algorithm": metadata.algorithm,
            "timestamp": metadata.timestamp.isoformat(),
            "grid_size": metadata.grid_size,
        }

        # Add signature if available
        if metadata.signature:
            verification_data["signature"] = metadata.signature

        # Add pattern hash if available
        if metadata.pattern_hash:
            verification_data["pattern_hash"] = metadata.pattern_hash

        # Add manufacturer ID if available
        if metadata.manufacturer_id:
            verification_data["manufacturer_id"] = metadata.manufacturer_id

        # Convert to JSON string for QR encoding
        qr_data = json.dumps(verification_data, separators=(',', ':'))

        # Generate QR code
        qr = qrcode.QRCode(
            version=1,
            error_correction=qrcode.constants.ERROR_CORRECT_L,
            box_size=10,
            border=4,
        )
        qr.add_data(qr_data)
        qr.make(fit=True)

        # Create QR code image
        img = qr.make_image(fill_color="black", back_color="white")

        # Convert to BytesIO for ReportLab
        img_buffer = io.BytesIO()
        img.save(img_buffer, format='PNG')
        img_buffer.seek(0)

        return img_buffer

    def create_professional_pdf(self, metadata: PDFMetadata) -> bytes:
        """Create a beautiful professional PDF with colored grid patterns"""
        buffer = io.BytesIO()

        # Create PDF document with A4 page size
        doc = SimpleDocTemplate(
            buffer,
            pagesize=A4,
            rightMargin=30,
            leftMargin=30,
            topMargin=30,
            bottomMargin=30
        )

        # Build PDF story
        story = []
        styles = getSampleStyleSheet()

        # Title
        title = Paragraph("LatticeLock Security Tag", styles['Title'])
        story.append(title)
        story.append(Spacer(0.2*inch, 0.2*inch))

        # Create verification section with QR code (if signature available)
        if metadata.signature or metadata.pattern_hash:
            story.append(self._create_verification_section(metadata))
            story.append(Spacer(0.2*inch, 0.2*inch))

        # Metadata section
        metadata_data = [
            ["Batch Code:", metadata.batch_code],
            ["Algorithm:", metadata.algorithm],
            ["Material:", metadata.material_profile],
            ["Generated:", metadata.timestamp.strftime('%Y-%m-%d %H:%M:%S')],
            ["Grid Size:", f"{metadata.grid_size}×{metadata.grid_size}"]
        ]

        if metadata.manufacturer_id:
            metadata_data.append(["Manufacturer:", metadata.manufacturer_id])

        if metadata.pattern_hash:
            # Show first 16 chars of hash for brevity
            hash_short = metadata.pattern_hash[:16] + "..."
            metadata_data.append(["Pattern Hash:", hash_short])

        metadata_table = Table(metadata_data, colWidths=[1.5*inch, 4*inch])
        metadata_table.setStyle(TableStyle([
            ('ALIGN', (0, 0), (0, -1), 'LEFT'),
            ('ALIGN', (1, 0), (1, -1), 'LEFT'),
            ('FONTNAME', (0, 0), (0, -1), 'Helvetica-Bold'),
            ('FONTNAME', (1, 0), (1, -1), 'Helvetica'),
            ('FONTSIZE', (0, 0), (0, -1), 11),
            ('FONTSIZE', (1, 0), (1, -1), 11),
            ('BOTTOMPADDING', (0, 0), (1, -1), 8),
            ('TOPPADDING', (0, 0), (1, -1), 8),
            ('BACKGROUND', (0, 0), (0, -1), HexColor('#f8f9fa')),
            ('BACKGROUND', (1, 0), (1, -1), colors.white),
            ('GRID', (0, 0), (1, -1), 1, HexColor('#dee2e6')),
        ]))

        story.append(metadata_table)
        story.append(Spacer(0.1*inch, 0.1*inch))

        # Create colored grid (title removed for cleaner scanning)
        story.append(self._create_colored_grid(metadata))
        story.append(Spacer(0.2*inch, 0.2*inch))

        # Add legend for ink colors
        story.append(self._create_ink_legend(metadata))
        story.append(Spacer(0.3*inch, 0.3*inch))

        # Footer section
        footer_data = [
            ["SECURITY CLASSIFICATION:", "CONFIDENTIAL"],
            ["Document ID:", f"{metadata.batch_code}_{datetime.now().strftime('%Y%m%d_%H%M%S')}"],
            ["Generated:", "LatticeLock Security System"]
        ]

        footer_table = Table(footer_data, colWidths=[2*inch, 4*inch])
        footer_table.setStyle(TableStyle([
            ('ALIGN', (0, 0), (0, -1), 'LEFT'),
            ('ALIGN', (1, 0), (1, -1), 'LEFT'),
            ('TEXTCOLOR', (0, 0), (1, -1), colors.whitesmoke),
            ('FONTNAME', (0, 0), (0, -1), 'Helvetica-Bold'),
            ('FONTNAME', (1, 0), (1, -1), 'Helvetica'),
            ('FONTSIZE', (0, 0), (1, -1), 10),
            ('BOTTOMPADDING', (0, 0), (1, -1), 8),
            ('TOPPADDING', (0, 0), (1, -1), 8),
            ('BACKGROUND', (0, 0), (1, -1), HexColor('#424242')),
        ]))

        story.append(footer_table)

        # Build PDF
        doc.build(story)

        # Get PDF bytes
        buffer.seek(0)
        pdf_bytes = buffer.getvalue()
        buffer.close()

        return pdf_bytes

    def _create_colored_grid(self, metadata: PDFMetadata):
        """Create the actual colored grid visualization matching Flutter UI"""
        grid_size = metadata.grid_size
        pattern = metadata.pattern
        material_colors = metadata.material_colors  # Get dynamic colors

        # DEBUG: Log the pattern being used for PDF generation
        logger.info(f"DEBUG PDF _create_colored_grid:")
        logger.info(f"   grid_size={grid_size}")
        logger.info(f"   pattern type={type(pattern)}, len={len(pattern) if pattern else 'N/A'}")
        if pattern:
            flat_debug = [item for row in pattern for item in row]
            logger.info(f"   pattern (flat, first 16): {flat_debug[:16]}")

        # Calculate cell size to fit within page boundaries
        # A4 page: 595 × 842 points
        # Margins: 30 points each side
        # Usable: 535 × 782 points
        # Reserve space for other elements (metadata, title, footer): ~150 points vertical
        usable_width = 535   # 595 - 30 - 30
        usable_height = 632  # 782 - 150 (reserve for title, metadata, footer)

        # Calculate max cell size that fits in both dimensions
        max_cell_width = usable_width / grid_size
        max_cell_height = usable_height / grid_size
        cell_size = min(max_cell_width, max_cell_height)

        # Ensure minimum cell size for visibility (min 10 points)
        cell_size = max(cell_size, 10)

        # Create table data for the grid
        grid_data = []
        for row in range(grid_size):
            row_data = []
            for col in range(grid_size):
                # Get the ink value for this cell
                # Note: Bounds checking not needed - validator ensures pattern is grid_size × grid_size
                ink_value = pattern[row][col]

                # Use dynamic colors if provided, otherwise fall back to static INK_COLORS
                if material_colors and str(ink_value) in material_colors:
                    rgb = material_colors[str(ink_value)]
                    color = colors.Color(rgb['r']/255.0, rgb['g']/255.0, rgb['b']/255.0)
                else:
                    color = INK_COLORS.get(ink_value, INK_COLORS[0])

                # CRITICAL FIX: Use a fixed-size Spacer to force cell height
                # Empty Paragraphs don't enforce height, but Spacers do!
                # Spacer forces exact dimensions - width x height in points
                fixed_cell = Spacer(cell_size, cell_size)
                row_data.append(fixed_cell)
            grid_data.append(row_data)

        # Set individual cell colors
        cell_colors = []
        for row in range(grid_size):
            for col in range(grid_size):
                # Note: Bounds checking not needed - validator ensures pattern is grid_size × grid_size
                ink_value = pattern[row][col]

                # Use dynamic colors if provided, otherwise fall back to static INK_COLORS
                if material_colors and str(ink_value) in material_colors:
                    rgb = material_colors[str(ink_value)]
                    color = colors.Color(rgb['r']/255.0, rgb['g']/255.0, rgb['b']/255.0)
                else:
                    color = INK_COLORS.get(ink_value, INK_COLORS[0])

                cell_colors.append(('BACKGROUND', (col, row), (col, row), color))
                # CRITICAL: ReportLab TableStyle uses (col, row) NOT (row, col)!

        # DEBUG: Log first 16 cell colors to verify
        logger.info(f"DEBUG: First 16 cell colors (row, col, ink_value):")
        for i in range(min(16, len(cell_colors))):
            style = cell_colors[i]
            row, col = style[1]
            ink_value = pattern[row][col]
            logger.info(f"   Cell ({row}, {col}): ink_value={ink_value}, color={style[3]}")

        # Combine all styles into a single TableStyle
        # IMPORTANT: Order matters - cell backgrounds must come BEFORE grid lines
        all_styles = [
            ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
            ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
            ('LEFTPADDING', (0, 0), (-1, -1), 0),  # Remove padding to let Spacer control size
            ('RIGHTPADDING', (0, 0), (-1, -1), 0),
            ('TOPPADDING', (0, 0), (-1, -1), 0),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 0),
        ]

        # Add individual cell colors FIRST (before grid lines)
        all_styles.extend(cell_colors)

        # Add grid lines LAST so they appear on top of cell backgrounds
        all_styles.extend([
            ('GRID', (0, 0), (-1, -1), 1, colors.black),  # 1pt black grid lines
            ('LINEBELOW', (0, 0), (-1, -1), 1, colors.black),  # Ensure bottom lines
            ('LINEABOVE', (0, 0), (-1, -1), 1, colors.black),  # Ensure top lines
            ('LINELEFT', (0, 0), (-1, -1), 1, colors.black),   # Ensure left lines
            ('LINERIGHT', (0, 0), (-1, -1), 1, colors.black),  # Ensure right lines
        ])

        # Create the table with BOTH colWidths AND rowHeights for SQUARE cells
        grid_table = Table(
            grid_data,
            colWidths=[cell_size]*grid_size,
            rowHeights=[cell_size]*grid_size  # Make cells SQUARE
        )
        grid_table.setStyle(TableStyle(all_styles))

        return grid_table

    def _create_ink_legend(self, metadata: PDFMetadata):
        """Create a legend showing what each color/ink represents"""
        grid_size = metadata.grid_size
        pattern = metadata.pattern
        material_colors = metadata.material_colors

        # Collect unique ink values used in this pattern
        used_inks = set()
        for row in pattern:
            for cell in row:
                used_inks.add(cell)

        # Get styles for paragraphs
        styles = getSampleStyleSheet()
        normal_style = styles["Normal"]
        normal_style.fontName = "Helvetica"
        normal_style.fontSize = 10

        # Create legend data with Paragraph-wrapped text for proper word wrapping
        legend_data = [
            [Paragraph("Ink ID", normal_style), Paragraph("Color", normal_style),
             Paragraph("RGB Color", normal_style), Paragraph("Purpose", normal_style)]
        ]

        for ink_id in sorted(used_inks):
            # Use dynamic material colors if available, otherwise fallback to hardcoded ink_names
            if material_colors and str(ink_id) in material_colors:
                rgb = material_colors[str(ink_id)]
                color_obj = colors.Color(rgb['r']/255.0, rgb['g']/255.0, rgb['b']/255.0)
                rgb_str = f"RGB({rgb['r']}, {rgb['g']}, {rgb['b']})"
                name = f"Ink {ink_id}"
                purpose = "Custom material ink"
            else:
                # Fallback to hardcoded ink_names
                name, hex_color, color_obj = self.ink_names.get(ink_id, ("Unknown", "#000000", colors.black))
                rgb_str = hex_color

                # Determine purpose based on ink ID
                purposes = {
                    0: "Data High - Critical information (reacts at 75°C)",
                    1: "Protected/Fake - Security pattern (reacts at 75°C)",
                    2: "Data Low - Standard information (reacts at 55°C)",
                    3: "Protected/Fake - Security pattern (reacts at 55°C)",
                    4: "Metadata - Labels and tracking info",
                    5: "Special - Custom applications"
                }
                purpose = purposes.get(ink_id, "Custom usage")

            # Create colored style for each ink's color swatch
            color_style = ParagraphStyle(
                'ColorSwatch',
                parent=normal_style,
                textColor=color_obj,
                fontName='Symbol',
                fontSize=16
            )

            # Wrap text in Paragraphs for proper word wrapping
            legend_data.append([
                str(ink_id),
                Paragraph('■', color_style),  # Colored square using styled Paragraph
                Paragraph(rgb_str, normal_style),
                Paragraph(purpose, normal_style)
            ])

        # FIXED: Increased column widths to prevent overflow
        # Previous widths caused overflow: Color column (0.3") too narrow for 16pt ■ character
        # New widths: Ink ID=0.8", Color=0.6", Description=1.5", Purpose=3.2" (Total: 6.1")
        col_widths = [0.8*inch, 0.6*inch, 1.5*inch, 3.2*inch]

        legend_table = Table(legend_data, colWidths=col_widths)
        legend_table.setStyle(TableStyle([
            ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
            ('FONTSIZE', (0, 0), (-1, 0), 12),
            ('BACKGROUND', (0, 0), (-1, -1), HexColor('#f8f9fa')),
            ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
            ('VALIGN', (0, 0), (-1, -1), 'TOP'),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 6),
            ('TOPPADDING', (0, 0), (-1, -1), 6),
            ('LEFTPADDING', (0, 0), (-1, -1), 6),
            ('RIGHTPADDING', (0, 0), (-1, -1), 6),
            ('GRID', (0, 0), (-1, -1), 1, HexColor('#dee2e6')),
        ]))

        # Add title
        styles = getSampleStyleSheet()
        legend_title = Paragraph("Material/Legend Reference", styles['Heading3'])
        story_parts = [legend_title, Spacer(0.1*inch, 0.1*inch), legend_table]

        return KeepTogether(story_parts)

    def _create_verification_section(self, metadata: PDFMetadata):
        """Create verification section with QR code and signature info"""
        styles = getSampleStyleSheet()

        # Generate QR code
        qr_buffer = self._generate_qr_code(metadata)

        # Create QR code image for ReportLab (1.5 inch size)
        qr_image = Image(qr_buffer, width=1.5*inch, height=1.5*inch)

        # Create verification info text
        verification_info = [
            [Paragraph("<b>Verification QR Code</b>", styles['Heading3'])],
            [Paragraph("Scan this QR code to verify authenticity", styles['Normal'])],
            [Spacer(0.1*inch, 0.1*inch)],
            [qr_image],
            [Spacer(0.1*inch, 0.1*inch)],
        ]

        # Add signature status
        if metadata.signature:
            verification_info.append([
                Paragraph("<b>Digital Signature:</b> <font color='green'>✓ Signed</font>", styles['Normal'])
            ])
        else:
            verification_info.append([
                Paragraph("<b>Digital Signature:</b> <font color='gray'>Not signed</font>", styles['Normal'])
            ])

        # Add pattern hash status
        if metadata.pattern_hash:
            verification_info.append([
                Paragraph(f"<b>Pattern Hash:</b> {metadata.pattern_hash[:32]}...", styles['Normal'])
            ])

        # Create table for verification section
        verification_table = Table(verification_info, colWidths=[5.5*inch])
        verification_table.setStyle(TableStyle([
            ('ALIGN', (0, 0), (0, -1), 'CENTER'),
            ('VALIGN', (0, 0), (0, -1), 'MIDDLE'),
            ('BACKGROUND', (0, 0), (0, -1), HexColor('#e3f2fd')),
            ('GRID', (0, 0), (0, -1), 1, HexColor('#90caf9')),
            ('LEFTPADDING', (0, 0), (0, -1), 10),
            ('RIGHTPADDING', (0, 0), (0, -1), 10),
            ('TOPPADDING', (0, 0), (0, -1), 10),
            ('BOTTOMPADDING', (0, 0), (0, -1), 10),
        ]))

        return KeepTogether([verification_table])

# Global PDF generator instance
pdf_generator = PDFGenerator()

# API Endpoints
@app.get("/", response_model=Dict[str, str])
async def root():
    """Root endpoint with API information"""
    return {
        "message": "LatticeLock PDF Generation API",
        "version": "1.0.0",
        "status": "running",
        "docs": "/docs",
        "health": "/health"
    }

@app.get("/health", response_model=Dict[str, str])
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "service": "LatticeLock PDF Generator",
        "version": "1.0.0",
        "timestamp": datetime.now().isoformat()
    }

@app.post("/generate-pdf", response_model=PDFGenerationResponse)
async def generate_pdf(request: PDFGenerationRequest):
    """Generate a beautiful PDF from pattern data"""
    try:
        logger.info(f"🎨 Generating PDF for batch: {request.metadata.batch_code}")
        logger.info(f"Request metadata: {request.metadata}")

        # Validate data
        metadata = request.metadata

        # Log pattern in readable grid format
        pattern = request.metadata.pattern
        if pattern:
            grid_size = request.metadata.grid_size
            logger.info(f"📊 Pattern Grid ({grid_size}×{grid_size}):")
            for i, row in enumerate(pattern):
                logger.info(f"  Row {i}: {row}")
            # Flatten pattern for quick reference
            flat_pattern = [item for row in pattern for item in row]
            logger.info(f"🎯 Flat Pattern ({len(flat_pattern)} values): {flat_pattern}")

        # Log material profile
        if metadata.material_colors:
            logger.info(f"🎨 Material Profile: {len(metadata.material_colors)} inks defined")
            for idx, color in enumerate(metadata.material_colors):
                logger.info(f"  Ink {idx}: RGB={color}")

        # Log algorithm and grid size
        logger.info(f"🔐 Algorithm: {metadata.algorithm}")
        logger.info(f"📏 Grid Size: {metadata.grid_size}×{metadata.grid_size} ({metadata.grid_size * metadata.grid_size} cells)")

        # Generate PDF
        logger.info(f"🖨️  Calling PDF generator...")
        pdf_bytes = pdf_generator.create_professional_pdf(metadata)

        # Create filename
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        filename = f"latticelock_{metadata.batch_code}_{timestamp}.pdf"

        # Convert to base64
        pdf_base64 = base64.b64encode(pdf_bytes).decode('utf-8')

        logger.info(f"✅ Successfully generated PDF: {filename} ({len(pdf_bytes)} bytes)")
        logger.info(f"📦 Base64 encoded size: {len(pdf_base64)} characters")

        return PDFGenerationResponse(
            success=True,
            pdf_base64=pdf_base64,
            filename=filename,
            size=len(pdf_bytes),
            message=f"PDF generated successfully: {filename}"
        )

    except Exception as e:
        logger.error(f"Error generating PDF: {str(e)}")
        logger.error(f"Traceback: {traceback.format_exc()}")
        return PDFGenerationResponse(
            success=False,
            error=f"Failed to generate PDF: {str(e)}"
        )

@app.post("/store-pattern", response_model=PatternStorageResponse)
async def store_pattern(request: PDFGenerationRequest):
    """
    Store generated pattern in SQLite database for scanner verification.

    This endpoint saves the pattern metadata to the database so the scanner
    can later verify if a physical tag is authentic or counterfeit.
    """
    try:
        metadata = request.metadata

        # Flatten 2D pattern to 1D array for storage
        flat_pattern = []
        for row in metadata.pattern:
            flat_pattern.extend(row)

        # Calculate pattern hash for quick lookup
        pattern_str = str(flat_pattern)
        pattern_hash = hashlib.sha256(pattern_str.encode()).hexdigest()

        # Store in database
        pattern_record = PatternRepository.create_pattern(
            input_text=metadata.batch_code,
            algorithm=metadata.algorithm,
            pattern=flat_pattern,
            grid_size=metadata.grid_size,
            pattern_hash=pattern_hash,
            material_colors=metadata.material_colors,
            manufacturer_id=metadata.manufacturer_id,
            additional_data=metadata.additional_data,
            signature=metadata.signature,
        )

        logger.info(f"💾 Stored pattern: {pattern_record['uuid']} for batch: {metadata.batch_code}")
        logger.info(f"📊 Stored Pattern ({metadata.grid_size}×{metadata.grid_size}): {flat_pattern}")

        return PatternStorageResponse(
            success=True,
            pattern_id=pattern_record['id'],
            uuid=str(pattern_record['uuid']),
            message=f"Pattern stored successfully with UUID: {pattern_record['uuid']}"
        )

    except Exception as e:
        logger.error(f"Error storing pattern: {str(e)}")
        logger.error(f"Traceback: {traceback.format_exc()}")
        return PatternStorageResponse(
            success=False,
            error=f"Failed to store pattern: {str(e)}"
        )

# ============================================================================
# Scanner Endpoints
# ============================================================================

def rgb_to_cielab(rgb):
    """Convert RGB to CIELAB color space for perceptual uniformity"""
    r, g, b = rgb[0], rgb[1], rgb[2]
    r, g, b = r / 255.0, g / 255.0, b / 255.0

    # RGB to XYZ
    def to_linear(c):
        return c if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4

    r_lin, g_lin, b_lin = to_linear(r), to_linear(g), to_linear(b)

    X = r_lin * 0.4124 + g_lin * 0.3576 + b_lin * 0.1805
    Y = r_lin * 0.2126 + g_lin * 0.7152 + b_lin * 0.0722
    Z = r_lin * 0.0193 + g_lin * 0.1192 + b_lin * 0.9505

    # XYZ to CIELAB (D65 illuminant)
    def to_lab(t):
        return t ** (1/3) if t > 0.008856 else 7.787 * t + 16/116

    Xn, Yn, Zn = 0.95047, 1.0, 1.08883
    L = 116 * to_lab(Y / Yn) - 16
    a = 500 * (to_lab(X / Xn) - to_lab(Y / Yn))
    b_val = 200 * (to_lab(Y / Yn) - to_lab(Z / Zn))

    return (L, a, b_val)

def find_closest_ink(color, material_profile):
    """Find the closest matching ink ID using CIELAB delta E"""
    if not material_profile or not material_profile.inks:
        return 0  # Default to ink ID 0

    lab_color = rgb_to_cielab([color['r'], color['g'], color['b']])

    min_distance = float('inf')
    closest_ink = 0

    for ink in material_profile.inks:
        ink_rgb = [ink.visual_color.r, ink.visual_color.g, ink.visual_color.b]
        lab_ink = rgb_to_cielab(ink_rgb)

        # Calculate delta E (CIELAB color difference)
        delta_e = ((lab_color[0] - lab_ink[0]) ** 2 +
                   (lab_color[1] - lab_ink[1]) ** 2 +
                   (lab_color[2] - lab_ink[2]) ** 2) ** 0.5

        if delta_e < min_distance:
            min_distance = delta_e
            closest_ink = ink.id

    return closest_ink

@app.post("/analyze-image", response_model=ImageAnalysisResponse)
async def analyze_image(file: UploadFile = File(...)):
    """
    Analyze uploaded image to detect grid (3×3 to 8×8) and extract pattern
    """
    logger.info("=" * 60)
    logger.info("📸 IMAGE ANALYSIS REQUEST RECEIVED")
    logger.info(f"Filename: {file.filename}")
    logger.info("=" * 60)

    # Set random seeds for deterministic K-means clustering
    random.seed(42)
    np.random.seed(42)

    try:
        # Read image file
        contents = await file.read()
        logger.info(f"📦 Read {len(contents)} bytes from uploaded file")

        nparr = np.frombuffer(contents, np.uint8)
        image = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

        if image is None:
            logger.error("❌ Failed to decode image")
            return ImageAnalysisResponse(
                success=False,
                grid_detected=False,
                message="Failed to decode image"
            )

        logger.info(f"✅ Image decoded successfully: {image.shape[1]}×{image.shape[0]} pixels")

        # Convert to grayscale for grid detection
        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)

        # Apply Gaussian blur to reduce noise
        blurred = cv2.GaussianBlur(gray, (5, 5), 0)

        # Apply adaptive thresholding
        thresh = cv2.adaptiveThreshold(
            blurred, 255,
            cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
            cv2.THRESH_BINARY_INV, 11, 2
        )

        # Find contours
        contours, _ = cv2.findContours(thresh, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

        # Filter contours to find the grid
        min_contour_area = 1000
        grid_contour = None

        for contour in contours:
            area = cv2.contourArea(contour)
            if area > min_contour_area:
                peri = cv2.arcLength(contour, True)
                approx = cv2.approxPolyDP(contour, 0.02 * peri, True)

                # Look for quadrilateral (grid shape)
                if len(approx) == 4:
                    grid_contour = approx
                    break

        if grid_contour is None:
            return ImageAnalysisResponse(
                success=False,
                grid_detected=False,
                message="No 8×8 grid detected in image"
            )

        # Perspective transform to get top-down view
        x, y, w, h = cv2.boundingRect(grid_contour)

        # Define default material profile (5 inks matching Flutter UI)
        default_profile = MaterialProfile(
            name="Standard Temperature-Reactive Inks",
            inks=[
                MaterialInk(id=0, name="75°C Reactive", visual_color=ColorRGB(r=0, g=229, b=255)),
                MaterialInk(id=1, name="75°C Protected", visual_color=ColorRGB(r=0, g=188, b=212)),
                MaterialInk(id=2, name="55°C Reactive", visual_color=ColorRGB(r=29, g=233, b=182)),
                MaterialInk(id=3, name="55°C Protected", visual_color=ColorRGB(r=0, g=150, b=136)),
                MaterialInk(id=4, name="35°C Marker", visual_color=ColorRGB(r=33, g=150, b=243)),
            ]
        )

        # Extract grid cells - Detect grid size using color-based segmentation
        # This approach uses color clustering instead of binary thresholding to handle grids without grid lines

        # Get the region of interest (the grid) for analysis
        # Convert BGR to RGB for color processing
        img_rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
        roi_color = img_rgb[y:y+h, x:x+w]
        roi = gray[y:y+h, x:x+w]

        logger.info(f"🎯 Grid contour detected: bounding_box={x},{y} + {w}×{h}")
        logger.info(f"📐 ROI shape: {roi.shape[1]}×{roi.shape[0]} pixels")

        # COLOR-BASED SEGMENTATION: Use K-means to find main colors and detect cells by color
        # Convert to CIELAB for better color clustering
        lab = cv2.cvtColor(roi_color, cv2.COLOR_RGB2LAB)
        lab_flat = lab.reshape(-1, 3).astype(np.float32)

        # CRITICAL FIX: Force k=3 for 3-color system
        k = 3
        criteria = (cv2.TERM_CRITERIA_EPS + cv2.TERM_CRITERIA_MAX_ITER, 10, 1.0)
        flags = cv2.KMEANS_PP_CENTERS  # Deterministic
        compactness, labels, centers = cv2.kmeans(lab_flat, k, None, criteria, 10, flags)

        best_k = 3
        best_labels = labels
        best_centers = centers

        score = compactness / (roi.shape[0] * roi.shape[1])
        logger.info(f"🎨 K-means: k={k}, score={score:.2f}")

        # Create binary masks for each cluster
        combined_mask = np.zeros_like(roi, dtype=np.uint8)
        for cluster_id in range(best_k):
            # Create mask for this cluster
            cluster_mask = (best_labels.reshape(roi.shape[:2]) == cluster_id).astype(np.uint8) * 255

            # Remove tiny noise
            kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (3, 3))
            cluster_mask = cv2.morphologyEx(cluster_mask, cv2.MORPH_OPEN, kernel)

            # Add to combined mask
            combined_mask = cv2.bitwise_or(combined_mask, cluster_mask)

        # Use combined mask for connected components
        num_labels, labels, stats, centroids = cv2.connectedComponentsWithStats(combined_mask, connectivity=8)

        # Filter out tiny components (noise) and very large components (background/artifacts)
        component_sizes = stats[:, cv2.CC_STAT_AREA]
        min_component_area = (roi.shape[0] * roi.shape[1]) / 200  # 0.5% minimum
        max_component_area = (roi.shape[0] * roi.shape[1]) / 2    # 50% maximum

        large_components = [s for s in component_sizes if min_component_area < s and s < max_component_area]
        detected_count = len(large_components)

        # DEBUG: Log top component areas and centroids
        sorted_areas = sorted(component_sizes, reverse=True)[:10]
        logger.info(f"🔦 Connected components: {detected_count} components (min_area={min_component_area:.0f}, max_area={max_component_area:.0f})")
        logger.info(f"📊 Top 10 areas: {sorted_areas}")

        # PRIMARY: Use grid line detection for accurate grid structure
        # Connected components merge same-color cells, unreliable for sparse grids (< 6×6)
        # Hough transform detects grid lines regardless of cell colors (industry standard)
        logger.info(f"🔍 Checking if grid line detection needed... (components={detected_count})")

        # Quick heuristic: if components significantly less than expected for grid size, use Hough
        # 8×8 = 64 cells, 7×7 = 49, 6×6 = 36, 5×5 = 25, 4×4 = 16, 3×3 = 9
        estimated_from_components = int((detected_count ** 0.5) + 0.5)

        # Use Hough if:
        # 1. Estimated grid is small (< 6×6) - sparse colors
        # 2. Component count is suspiciously low (< 50) - suggests merging in 8×8 or 7×7 grids
        use_hough_first = estimated_from_components < 6 or detected_count < 50

        if use_hough_first:
            logger.info(f"📐 Using Hough grid line detection FIRST (estimated={estimated_from_components}×{estimated_from_components}, components={detected_count})")

            # Detect horizontal and vertical grid lines using edge detection
            edges = cv2.Canny(roi, 50, 150)

            # Detect all lines using probabilistic Hough transform
            lines = cv2.HoughLinesP(edges, 1, np.pi/180, threshold=50,
                                   minLineLength=roi.shape[1]//4,
                                   maxLineGap=10)

            # Classify lines as horizontal or vertical based on angle
            h_positions = []
            v_positions = []

            if lines is not None:
                for line in lines:
                    x1, y1, x2, y2 = line[0]
                    # Calculate angle
                    angle = np.arctan2(y2 - y1, x2 - x1) * 180 / np.pi

                    # Horizontal lines: angle close to 0 or 180 (within 10 degrees)
                    if abs(angle) < 10 or abs(abs(angle) - 180) < 10:
                        h_positions.append((y1 + y2) // 2)
                    # Vertical lines: angle close to 90 or -90 (within 10 degrees)
                    elif abs(abs(angle) - 90) < 10:
                        v_positions.append((x1 + x2) // 2)

            # Cluster lines that are close together (within 10% of ROI size)
            # This merges multiple segments of the same grid line
            cell_size_estimate = roi.shape[0] / 8  # Assume at most 8×8
            clustering_threshold = cell_size_estimate / 2  # Half a cell size

            # Cluster horizontal lines
            if h_positions:
                h_positions.sort()
                h_clusters = []
                current_cluster = [h_positions[0]]

                for pos in h_positions[1:]:
                    if abs(pos - current_cluster[0]) < clustering_threshold:
                        current_cluster.append(pos)
                    else:
                        h_clusters.append(int(sum(current_cluster) / len(current_cluster)))
                        current_cluster = [pos]

                if current_cluster:
                    h_clusters.append(int(sum(current_cluster) / len(current_cluster)))
            else:
                h_clusters = []

            # Cluster vertical lines
            if v_positions:
                v_positions.sort()
                v_clusters = []
                current_cluster = [v_positions[0]]

                for pos in v_positions[1:]:
                    if abs(pos - current_cluster[0]) < clustering_threshold:
                        current_cluster.append(pos)
                    else:
                        v_clusters.append(int(sum(current_cluster) / len(current_cluster)))
                        current_cluster = [pos]

                if current_cluster:
                    v_clusters.append(int(sum(current_cluster) / len(current_cluster)))
            else:
                v_clusters = []

            h_count = len(h_clusters)
            v_count = len(v_clusters)

            logger.info(f"📏 Grid lines detected (clustered): {h_count} horizontal, {v_count} vertical")

            # Calculate grid size from line spacing (more robust than line count)
            # If we have N lines, they create N-1 spaces (cells) between them
            # But we also need to check if lines cover the full ROI (with borders) or just internal
            if len(h_clusters) >= 2:
                # Calculate average spacing between consecutive lines
                h_spacings = [h_clusters[i+1] - h_clusters[i] for i in range(len(h_clusters)-1)]
                avg_h_spacing = sum(h_spacings) / len(h_spacings) if h_spacings else roi.shape[0] / 3

                # Estimate grid size: how many cells of this size fit in the ROI?
                estimated_h = int(round(roi.shape[0] / avg_h_spacing)) if avg_h_spacing > 0 else 3
                estimated_h = max(3, min(8, estimated_h))

                logger.info(f"📏 Horizontal spacing: avg={avg_h_spacing:.1f}px, ROI={roi.shape[0]}px, estimated={estimated_h}×{estimated_h}")
            else:
                estimated_h = 3

            if len(v_clusters) >= 2:
                # Calculate average spacing between consecutive lines
                v_spacings = [v_clusters[i+1] - v_clusters[i] for i in range(len(v_clusters)-1)]
                avg_v_spacing = sum(v_spacings) / len(v_spacings) if v_spacings else roi.shape[1] / 3

                # Estimate grid size
                estimated_v = int(round(roi.shape[1] / avg_v_spacing)) if avg_v_spacing > 0 else 3
                estimated_v = max(3, min(8, estimated_v))

                logger.info(f"📏 Vertical spacing: avg={avg_v_spacing:.1f}px, ROI={roi.shape[1]}px, estimated={estimated_v}×{estimated_v}")
            else:
                estimated_v = 3

            # Use average for more robust detection
            grid_size = max(estimated_h, estimated_v)

            logger.info(f"✅ Hough grid line detection: {h_count}h × {v_count}v lines → {grid_size}×{grid_size} grid")

            # Generate evenly-spaced row positions based on Hough-detected grid size
            row_y_positions = [int((i + 0.5) * (h / grid_size)) for i in range(grid_size)]
            logger.info(f"✅ Generated {grid_size} evenly-spaced row positions from Hough detection")

        else:
            # FALLBACK: Use centroid-based detection for larger, dense grids (6×6 to 8×8)
            # Extract Y positions from centroids for grid size detection
            # centroids[i] = [cx, cy] for each component i (0 = background)

            # Get Y positions from centroids (skip background label 0)
            y_positions = [int(centroids[i][1]) for i in range(1, min(num_labels, 100))]
            y_positions.sort()
            logger.info(f"📍 Extracted {len(y_positions)} Y positions from centroids")

            # Cluster Y positions into rows (within 15px tolerance)
            row_y_positions = []
            current_row = [y_positions[0]]

            for y in y_positions[1:]:
                if abs(y - current_row[0]) < 15:  # Same row if within 15px
                    current_row.append(y)
                else:
                    row_y_positions.append(int(sum(current_row) / len(current_row)))
                    current_row = [y]

            if current_row:
                row_y_positions.append(int(sum(current_row) / len(current_row)))

            grid_size = len(row_y_positions)

            # Auto-detect grid size from centroids
            if grid_size >= 7 and grid_size <= 8:
                grid_size = 8
                logger.info(f"✅ Grid detected from centroids: ~8 rows, using 8×8")
            elif grid_size >= 3:
                logger.info(f"✅ Grid detected from centroids: {grid_size}×{grid_size}")
            else:
                logger.error(f"❌ Insufficient rows detected: {grid_size} (minimum 3 required)")
                return JSONResponse(
                    status_code=200,
                    content={
                        "success": False,
                        "grid_detected": False,
                        "pattern": None,
                        "extracted_colors": None,
                        "message": f"Could not detect valid grid (only {grid_size} rows found)",
                    }
                )

        if 3 <= grid_size <= 8:
            # Force square grid
            pattern = []
            extracted_colors = []

            # Sample colors at each grid position
            cell_size = w // grid_size

            # If forcing 8x8, generate evenly spaced row positions
            if grid_size == 8 and len(row_y_positions) < 8:
                row_y_positions = [int((i + 0.5) * (h / grid_size)) for i in range(grid_size)]
                logger.info(f"✅ Generated 8 evenly-spaced row positions")

            for row_idx, row_y in enumerate(row_y_positions):
                row_colors = []
                row_pattern = []

                # Calculate expected X positions for columns (evenly spaced)
                for col_idx in range(grid_size):
                    cell_x = int((col_idx + 0.5) * (w / grid_size))
                    cell_y = row_y

                    # Sample a small region around the centroid
                    sample_size = 5
                    start_y = max(0, cell_y - sample_size)
                    end_y = min(h, cell_y + sample_size)
                    start_x = max(0, cell_x - sample_size)
                    end_x = min(w, cell_x + sample_size)

                    cell_region = roi_color[start_y:end_y, start_x:end_x]

                    # Calculate median color
                    if cell_region.size > 0:
                        median_rgb = np.median(cell_region.reshape(-1, 3), axis=0)
                        r, g, b = [int(x) for x in median_rgb]
                    else:
                        r, g, b = 0, 0, 0

                    row_colors.append([r, g, b])
                    row_pattern.append(0)  # Placeholder

                extracted_colors.append(row_colors)
                pattern.extend(row_pattern)

            logger.info(f"🎯 Grid detected: {grid_size}×{grid_size}")

            # Now do K-means clustering on the extracted colors to assign pattern IDs
            all_colors = np.array([color for row in extracted_colors for color in row])
            if len(all_colors) > 0:
                # CRITICAL FIX: Force k=3 for 3-color system (Standard Set has only 3 inks)
                k = 3
                criteria = (cv2.TERM_CRITERIA_EPS + cv2.TERM_CRITERIA_MAX_ITER, 10, 1.0)
                flags = cv2.KMEANS_PP_CENTERS  # Deterministic
                compactness, labels, centers = cv2.kmeans(all_colors.astype(np.float32), k, None, criteria, 10, flags)

                best_k = 3
                best_labels = labels
                best_centers = centers

                logger.info(f"🎨 K-means clustering: k={k}, score={100000/compactness if compactness > 0 else 0:.2f}")

                # Convert cluster centers to RGB
                cluster_centers_rgb = []
                for center in best_centers:
                    rgb = [int(x) for x in center]
                    cluster_centers_rgb.append(rgb)

                # CRITICAL FIX: Detect and merge duplicate cluster centers
                # K-means can create duplicate clusters when fewer colors exist than k
                duplicate_map = {}  # Maps old cluster ID to new merged ID
                merged_centers = []
                seen_colors = []

                for i, rgb in enumerate(cluster_centers_rgb):
                    # Check if this color already exists (within small tolerance)
                    is_duplicate = False
                    for seen_idx, seen_rgb in enumerate(seen_colors):
                        # Check if colors are nearly identical (within 5 RGB units)
                        if (abs(rgb[0] - seen_rgb[0]) < 5 and
                            abs(rgb[1] - seen_rgb[1]) < 5 and
                            abs(rgb[2] - seen_rgb[2]) < 5):
                            duplicate_map[i] = seen_idx
                            is_duplicate = True
                            logger.warning(f"⚠️  Duplicate cluster detected: ID {i} RGB={tuple(rgb)} → merged with ID {seen_idx}")
                            break

                    if not is_duplicate:
                        duplicate_map[i] = len(merged_centers)
                        merged_centers.append(rgb)
                        seen_colors.append(rgb)

                if duplicate_map:
                    # Remap labels using duplicate map
                    new_labels = []
                    for label in best_labels:
                        old_id = int(label[0])
                        new_id = duplicate_map.get(old_id, old_id)
                        new_labels.append([new_id])
                    best_labels = np.array(new_labels, dtype=np.float32)
                    cluster_centers_rgb = merged_centers
                    logger.info(f"✅ Merged {len(duplicate_map)} duplicate clusters, now {len(cluster_centers_rgb)} unique colors")

                # Filter out background and grid line colors
                valid_colors = []
                for i, rgb in enumerate(cluster_centers_rgb):
                    r, g, b = rgb
                    rgb_sum = r + g + b
                    min_ch = min(r, g, b)
                    max_ch = max(r, g, b)

                    # Filter: white (min > 200), black/dark (max < 60 or sum < 120)
                    if min_ch > 200 or max_ch < 60 or rgb_sum < 120:
                        logger.info(f"   Color ID {i}: RGB={tuple(rgb)} → FILTERED (background/grid lines)")
                    else:
                        valid_colors.append(i)
                        logger.info(f"   Color ID {i}: RGB={tuple(rgb)}")

                # Track if filtering happened
                colors_filtered = len(valid_colors) < len(cluster_centers_rgb)

                if colors_filtered:
                    logger.warning(f"⚠️  Filtered {len(cluster_centers_rgb) - len(valid_colors)} colors (background/grid lines)")

                # Rebuild color ID mapping if filtering happened
                if colors_filtered:
                    old_to_new_id = {old_id: new_id for new_id, old_id in enumerate(valid_colors)}

                # Build pattern with remapped IDs
                pattern = []
                label_idx = 0
                for row_colors in extracted_colors:
                    for rgb in row_colors:
                        old_id = int(best_labels[label_idx][0])
                        label_idx += 1

                        if colors_filtered:
                            new_id = old_to_new_id.get(old_id, 0)
                        else:
                            new_id = old_id

                        pattern.append(new_id)

                logger.info(f"✅ Successfully analyzed image, extracted {len(pattern)} cell pattern")
                logger.info(f"🎨 Final pattern ({grid_size}×{grid_size}): {pattern}")

                # Validate minimum colors (accept 2 or more - patterns can use fewer inks)
                unique_colors = len(set(pattern))
                if unique_colors < 2:
                    logger.error(f"❌ Only {unique_colors} unique colors detected (minimum 2 required)")
                    return JSONResponse(
                        status_code=200,
                        content={
                            "success": False,
                            "grid_detected": True,
                            "pattern": None,
                            "extracted_colors": None,
                            "message": f"Pattern must use at least 2 unique colors (detected {unique_colors})",
                        }
                    )
                else:
                    return JSONResponse(
                        status_code=200,
                        content={
                            "success": True,
                            "grid_detected": True,
                            "pattern": pattern,
                            "extracted_colors": extracted_colors,
                            "message": f"Successfully extracted {grid_size}×{grid_size} pattern from image",
                        }
                    )

        # FALLBACK: Use grid line detection for better accuracy
        # Connected components merge same-color cells, unreliable for sparse grids (< 6×6)
        # Use Hough line detection to count actual grid lines instead of color blobs
        if grid_size < 6 or detected_count < grid_size * grid_size * 0.7:
            logger.info(f"📐 Using grid line detection (grid={grid_size}×{grid_size}, components={detected_count})")

            # Detect horizontal and vertical grid lines using edge detection
            edges = cv2.Canny(roi, 50, 150)

            # Detect all lines using probabilistic Hough transform
            lines = cv2.HoughLinesP(edges, 1, np.pi/180, threshold=50,
                                   minLineLength=roi.shape[1]//4,
                                   maxLineGap=10)

            # Classify lines as horizontal or vertical based on angle
            h_positions = []
            v_positions = []

            if lines is not None:
                for line in lines:
                    x1, y1, x2, y2 = line[0]
                    # Calculate angle
                    angle = np.arctan2(y2 - y1, x2 - x1) * 180 / np.pi

                    # Horizontal lines: angle close to 0 or 180 (within 10 degrees)
                    if abs(angle) < 10 or abs(abs(angle) - 180) < 10:
                        h_positions.append((y1 + y2) // 2)
                    # Vertical lines: angle close to 90 or -90 (within 10 degrees)
                    elif abs(abs(angle) - 90) < 10:
                        v_positions.append((x1 + x2) // 2)

            # Cluster lines that are close together (within 10% of ROI size)
            # This merges multiple segments of the same grid line
            cell_size_estimate = roi.shape[0] / 8  # Assume at most 8×8
            clustering_threshold = cell_size_estimate / 2  # Half a cell size

            # Cluster horizontal lines
            if h_positions:
                h_positions.sort()
                h_clusters = []
                current_cluster = [h_positions[0]]

                for pos in h_positions[1:]:
                    if abs(pos - current_cluster[0]) < clustering_threshold:
                        current_cluster.append(pos)
                    else:
                        h_clusters.append(int(sum(current_cluster) / len(current_cluster)))
                        current_cluster = [pos]

                if current_cluster:
                    h_clusters.append(int(sum(current_cluster) / len(current_cluster)))
            else:
                h_clusters = []

            # Cluster vertical lines
            if v_positions:
                v_positions.sort()
                v_clusters = []
                current_cluster = [v_positions[0]]

                for pos in v_positions[1:]:
                    if abs(pos - current_cluster[0]) < clustering_threshold:
                        current_cluster.append(pos)
                    else:
                        v_clusters.append(int(sum(current_cluster) / len(current_cluster)))
                        current_cluster = [pos]

                if current_cluster:
                    v_clusters.append(int(sum(current_cluster) / len(current_cluster)))
            else:
                v_clusters = []

            h_count = len(h_clusters)
            v_count = len(v_clusters)

            logger.info(f"📏 Grid lines detected (clustered): {h_count} horizontal, {v_count} vertical")

            # Calculate grid size from line spacing (more robust than line count)
            # If we have N lines, they create N-1 spaces (cells) between them
            # But we also need to check if lines cover the full ROI (with borders) or just internal
            if len(h_clusters) >= 2:
                # Calculate average spacing between consecutive lines
                h_spacings = [h_clusters[i+1] - h_clusters[i] for i in range(len(h_clusters)-1)]
                avg_h_spacing = sum(h_spacings) / len(h_spacings) if h_spacings else roi.shape[0] / 3

                # Estimate grid size: how many cells of this size fit in the ROI?
                estimated_h = int(round(roi.shape[0] / avg_h_spacing)) if avg_h_spacing > 0 else 3
                estimated_h = max(3, min(8, estimated_h))

                logger.info(f"📏 Horizontal spacing: avg={avg_h_spacing:.1f}px, ROI={roi.shape[0]}px, estimated={estimated_h}x{estimated_h}")
            else:
                estimated_h = 3

            if len(v_clusters) >= 2:
                # Calculate average spacing between consecutive lines
                v_spacings = [v_clusters[i+1] - v_clusters[i] for i in range(len(v_clusters)-1)]
                avg_v_spacing = sum(v_spacings) / len(v_spacings) if v_spacings else roi.shape[1] / 3

                # Estimate grid size
                estimated_v = int(round(roi.shape[1] / avg_v_spacing)) if avg_v_spacing > 0 else 3
                estimated_v = max(3, min(8, estimated_v))

                logger.info(f"📏 Vertical spacing: avg={avg_v_spacing:.1f}px, ROI={roi.shape[1]}px, estimated={estimated_v}x{estimated_v}")
            else:
                estimated_v = 3

            # Use average for more robust detection
            grid_size = max(estimated_h, estimated_v)

            logger.info(f"✅ Grid line detection: {h_count}h × {v_count}v lines → {grid_size}×{grid_size} grid")
        else:
            # Estimate grid size from component count (grid_size² ≈ component_count)
            import math
            estimated_grid = int(math.sqrt(detected_count))
            if estimated_grid * estimated_grid != detected_count:
                # Not a perfect square, find closest square number
                for size in range(3, 9):
                    if size * size >= detected_count:
                        estimated_grid = size
                        break

            grid_size = max(3, min(8, estimated_grid))
            logger.info(f"✅ Connected components detection: {detected_count} components → {grid_size}×{grid_size} grid")

        pattern = []
        extracted_colors = []  # Store RGB colors for each cell

        # Calculate cell size
        cell_size = w // grid_size
        if cell_size == 0:
            # Fallback if bounding box is too small
            cell_size = h // grid_size

        logger.info(f"🎯 Grid detected: {w}x{h}px, detected_size={grid_size}x{grid_size}, cell_size={cell_size}px")

        # Extract color from each cell
        for row in range(grid_size):
            row_colors = []  # Store colors for this row
            row_pattern = []  # Store pattern for this row

            for col in range(grid_size):
                # Calculate cell boundaries
                start_y = int(row * (h / grid_size))
                end_y = int((row + 1) * (h / grid_size))
                start_x = int(col * (w / grid_size))
                end_x = int((col + 1) * (w / grid_size))

                # Extract cell region
                cell = image[start_y:end_y, start_x:end_x]

                if cell.size == 0:
                    logger.warning(f"⚠️  Cell [{row},{col}] is empty, using default")
                    pattern.append(0)
                    row_colors.append([0, 0, 0])  # Default black
                    row_pattern.append(0)
                    continue

                # Sample the MODE (most common color) in the cell to avoid grid lines
                # Convert to RGB and find most frequent non-white/non-black color
                cell_rgb = cell.reshape(-1, 3)
                
                # Filter out near-white and near-black pixels
                valid_pixels = []
                for pixel in cell_rgb:
                    b, g, r = pixel
                    rgb_sum = r + g + b
                    min_ch = min(r, g, b)
                    max_ch = max(r, g, b)
                    
                    # Skip white/background and dark/grid
                    if min_ch > 200 or max_ch < 40 or rgb_sum < 100:
                        continue
                    
                    # Skip low saturation (gray/anti-aliased grid lines)
                    saturation = max_ch - min_ch
                    if saturation < 50:  # Low saturation = gray
                        continue
                    valid_pixels.append(pixel)
                
                if len(valid_pixels) == 0:
                    # Fallback to center pixel
                    center_y = cell.shape[0] // 2
                    center_x = cell.shape[1] // 2
                    b, g, r = cell[center_y, center_x]
                else:
                    # Use median of valid pixels to avoid outliers
                    valid_pixels = np.array(valid_pixels)
                    median_rgb = np.median(valid_pixels, axis=0)
                    b, g, r = [int(x) for x in median_rgb]

                # Store RGB color for response
                row_colors.append([r, g, b])
                row_pattern.append(0)  # Placeholder, will be replaced after clustering

            extracted_colors.append(row_colors)

        # PRODUCTION COLOR CLUSTERING: K-means with CIELAB color space
        # Convert all colors to CIELAB (perceptually uniform color space)
        all_colors_lab = []
        for row_colors in extracted_colors:
            for rgb in row_colors:
                # Convert BGR to LAB (OpenCV format)
                lab = cv2.cvtColor(np.uint8([[rgb]]), cv2.COLOR_BGR2LAB)[0][0]
                all_colors_lab.append(lab)

        all_colors_lab = np.array(all_colors_lab, dtype=np.float32)

        # CRITICAL FIX: Force k=3 for 3-color system
        k = 3
        criteria = (cv2.TERM_CRITERIA_EPS + cv2.TERM_CRITERIA_MAX_ITER, 20, 1.0)
        compactness, labels, centers = cv2.kmeans(
            all_colors_lab, k, None, criteria, 10, cv2.KMEANS_PP_CENTERS
        )

        best_k = 3
        best_labels = labels
        best_centers = centers

        # Calculate avg distance for logging
        if len(np.unique(labels)) > 1:
            avg_distance = 0
            for i in range(k):
                cluster_points = all_colors_lab[labels.flatten() == i]
                if len(cluster_points) > 0:
                    avg_distance += np.mean([np.linalg.norm(p - centers[i]) for p in cluster_points])
            avg_distance /= k

            score = 100 / (avg_distance + 1)
        else:
            score = -1

        best_score = score  # Set for logging later
        logger.info(f"   k={k}: score={score:.2f}")
        for i, center in enumerate(centers):
            # Convert LAB to RGB correctly
            # LAB range: L(0-100), A(-128 to 127), B(-128 to 127)
            # OpenCV expects: L(0-255), A(0-255), B(0-255) with 128 as neutral
            l, a, b = center
            lab_corrected = np.array([[
                [l * 2.55, a + 128, b + 128]
            ]], dtype=np.uint8)
            rgb = cv2.cvtColor(lab_corrected, cv2.COLOR_LAB2BGR)[0][0]
            logger.info(f"     Cluster {i}: RGB={tuple(int(x) for x in rgb)}")

        # Validate clustering quality
        if score < 2.0:  # Threshold based on avg_distance inversion
            logger.error(f"❌ Poor color clustering quality (score={score:.2f}). Pattern may have lighting issues.")
            return ImageAnalysisResponse(
                success=False,
                grid_detected=True,
                message=f"Poor image quality - colors cannot be reliably distinguished. Please improve lighting or rescan."
            )

        # Build color to ID mapping
        color_to_id = {}
        for i, color_lab in enumerate(all_colors_lab):
            cluster_id = int(best_labels[i])
            # Use LAB values as key (more precise than RGB)
            color_key = tuple(int(x) for x in color_lab)
            color_to_id[color_key] = cluster_id

        # Convert cluster centers to RGB for logging
        cluster_centers_rgb = []
        for center in best_centers:
            # Convert LAB to RGB correctly
            l, a, b = center
            lab_corrected = np.array([[
                [l * 2.55, a + 128, b + 128]
            ]], dtype=np.uint8)
            rgb = cv2.cvtColor(lab_corrected, cv2.COLOR_LAB2BGR)[0][0]
            cluster_centers_rgb.append([int(x) for x in rgb])

        # Filter out background and grid line colors
        valid_colors = []
        filtered_clusters = []
        for i, rgb in enumerate(cluster_centers_rgb):
            r, g, b = rgb
            rgb_sum = r + g + b
            min_ch = min(r, g, b)
            max_ch = max(r, g, b)
            
            # Calculate saturation
            saturation = max_ch - min_ch
            
            # Filter: white (min > 200), dark (max < 60 or sum < 120), low saturation (grays)
            if min_ch > 200 or max_ch < 60 or rgb_sum < 120 or saturation < 70:
                logger.info(f'   Color ID {i}: RGB={tuple(rgb)} -> FILTERED (background/grid/low-sat)')
            else:
                valid_colors.append(i)
                filtered_clusters.append(rgb)
                logger.info(f'   Color ID {i}: RGB={tuple(rgb)} -> VALID pattern color')

        # Track if filtering happened BEFORE we update cluster_centers_rgb
        original_cluster_count = len(cluster_centers_rgb)
        colors_filtered = len(valid_colors) < original_cluster_count

        # If we filtered out colors, we need to remap the pattern
        if colors_filtered:
            logger.warning(f"⚠️  Filtered {original_cluster_count - len(valid_colors)} colors (background/grid lines)")

            # Rebuild color ID mapping (remap valid colors to 0, 1, 2, ...)
            old_to_new_id = {old_id: new_id for new_id, old_id in enumerate(valid_colors)}

            # Remap pattern
            remapped_pattern = []
            for label in best_labels.flatten():
                old_id = int(label)
                new_id = old_to_new_id.get(old_id, 0)
                remapped_pattern.append(new_id)
            
            # Log remapping results
            logger.info(f"🔄 Remapped pattern: old_to_new_id={old_to_new_id}")
            logger.info(f"🔄 Remapped pattern (first 32): {remapped_pattern[:32]}")

            # Update labels and centers
            unique_new_ids = sorted(set(remapped_pattern))
            new_centers = [best_centers[valid_colors[i]] for i in range(len(valid_colors))]

            # Update for logging
            best_labels = np.array(remapped_pattern).reshape(-1, 1)
            best_centers = np.array(new_centers)
            best_k = len(unique_new_ids)

            # Update cluster centers RGB
            cluster_centers_rgb = []
            for center in best_centers:
                # Convert LAB to RGB correctly
                l, a, b = center
                lab_corrected = np.array([[
                    [l * 2.55, a + 128, b + 128]
                ]], dtype=np.uint8)
                rgb = cv2.cvtColor(lab_corrected, cv2.COLOR_LAB2BGR)[0][0]
                cluster_centers_rgb.append([int(x) for x in rgb])

        logger.info(f"🎨 K-means clustering: k={best_k}, score={best_score:.2f}")
        logger.info(f"🎨 Detected {best_k} unique colors (after filtering):")
        for i, center_rgb in enumerate(cluster_centers_rgb):
            logger.info(f"   Color ID {i}: RGB={tuple(center_rgb)}")

        # Assign pattern IDs based on clustering
        # If we filtered colors, use the remapped pattern; otherwise use clustering
        logger.info(f"🔍 colors_filtered={colors_filtered}, len(remapped_pattern)={len(remapped_pattern) if 'remapped_pattern' in locals() else 'N/A'}")
        
        if colors_filtered:
            # Use the remapped pattern we created earlier
            logger.info(f"✅ Using remapped_pattern (first 16: {remapped_pattern[:16]})")
            pattern = remapped_pattern
        else:
            # Use the original clustering result
            pattern = []
            for row_colors in extracted_colors:
                for rgb in row_colors:
                    # Convert to LAB for lookup
                    lab = cv2.cvtColor(np.uint8([[rgb]]), cv2.COLOR_BGR2LAB)[0][0]
                    color_key = tuple(int(x) for x in lab)
                    ink_id = color_to_id.get(color_key, 0)
                    pattern.append(ink_id)

        # Validate 3-5 unique colors
        unique_colors = len(set(pattern))
        if unique_colors < 3:
            logger.error(f"❌ Only {unique_colors} unique colors detected (minimum 3 required)")
            return ImageAnalysisResponse(
                success=False,
                grid_detected=True,
                message=f"Pattern must use at least 3 unique colors (detected {unique_colors})"
            )

        if unique_colors > 5:
            logger.warning(f"⚠️  {unique_colors} unique colors detected (maximum 5, but k-means produced {unique_colors})")

        # Update row patterns for logging
        for row_idx in range(grid_size):
            start_idx = row_idx * grid_size
            end_idx = start_idx + grid_size
            row_pattern = pattern[start_idx:end_idx]
            row_colors = extracted_colors[row_idx]

            # Format RGB values
            rgb_str = ", ".join([f"RGB={tuple(rgb)}→{pattern[start_idx + col_idx]}"
                                 for col_idx, rgb in enumerate(row_colors)])
            logger.info(f"📊 Row {row_idx}: {rgb_str}")

        logger.info(f"✅ Successfully analyzed image, extracted {len(pattern)} cell pattern")
        logger.info(f"🎨 Final pattern ({grid_size}x{grid_size}): {pattern}")
        logger.info(f"📏 Extracted colors: {len(extracted_colors)} rows × {len(extracted_colors[0]) if extracted_colors else 0} cols")

        return ImageAnalysisResponse(
            success=True,
            grid_detected=True,
            pattern=pattern,
            extracted_colors=extracted_colors,
            message=f"Successfully extracted {grid_size}×{grid_size} pattern from image"
        )

    except Exception as e:
        logger.error(f"Error analyzing image: {str(e)}")
        logger.error(f"Traceback: {traceback.format_exc()}")
        return ImageAnalysisResponse(
            success=False,
            grid_detected=False,
            message=f"Image analysis failed: {str(e)}",
            error=str(e)
        )

@app.post("/verify-pattern", response_model=ScannerResponse)
async def verify_pattern(request: ScannerRequest):
    """
    Verify pattern against database of known patterns
    """
    print("=== verify_pattern called ===", flush=True)
    logger.info("=== verify_pattern called ===")
    logger.info(f"Request: pattern length={len(request.pattern)}, algorithm={request.algorithm}, has_extracted_colors={request.extracted_colors is not None}")

    import time
    start_time = time.time()

    pattern = request.pattern
    pattern_length = len(pattern)

    # Validate pattern forms a perfect square grid (3x3 to 8x8)
    import math
    grid_size = int(math.sqrt(pattern_length))
    if grid_size * grid_size != pattern_length or grid_size < 3 or grid_size > 8:
        raise HTTPException(
            status_code=400,
            detail=f"Pattern must form a square grid from 3×3 to 8×8 (got {pattern_length} values, expected {grid_size}×{grid_size}={grid_size*grid_size})"
        )

    logger.info(f"🔍 Verifying pattern: {pattern_length} values ({grid_size}×{grid_size} grid)")
    logger.info(f"🔍 Request data: algorithm={request.algorithm}, extracted_colors={request.extracted_colors is not None}")

    # Validate 2-5 unique colors in pattern (patterns can use fewer inks)
    unique_colors = len(set(pattern))
    if unique_colors < 2:
        raise HTTPException(
            status_code=400,
            detail=f"Pattern must use at least 2 unique colors (detected {unique_colors})"
        )
    if unique_colors > 5:
        raise HTTPException(
            status_code=400,
            detail=f"Pattern must use at most 5 unique colors (detected {unique_colors})"
        )

    logger.info(f"🎨 Pattern uses {unique_colors} unique colors: {sorted(set(pattern))}")

    # COLOR MATCHING: If extracted_colors provided, match scanned RGB to stored material_colors
    remapped_pattern = pattern
    if request.extracted_colors:
        logger.info("COLOR MATCHING: Extracted colors provided, performing color matching...")

        # Validate extracted_colors dimensions
        grid_size = int(math.sqrt(len(pattern)))
        expected_rows = grid_size
        expected_cols = grid_size

        if len(request.extracted_colors) != expected_rows:
            logger.error(f"ERROR: Invalid extracted_colors: expected {expected_rows} rows, got {len(request.extracted_colors)}")
            raise HTTPException(
                status_code=400,
                detail=f"extracted_colors must have {expected_rows} rows for {grid_size}×{grid_size} grid"
            )

        # Compute average RGB for each color ID in scanned pattern
        id_to_rgb = {}  # Maps scanned ID to average RGB
        id_to_cells = {}  # Maps scanned ID to list of (row, col) positions

        for idx, color_id in enumerate(pattern):
            row = idx // grid_size
            col = idx % grid_size

            if row >= len(request.extracted_colors) or col >= len(request.extracted_colors[row]):
                logger.error(f"❌ Index out of range: row={row}, col={col}, extracted_colors shape={[len(r) for r in request.extracted_colors]}")
                raise HTTPException(
                    status_code=400,
                    detail=f"extracted_colors dimensions don't match pattern grid at position ({row}, {col})"
                )

            rgb = request.extracted_colors[row][col]  # [r, g, b]

            if color_id not in id_to_rgb:
                id_to_rgb[color_id] = [rgb[0], rgb[1], rgb[2]]
                id_to_cells[color_id] = []

            id_to_cells[color_id].append((row, col))

        logger.info(f"🎨 Scanned color IDs and RGB values:")
        for color_id in sorted(id_to_rgb.keys()):
            r, g, b = id_to_rgb[color_id]
            logger.info(f"   ID {color_id}: RGB=({r}, {g}, {b})")

        # Get all candidate patterns from database with same grid size
        candidates = PatternRepository.get_patterns_by_grid_size(grid_size)
        logger.info(f"🔍 Found {len(candidates)} candidate patterns with {grid_size}×{grid_size} grid")

        best_match = None
        best_score = 0

        for idx, candidate in enumerate(candidates):
            logger.info(f"Processing candidate {idx+1}/{len(candidates)}: ID={candidate.get('id')}")
            logger.info(f"   DEBUG: Candidate keys={list(candidate.keys())}")
            logger.info(f"   DEBUG: Has material_colors field={'material_colors' in candidate}")
            logger.info(f"   DEBUG: material_colors type={type(candidate.get('material_colors'))}")
            logger.info(f"   DEBUG: material_colors value={candidate.get('material_colors')}")
            try:
                candidate_pattern = eval(candidate['pattern']) if isinstance(candidate['pattern'], str) else candidate['pattern']
                material_colors = json.loads(candidate['material_colors']) if isinstance(candidate['material_colors'], str) else candidate['material_colors']

                # Skip patterns without material_colors (old database entries)
                if material_colors is None:
                    logger.debug(f"Skipping pattern ID {candidate['id']}: no material_colors")
                    continue

                # material_colors format: {"0": {"r": 0, "g": 229, "b": 255}, ...}
                stored_id_to_rgb = {}
                for color_id_str, rgb_dict in material_colors.items():
                    stored_id_to_rgb[int(color_id_str)] = [rgb_dict['r'], rgb_dict['g'], rgb_dict['b']]
            except Exception as e:
                logger.error(f"❌ Error processing candidate pattern ID {candidate.get('id', 'unknown')}: {e}")
                logger.error(f"   Candidate data: {candidate}")
                logger.error(f"   Traceback: {traceback.format_exc()}")
                continue

            logger.info(f"✅ Candidate {candidate.get('id')} processed successfully, continuing to matching...")

            # Find best mapping from scanned IDs to stored IDs using RGB similarity
            # This is an assignment problem - use greedy matching for simplicity
            scanned_ids = set(id_to_rgb.keys())
            stored_ids = set(stored_id_to_rgb.keys())

            logger.info(f"   DEBUG: scanned_ids={scanned_ids}, stored_ids={stored_ids}")

            # Check if scanned colors are a subset of stored colors (pattern may use fewer inks than profile)
            if not scanned_ids.issubset(stored_ids):
                logger.info(f"   SKIP: Scanned colors not in stored palette (scanned={scanned_ids}, stored={stored_ids})")
                continue  # Scanned colors don't match stored palette

            # Allow subset matching - patterns can use fewer colors than defined in material_colors
            if len(scanned_ids) > len(stored_ids):
                logger.info(f"   SKIP: More scanned colors than stored (scanned={len(scanned_ids)}, stored={len(stored_ids)})")
                continue  # Cannot have more colors than source

            if len(scanned_ids) != len(stored_ids):
                logger.info(f"   INFO: Subset color matching (scanned={len(scanned_ids)}, stored={len(stored_ids)})")
                # Continue with color mapping using available colors

            # Build mapping by minimizing RGB distance
            id_mapping = {}
            used_stored_ids = set()

            for scanned_id in scanned_ids:
                scanned_rgb = id_to_rgb[scanned_id]

                # Find closest stored color by Euclidean distance
                min_distance = float('inf')
                closest_stored_id = None

                for stored_id in stored_ids:
                    if stored_id in used_stored_ids:
                        continue

                    stored_rgb = stored_id_to_rgb[stored_id]
                    distance = math.sqrt(
                        (scanned_rgb[0] - stored_rgb[0]) ** 2 +
                        (scanned_rgb[1] - stored_rgb[1]) ** 2 +
                        (scanned_rgb[2] - stored_rgb[2]) ** 2
                    )

                    if distance < min_distance:
                        min_distance = distance
                        closest_stored_id = stored_id

                if closest_stored_id is not None:
                    id_mapping[scanned_id] = closest_stored_id
                    used_stored_ids.add(closest_stored_id)

            logger.info(f"   DEBUG: id_mapping={id_mapping}")

            # Remap pattern using this mapping
            remapped = [id_mapping.get(pid, pid) for pid in pattern]

            logger.info(f"   DEBUG: original pattern[:16]={pattern[:16]}")
            logger.info(f"   DEBUG: remapped pattern[:16]={remapped[:16]}")
            logger.info(f"   DEBUG: candidate pattern[:16]={candidate_pattern[:16]}")
            logger.info(f"   DEBUG: patterns match={remapped == candidate_pattern}")

            # Check if remapped pattern matches candidate
            if remapped == candidate_pattern:
                logger.info(f"✅ MATCH FOUND: Pattern ID {candidate['id']} ('{candidate['input_text']}')")
                logger.info(f"   Color mapping: {id_mapping}")

                # Calculate confidence based on RGB distance (lower distance = higher confidence)
                avg_distance = 0
                for scanned_id, stored_id in id_mapping.items():
                    scanned_rgb = id_to_rgb[scanned_id]
                    stored_rgb = stored_id_to_rgb[stored_id]
                    distance = math.sqrt(
                        (scanned_rgb[0] - stored_rgb[0]) ** 2 +
                        (scanned_rgb[1] - stored_rgb[1]) ** 2 +
                        (scanned_rgb[2] - stored_rgb[2]) ** 2
                    )
                    avg_distance += distance
                avg_distance /= len(id_mapping)

                # Convert distance to confidence (0-442 RGB range, map to 0-1)
                confidence = max(0, 1 - (avg_distance / 442))

                if confidence > best_score:
                    best_score = confidence
                    best_match = {
                        'uuid': candidate['uuid'],
                        'input_text': candidate['input_text'],
                        'algorithm': candidate['algorithm'],
                        'timestamp': candidate['timestamp'],
                        'confidence': confidence,
                        'id': candidate['id']
                    }

        # If we found a match, return it directly
        if best_match:
            logger.info(f"🎯 VERIFICATION SUCCESSFUL: Found match with {best_score:.2%} confidence")
            logger.info(f"Best match data: {best_match}")

            try:
                matches = [PatternMatch(
                    id=str(best_match['uuid']),
                    inputText=best_match['input_text'],
                    algorithm=best_match['algorithm'],
                    timestamp=str(best_match['timestamp']),  # Convert to string to avoid serialization issues
                    confidence=best_match['confidence']
                )]
                logger.info("PatternMatch created successfully")
            except Exception as e:
                logger.error(f"❌ Error creating PatternMatch: {e}")
                logger.error(f"best_match keys: {best_match.keys()}")
                raise

            # Log verification attempt
            response_time_ms = int((time.time() - start_time) * 1000)
            VerificationRepository.create_verification_log(
                pattern_input=pattern,
                found=True,
                matched_pattern_id=best_match['id'],
                confidence=best_match['confidence'],
                algorithm=request.algorithm,
                response_time_ms=response_time_ms
            )

            return ScannerResponse(
                found=True,
                matches=matches,
                partial_matches=[]
            )
        else:
            logger.warning("⚠️  No match found after color matching")

    try:
        # Query database for matching patterns (fallback if no extracted_colors or no match found)
        matching_patterns = PatternRepository.find_matching_patterns(
            pattern=remapped_pattern,
            exact_match=True,
            limit=10
        )

        # Convert database results to API response format
        matches = []
        found = len(matching_patterns) > 0
        matched_pattern_id = None

        for match in matching_patterns:
            matched_pattern_id = match['id']
            confidence = 1.0  # Exact match = 100%

            matches.append(PatternMatch(
                id=str(match['uuid']),
                inputText=match['input_text'],
                algorithm=match['algorithm'],
                timestamp=match['timestamp'],
                confidence=confidence
            ))

        # Log verification attempt
        response_time_ms = int((time.time() - start_time) * 1000)
        VerificationRepository.create_verification_log(
            pattern_input=pattern,
            found=found,
            matched_pattern_id=matched_pattern_id,
            confidence=matches[0].confidence if matches else None,
            algorithm=request.algorithm,
            response_time_ms=response_time_ms
        )

        logger.info(f"Pattern verification: found={found}, matches={len(matches)}, response_time={response_time_ms}ms")

        return ScannerResponse(
            found=found,
            matches=matches,
            partial_matches=[]
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error verifying pattern: {str(e)}")
        logger.error(f"Traceback: {traceback.format_exc()}")
        raise HTTPException(
            status_code=500,
            detail=f"Verification failed: {str(e)}"
        )

# Startup event
@app.on_event("startup")
async def startup_event():
    logger.info("LatticeLock PDF Generation API starting up...")
    logger.info("CORS enabled for Flutter web integration")
    logger.info("ReportLab PDF generator initialized")

    # Initialize SQLite database
    try:
        from database import init_db
        init_db.init_database()
        logger.info("SQLite database initialized successfully")
    except Exception as e:
        logger.error(f"Error initializing database: {e}")
        # Don't fail startup if DB init fails - will be created on first use

# Shutdown event
@app.on_event("shutdown")
async def shutdown_event():
    logger.info("LatticeLock PDF Generation API shutting down...")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
        log_level="info"
    )