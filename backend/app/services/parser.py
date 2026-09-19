"""Document parsing service using PyMuPDF for extracting structured text and metadata."""

import io
import logging
from typing import Dict, List, Any, Optional

try:
    import pymupdf as fitz
except ImportError:
    try:
        import fitz
    except ImportError:
        fitz = None

logger = logging.getLogger(__name__)


class DocumentParsingError(Exception):
    """Base exception for document parsing failures."""
    pass


class EncryptedPDFError(DocumentParsingError):
    """Raised when a PDF is password protected."""
    pass


class InvalidPDFError(DocumentParsingError):
    """Raised when the document is not a valid PDF."""
    pass


class DocumentParser:
    """Service to extract text, page layout, and metadata from PDF files using PyMuPDF."""

    @staticmethod
    def _verify_pymupdf_installed():
        if fitz is None:
            raise DocumentParsingError("PyMuPDF (fitz) is not installed. Run 'pip install pymupdf'.")

    @classmethod
    def parse_pdf_bytes(cls, pdf_bytes: bytes) -> Dict[str, Any]:
        """
        Parse PDF content from raw bytes.

        Returns a dictionary containing:
        - full_text: Aggregated text from all pages
        - pages: List of dicts with page_number and text
        - total_pages: Total number of pages
        - word_count: Total word count
        - has_text: True if extractable text is present (False if scanned/image-only)
        """
        cls._verify_pymupdf_installed()

        if not pdf_bytes or len(pdf_bytes) == 0:
            raise InvalidPDFError("PDF byte stream is empty.")

        try:
            stream = io.BytesIO(pdf_bytes)
            doc = fitz.open(stream=stream, filetype="pdf")
        except Exception as e:
            raise InvalidPDFError(f"Failed to open PDF stream: {str(e)}") from e

        return cls._extract_from_doc(doc)

    @classmethod
    def parse_pdf_file(cls, file_path: str) -> Dict[str, Any]:
        """
        Parse PDF content from a local file path.
        """
        cls._verify_pymupdf_installed()

        try:
            doc = fitz.open(file_path)
        except Exception as e:
            raise InvalidPDFError(f"Failed to open PDF file at {file_path}: {str(e)}") from e

        return cls._extract_from_doc(doc)

    @classmethod
    def _extract_from_doc(cls, doc) -> Dict[str, Any]:
        """Internal helper to extract text and metadata from an opened PyMuPDF document."""
        try:
            if doc.is_encrypted:
                raise EncryptedPDFError("The PDF document is encrypted and requires a password.")

            total_pages = len(doc)
            pages: List[Dict[str, Any]] = []
            full_text_parts: List[str] = []

            for page_idx in range(total_pages):
                page = doc[page_idx]
                page_text = page.get_text("text").strip()
                pages.append({
                    "page_number": page_idx + 1,
                    "text": page_text,
                    "char_count": len(page_text)
                })
                if page_text:
                    full_text_parts.append(f"--- Page {page_idx + 1} ---\n{page_text}")

            full_text = "\n\n".join(full_text_parts).strip()
            word_count = len(full_text.split()) if full_text else 0
            has_text = word_count > 0

            metadata = {
                "format": doc.metadata.get("format", "PDF"),
                "title": doc.metadata.get("title", ""),
                "author": doc.metadata.get("author", ""),
                "subject": doc.metadata.get("subject", ""),
                "creator": doc.metadata.get("creator", ""),
            }

            return {
                "full_text": full_text,
                "pages": pages,
                "total_pages": total_pages,
                "word_count": word_count,
                "has_text": has_text,
                "metadata": metadata,
            }
        finally:
            doc.close()
