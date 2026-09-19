"""Unit tests for PyMuPDF document parser."""

import pytest
import pymupdf as fitz
from app.services.parser import DocumentParser, InvalidPDFError


def create_sample_pdf_bytes(text_content: str = "Cellular respiration produces ATP.") -> bytes:
    """Helper to generate a valid PDF in memory using PyMuPDF."""
    doc = fitz.open()
    page = doc.new_page()
    page.insert_text((50, 72), text_content)
    pdf_bytes = doc.tobytes()
    doc.close()
    return pdf_bytes


def test_parse_valid_pdf_bytes():
    """Test extracting text from valid PDF bytes."""
    sample_text = "Mitochondria is the powerhouse of the cell."
    pdf_bytes = create_sample_pdf_bytes(sample_text)

    result = DocumentParser.parse_pdf_bytes(pdf_bytes)

    assert result["total_pages"] == 1
    assert result["has_text"] is True
    assert sample_text in result["full_text"]
    assert len(result["pages"]) == 1
    assert result["pages"][0]["page_number"] == 1


def test_parse_empty_bytes_raises_error():
    """Test that empty bytes raise InvalidPDFError."""
    with pytest.raises(InvalidPDFError):
        DocumentParser.parse_pdf_bytes(b"")


def test_parse_corrupt_bytes_raises_error():
    """Test that corrupt/invalid bytes raise InvalidPDFError."""
    with pytest.raises(InvalidPDFError):
        DocumentParser.parse_pdf_bytes(b"not a valid pdf content")
