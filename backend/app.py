#!/usr/bin/env python3
"""
LatticeLock PDF Generation Backend
Beautiful PDF generation using Python ReportLab
"""

from flask import Flask, request, jsonify, send_file
from flask_cors import CORS
import os
import io
import base64
from datetime import datetime
from reportlab.lib.pagesizes import letter, A4
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle
from reportlab.lib.styles import getSampleStyleSheet
from reportlab.lib.units import inch, mm
from reportlab.lib import colors
from reportlab.graphics.shapes import Drawing
from reportlab.graphics.widgets import TextBox
from reportlab.lib.enums import TA_CENTER, TA_LEFT
from reportlab.pdfgen import canvas
import json

app = Flask(__name__)
CORS(app)

# PDF output directory
PDF_OUTPUT_DIR = "pdfs"
os.makedirs(PDF_OUTPUT_DIR, exist_ok=True)

# Color definitions matching the UI
INK_COLORS = {
    0: (245/255, 245/255, 245/255),  # Clear (light gray)
    1: (244/255, 67/255, 54/255),   # Red
    2: (33/255, 150/255, 243/255),  # Blue
    3: (76/255, 175/255, 80/255),   # Green
    4: (33/255, 33/255, 33/255),    # Black
    5: (255/255, 193/255, 7/255),   # Yellow
}

class PDFGenerator:
    def __init__(self):
        self.cell_size = 15  # Size of each grid cell in points

    def create_beautiful_pdf(self, metadata):
        """Create a beautiful PDF with colored grid patterns"""

        # Create a PDF buffer
        buffer = io.BytesIO()

        # Create the PDF document
        doc = SimpleDocTemplate(
            buffer,
            pagesize=A4,
            rightMargin=30,
            leftMargin=30,
            topMargin=30,
            bottomMargin=30
        )

        # Build the PDF story
        story = []

        # Get styles
        styles = getSampleStyleSheet()

        # Header with gradient effect
        story.append(self._create_header(metadata, styles))
        story.append(Spacer(0.2*inch))

        # Metadata section
        story.append(self._create_metadata_section(metadata, styles))
        story.append(Spacer(0.3*inch))

        # Grid visualization title
        story.append(self._create_section_title("Security Pattern Visualization", styles))
        story.append(Spacer(0.1*inch))

        # Create the colored grid
        story.append(self._create_colored_grid(metadata))
        story.append(Spacer(0.3*inch))

        # Footer
        story.append(self._create_footer(metadata, styles))

        # Build the PDF
        doc.build(story)

        # Get the PDF bytes
        buffer.seek(0)
        pdf_bytes = buffer.getvalue()
        buffer.close()

        return pdf_bytes

    def _create_header(self, metadata, styles):
        """Create a beautiful header section"""
        # Create a canvas for the header
        elements = []

        # Title
        title = Paragraph(
            "LatticeLock Security Tag",
            styles['Title']
        )
        elements.append(title)

        # Subtitle
        subtitle = Paragraph(
            "Professional Blueprint Document",
            styles['Heading5']
        )
        elements.append(subtitle)

        # Create a simple table for layout
        header_data = [
            [title, Paragraph("", styles['Normal'])],
            [subtitle, Paragraph("", styles['Normal'])]
        ]

        header_table = Table(header_data, colWidths=[6*inch, 1*inch])
        header_table.setStyle(TableStyle([
            ('ALIGN', (0, 0), 'CENTER'),
            ('ALIGN', (1, 1), 'CENTER'),
            ('TEXTCOLOR', (0, 0), colors.whitesmoke),
            ('BACKGROUND', (0, 0), colors.Hex('#1976D2')),
            ('BACKGROUND', (1, 1), colors.Hex('#1976D2')),
            ('ROWBACKGROUNDS', [(0, 0), (colors.Hex('#1976D2'), colors.Hex('#1565C0'))],
        ]))

        return header_table

    def _create_metadata_section(self, metadata, styles):
        """Create metadata section with beautiful styling"""
        data = [
            ["Batch Code:", metadata.get('batchCode', 'N/A')],
            ["Algorithm:", metadata.get('algorithm', 'N/A')],
            ["Material:", metadata.get('materialProfile', 'N/A')],
            ["Generated:", self._format_timestamp(metadata.get('timestamp'))],
            ["Grid Size:", f"{metadata.get('gridSize', 8)}×{metadata.get('gridSize', 8)}"]
        ]

        # Create table with professional styling
        table = Table(data, colWidths=[1.5*inch, 4*inch])
        table.setStyle(TableStyle([
            ('ALIGN', (0, 0), 'LEFT'),
            ('ALIGN', (1, 1), 'LEFT'),
            ('TEXTCOLOR', (0, 0), colors.black),
            ('TEXTCOLOR', (1, 1), colors.Hex('#1976D2')),
            ('FONTNAME', (0, 0), 'Helvetica-Bold'),
            ('FONTNAME', (1, 1), 'Helvetica'),
            ('FONTSIZE', (0, 0), 11),
            ('FONTSIZE', (1, 1), 11),
            ('BOTTOMPADDING', (0, 0), 8),
            ('TOPPADDING', (0, 0), 8),
            ('BACKGROUND', (0, 0), colors.Hex('#f8f9fa')),
            ('BACKGROUND', (1, 1), colors.white),
            ('GRIDLINECOLOR', colors.Hex('#dee2e6')),
            ('ROWBACKGROUNDS', [(0, 0), (colors.Hex('#f8f9fa'), colors.white)] * 5
        ]))

        return table

    def _create_section_title(self, title, styles):
        """Create a centered section title"""
        title_paragraph = Paragraph(
            title,
            styles['Heading2']
        )

        # Wrap in a table for centering
        title_table = Table([[title_paragraph]], colWidths=[6*inch])
        title_table.setStyle(TableStyle([
            ('ALIGN', (0, 0), 'CENTER'),
            ('TEXTCOLOR', (0, 0), colors.black),
            ('BOTTOMPADDING', (0, 0), 10),
        ]))

        return title_table

    def _create_colored_grid(self, metadata):
        """Create the actual colored grid visualization"""
        grid_size = metadata.get('gridSize', 8)
        pattern = metadata.get('pattern', [])

        # Create a container for the grid
        elements = []

        # Grid dimensions
        total_size = grid_size * self.cell_size
        page_width = 6*inch  # Approximate page width

        # Calculate position to center the grid
        grid_x = (page_width - total_size) / 2

        # Create a canvas for drawing the grid
        # We'll use a custom approach with colored rectangles

        # Create a table for the grid background
        grid_data = []
        for row in range(grid_size):
            row_data = []
            for col in range(grid_size):
                # Get the ink value for this cell
                ink_value = 0  # Default
                if row < len(pattern) and col < len(pattern[row]):
                    ink_value = pattern[row][col]

                # Get the color for this ink value
                color = INK_COLORS.get(ink_value, INK_COLORS[0])

                # Create a table cell with background color
                cell_text = ""  # Empty text, just color

                row_data.append([cell_text])
            grid_data.append(row_data)

        # Create the table
        grid_table = Table(grid_data, colWidths=[self.cell_size]*grid_size)
        grid_table.setStyle(TableStyle([
            ('ALIGN', (0, -1), 'CENTER'),
            ('VALIGN', (0, -1), 'MIDDLE'),
            ('LEFTPADDING', (0, -1), 1),
            ('RIGHTPADDING', (0, -1), 1),
            ('TOPPADDING', (0, -1), 1),
            ('BOTTOMPADDING', (0, -1), 1),
            ('GRIDLINEWIDTH', (0, -1), 0.5),
            ('GRIDLINECOLOR', (0, -1), colors.Hex('#dee2e6')),
            ('ROWBACKGROUNDS', []),
            ('COLBACKGROUNDS', []),
        ]))

        # Set individual cell colors
        for row in range(grid_size):
            for col in range(grid_size):
                ink_value = 0
                if row < len(pattern) and col < len(pattern[row]):
                    ink_value = pattern[row][col]

                color = INK_COLORS.get(ink_value, INK_COLORS[0])
                hex_color = f"#{int(color[0]*255):02x}{int(color[1]*255):02x}{int(color[2]*255):02x}"

                grid_table.setStyle(TableStyle([
                    ('BACKGROUND', (row, col), hex_color),
                ], parent=grid_table))

        # Add grid border
        border_style = TableStyle([
            ('GRIDLINECOLOR', (0, -1), colors.Hex('#424242')),
            ('GRIDLINEWIDTH', (0, -1), 2),
        ], parent=grid_table)

        elements.append(grid_table)
        return elements

    def _create_footer(self, metadata, styles):
        """Create professional footer"""
        footer_data = [
            ["SECURITY CLASSIFICATION:", "CONFIDENTIAL"],
            ["Document ID:", f"{metadata.get('batchCode', 'N/A')}_{datetime.now().strftime('%Y%m%d_%H%M%S')}"],
            ["Generated:", "LatticeLock Security System"],
            ["Ink Types:", "0=Clear, 1=Red, 2=Blue, 3=Green, 4=Black, 5=Yellow"]
        ]

        footer_table = Table(footer_data, colWidths=[2*inch, 4*inch])
        footer_table.setStyle(TableStyle([
            ('ALIGN', (0, 0), 'LEFT'),
            ('ALIGN', (1, 1), 'LEFT'),
            ('TEXTCOLOR', (0, 0), colors.whitesmoke),
            ('TEXTCOLOR', (1, 1), colors.whitesmoke),
            ('FONTNAME', (0, 0), 'Helvetica-Bold'),
            ('FONTNAME', (1, 1), 'Helvetica'),
            ('FONTSIZE', (0, 0), 10),
            ('FONTSIZE', (1, 1), 10),
            ('BOTTOMPADDING', (0, 0), 8),
            ('TOPPADDING', (0, 0), 8),
            ('BACKGROUND', (0, 0), colors.Hex('#424242')),
            ('BACKGROUND', (1, 1), colors.Hex('#424242')),
            ('ROWBACKGROUNDS', [
                (colors.Hex('#424242'), colors.Hex('#424242')),
                (colors.Hex('#424242'), colors.Hex('#424242')),
                (colors.Hex('#424242'), colors.Hex('#424242')),
                (colors.Hex('#424242'), colors.Hex('#424242')),
                (colors.Hex('#424242'), colors.Hex('#424242'))
            ]
        ]))

        return footer_table

    def _format_timestamp(self, timestamp_str):
        """Format timestamp for display"""
        try:
            timestamp = datetime.fromisoformat(timestamp_str.replace('Z', '+00:00'))
            return timestamp.strftime('%Y-%m-%d %H:%M:%S')
        except:
            return timestamp_str

# Global PDF generator instance
pdf_generator = PDFGenerator()

@app.route('/generate-pdf', methods=['POST'])
def generate_pdf():
    """Generate a beautiful PDF from pattern data"""
    try:
        # Get the pattern data from the request
        data = request.get_json()

        if not data:
            return jsonify({'error': 'No data provided'}), 400

        # Generate the PDF
        pdf_bytes = pdf_generator.create_beautiful_pdf(data)

        # Create filename
        batch_code = data.get('batchCode', 'unknown')
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        filename = f"latticelock_{batch_code}_{timestamp}.pdf"

        # Save the PDF
        pdf_path = os.path.join(PDF_OUTPUT_DIR, filename)
        with open(pdf_path, 'wb') as f:
            f.write(pdf_bytes)

        # Return the PDF as base64 for the frontend
        pdf_base64 = base64.b64encode(pdf_bytes).decode('utf-8')

        return jsonify({
            'success': True,
            'pdf_base64': pdf_base64,
            'filename': filename,
            'size': len(pdf_bytes)
        })

    except Exception as e:
        print(f"Error generating PDF: {e}")
        return jsonify({
            'error': f'Failed to generate PDF: {str(e)}'
        }), 500

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'service': 'LatticeLock PDF Generator',
        'version': '1.0.0'
    })

if __name__ == '__main__':
    print("🚀 Starting LatticeLock PDF Generation Backend on http://localhost:5000")
    app.run(host='0.0.0.0', port=5000, debug=True)