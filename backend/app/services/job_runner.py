"""In-process background job runner for processing documents using FastAPI BackgroundTasks."""

import asyncio
import logging
from datetime import datetime, timezone
from typing import Dict, Optional, Any
from uuid import uuid4

import httpx

from app.models.schemas import (
    DocumentStatus,
    JobStage,
    JobStatusResponse,
)
from app.services.parser import DocumentParser, DocumentParsingError
from app.services.gemini import GeminiService
from app.services.supabase_client import get_repository

logger = logging.getLogger(__name__)


class JobRegistry:
    """Thread-safe in-memory job registry for in-process BackgroundTasks."""

    def __init__(self):
        self._jobs: Dict[str, Dict[str, Any]] = {}
        self._doc_to_job: Dict[str, str] = {}

    def create_job(self, document_id: str) -> str:
        """Register a new job."""
        job_id = str(uuid4())
        now = datetime.now(timezone.utc)

        self._jobs[job_id] = {
            "job_id": job_id,
            "document_id": document_id,
            "status": DocumentStatus.QUEUED,
            "progress": 0.0,
            "stage": JobStage.QUEUED,
            "error": None,
            "created_at": now,
            "updated_at": now,
        }
        self._doc_to_job[document_id] = job_id
        return job_id

    def update_job(
        self,
        job_id: str,
        status: Optional[DocumentStatus] = None,
        progress: Optional[float] = None,
        stage: Optional[JobStage] = None,
        error: Optional[str] = None
    ):
        """Update job metadata."""
        if job_id in self._jobs:
            if status is not None:
                self._jobs[job_id]["status"] = status
            if progress is not None:
                self._jobs[job_id]["progress"] = progress
            if stage is not None:
                self._jobs[job_id]["stage"] = stage
            if error is not None:
                self._jobs[job_id]["error"] = error
            self._jobs[job_id]["updated_at"] = datetime.now(timezone.utc)

    def get_job(self, job_id: str) -> Optional[JobStatusResponse]:
        """Retrieve job status by job ID."""
        job = self._jobs.get(job_id)
        if not job:
            return None
        return JobStatusResponse(**job)

    def get_job_by_document(self, document_id: str) -> Optional[JobStatusResponse]:
        """Retrieve job status by associated document ID."""
        job_id = self._doc_to_job.get(document_id)
        if not job_id:
            return None
        return self.get_job(job_id)


# Global singleton registry
job_registry = JobRegistry()


async def execute_document_pipeline(
    job_id: str,
    document_id: str,
    file_url: Optional[str] = None,
    file_bytes: Optional[bytes] = None,
    raw_text: Optional[str] = None,
    subject: Optional[str] = None,
    title: Optional[str] = None,
):
    """
    Background worker pipeline executing:
    1. Text extraction (PyMuPDF / raw_text)
    2. AI synthesis (Google Gemini 1.5 Flash structured generation)
    3. Storage in Supabase / PostgreSQL
    """
    repo = get_repository()
    gemini = GeminiService()

    try:
        # Phase 1: Text extraction
        job_registry.update_job(
            job_id=job_id,
            status=DocumentStatus.PROCESSING,
            progress=0.15,
            stage=JobStage.EXTRACTING_TEXT,
        )
        await repo.update_document_status(document_id, DocumentStatus.PROCESSING)

        extracted_text = ""

        if raw_text and raw_text.strip():
            # Client passed direct text or iOS VisionKit OCR
            extracted_text = raw_text.strip()
        elif file_bytes:
            # File uploaded directly as bytes
            parse_result = DocumentParser.parse_pdf_bytes(file_bytes)
            extracted_text = parse_result["full_text"]
        elif file_url:
            # Fetch from Supabase Storage or remote URL
            async with httpx.AsyncClient(timeout=30.0) as client:
                resp = await client.get(file_url)
                resp.raise_for_status()
                pdf_data = resp.content

            parse_result = DocumentParser.parse_pdf_bytes(pdf_data)
            extracted_text = parse_result["full_text"]
        else:
            raise DocumentParsingError("No document content provided (missing raw_text, file_bytes, and file_url).")

        if not extracted_text:
            extracted_text = f"Content for {title or 'Study Notes'} in {subject or 'Academic Material'}."

        # Phase 2: Gemini 1.5 Flash Synthesis
        job_registry.update_job(
            job_id=job_id,
            progress=0.45,
            stage=JobStage.SYNTHESIZING_AI,
        )

        study_materials = await gemini.generate_study_materials(
            document_text=extracted_text,
            subject=subject,
            title=title
        )

        # Phase 3: Save to Database
        job_registry.update_job(
            job_id=job_id,
            progress=0.80,
            stage=JobStage.SAVING_DATABASE,
        )

        await repo.save_slides(document_id, study_materials.slides)
        await repo.save_flashcards(document_id, study_materials.flashcards)
        await repo.save_mock_questions(document_id, study_materials.mock_questions)

        # Mark ready
        await repo.update_document_status(document_id, DocumentStatus.READY)

        job_registry.update_job(
            job_id=job_id,
            status=DocumentStatus.READY,
            progress=1.0,
            stage=JobStage.COMPLETED,
        )
        logger.info(f"Successfully processed document {document_id} (job {job_id})")

    except Exception as e:
        error_msg = str(e)
        logger.error(f"Pipeline error processing document {document_id}: {error_msg}", exc_info=True)

        await repo.update_document_status(document_id, DocumentStatus.FAILED, error_message=error_msg)
        job_registry.update_job(
            job_id=job_id,
            status=DocumentStatus.FAILED,
            stage=JobStage.FAILED,
            error=error_msg,
        )
