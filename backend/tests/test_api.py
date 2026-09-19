"""Integration tests for FastAPI endpoints."""

import io
import pytest
from httpx import AsyncClient, ASGITransport
import pymupdf as fitz

from app.main import app
from app.services.job_runner import job_registry


def create_sample_pdf_bytes(text_content: str = "Cell division and mitosis phases.") -> bytes:
    """Helper to generate a valid PDF in memory."""
    doc = fitz.open()
    page = doc.new_page()
    page.insert_text((50, 72), text_content)
    pdf_bytes = doc.tobytes()
    doc.close()
    return pdf_bytes


@pytest.mark.asyncio
async def test_health_endpoint():
    """Test the /api/health endpoint."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get("/api/health")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "healthy"
        assert data["service"] == "kognit-backend"


@pytest.mark.asyncio
async def test_process_document_with_raw_text():
    """Test submitting document text, running background task, polling job, and retrieving results."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        payload = {
            "subject": "AP Biology",
            "title": "Cellular Respiration Notes",
            "raw_text": "Glycolysis breaks down glucose into pyruvate in the cytoplasm, yielding 2 ATP and 2 NADH. The Krebs cycle occurs in the mitochondrial matrix.",
        }

        # Step 1: Submit processing job
        response = await client.post("/api/documents/process", json=payload)
        assert response.status_code == 202
        job_data = response.json()
        job_id = job_data["job_id"]
        document_id = job_data["document_id"]
        assert job_id is not None
        assert document_id is not None

        # Step 2: Poll job status
        poll_resp = await client.get(f"/api/jobs/{job_id}")
        assert poll_resp.status_code == 200
        status_data = poll_resp.json()
        assert status_data["job_id"] == job_id
        # BackgroundTasks runs synchronously or immediately in TestClient / ASGI transport
        assert status_data["status"] in ["queued", "processing", "ready"]

        # Step 3: Check document status endpoint
        doc_status_resp = await client.get(f"/api/documents/{document_id}/status")
        assert doc_status_resp.status_code == 200

        # Step 4: Retrieve document details
        doc_details_resp = await client.get(f"/api/documents/{document_id}")
        assert doc_details_resp.status_code == 200
        doc_details = doc_details_resp.json()
        assert doc_details["id"] == document_id
        assert doc_details["title"] == "Cellular Respiration Notes"
        assert len(doc_details["slides"]) >= 4
        assert len(doc_details["flashcards"]) == 15
        assert len(doc_details["mock_questions"]) == 5


@pytest.mark.asyncio
async def test_upload_pdf_document():
    """Test multipart file upload with in-memory PDF."""
    pdf_bytes = create_sample_pdf_bytes("Mitosis consists of prophase, metaphase, anaphase, and telophase.")
    transport = ASGITransport(app=app)

    async with AsyncClient(transport=transport, base_url="http://test") as client:
        files = {"file": ("mitosis.pdf", pdf_bytes, "application/pdf")}
        data = {"subject": "AP Biology", "title": "Mitosis Summary"}

        response = await client.post("/api/documents/upload", files=files, data=data)
        assert response.status_code == 202
        job_data = response.json()
        job_id = job_data["job_id"]
        document_id = job_data["document_id"]

        # Verify job and document retrieval
        doc_details_resp = await client.get(f"/api/documents/{document_id}")
        assert doc_details_resp.status_code == 200
        doc_details = doc_details_resp.json()
        assert doc_details["title"] == "Mitosis Summary"
        assert len(doc_details["flashcards"]) == 15
