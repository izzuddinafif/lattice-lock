#!/usr/bin/env python3
"""
LatticeLock PDF Generation Backend
FastAPI backend with ReportLab for professional PDF generation
"""

from fastapi import FastAPI, HTTPException
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
from reportlab.lib.pagesizes import letter, A4
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, KeepTogether
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch, mm
from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_LEFT, TA_RIGHT
import logging
import traceback

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize FastAPI app
app = FastAPI(
    title="LatticeLock PDF Generation API",
    description="Professional PDF generation backend for LatticeLock security patterns",
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
        if v < 2 or v > 32:
            raise ValueError("Grid size must be between 2 and 32")
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

        # Metadata section
        metadata_data = [
            ["Batch Code:", metadata.batch_code],
            ["Algorithm:", metadata.algorithm],
            ["Material:", metadata.material_profile],
            ["Generated:", metadata.timestamp.strftime('%Y-%m-%d %H:%M:%S')],
            ["Grid Size:", f"{metadata.grid_size}×{metadata.grid_size}"]
        ]

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

        # Grid visualization title
        grid_title = Paragraph("Security Pattern Visualization", styles['Heading2'])
        story.append(grid_title)
        story.append(Spacer(0.05*inch, 0.05*inch))

        # Create colored grid
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

                cell_colors.append(('BACKGROUND', (row, col), (row, col), color))

        # Combine all styles into a single TableStyle
        # IMPORTANT: Order matters - cell backgrounds must come BEFORE grid lines
        all_styles = [
            ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
            ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
            ('LEFTPADDING', (0, 0), (-1, -1), 0),  # Remove padding to let Spacer control size
            ('RIGHTPADDING', (0, 0), (-1, -1), 0),
            ('TOPPADDING', (0, 0), (-1, -1), 0),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 0),
            ('BACKGROUND', (0, 0), (-1, -1), HexColor('#1E1E1E')),  # Dark background
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
        logger.info(f"Generating PDF for batch: {request.metadata.batch_code}")
        logger.info(f"Request metadata: {request.metadata}")

        # Validate data
        metadata = request.metadata

        # Generate PDF
        pdf_bytes = pdf_generator.create_professional_pdf(metadata)

        # Create filename
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        filename = f"latticelock_{metadata.batch_code}_{timestamp}.pdf"

        # Convert to base64
        pdf_base64 = base64.b64encode(pdf_bytes).decode('utf-8')

        logger.info(f"Successfully generated PDF: {filename} ({len(pdf_bytes)} bytes)")

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

# Startup event
@app.on_event("startup")
async def startup_event():
    logger.info("LatticeLock PDF Generation API starting up...")
    logger.info("CORS enabled for Flutter web integration")
    logger.info("ReportLab PDF generator initialized")

# Shutdown event
@app.on_event("shutdown")
async def shutdown_event():
    logger.info("LatticeLock PDF Generation API shutting down...")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8001,
        reload=True,
        log_level="info"
    )