"""API routes for Kognit document processing, job polling, and study materials retrieval."""

import logging
from typing import Optional
from uuid import uuid4

from fastapi import APIRouter, BackgroundTasks, File, Form, HTTPException, UploadFile, status

from app.models.schemas import (
    DocumentDetailResponse,
    DocumentStatus,
    JobStatusResponse,
    ProcessDocumentRequest,
)
from app.services.job_runner import execute_document_pipeline, job_registry
from app.services.supabase_client import get_repository

logger = logging.getLogger(__name__)

router = APIRouter()


@router.post(
    "/documents/process",
    response_model=JobStatusResponse,
    status_code=status.HTTP_202_ACCEPTED,
    summary="Process an uploaded document via URL or raw text",
    description="Creates a document record, queues an in-process background job, and starts text extraction and Gemini AI synthesis.",
)
async def process_document(
    request: ProcessDocumentRequest,
    background_tasks: BackgroundTasks,
):
    """
    Step 1 & 2 of Lean MVP Flow:
    Accepts document metadata/URL and kicks off background processing.
    """
    repo = get_repository()
    doc_id = str(uuid4())
    doc_title = request.title or (f"{request.subject} Notes" if request.subject else "Untitled Study Document")
    user_id = request.user_id or str(uuid4())

    # Create document record in database
    await repo.create_document(
        title=doc_title,
        file_url=request.file_url,
        user_id=user_id,
        status=DocumentStatus.QUEUED,
        document_id=doc_id,
    )

    # Register in-process background job
    job_id = job_registry.create_job(document_id=doc_id)

    # Schedule non-blocking background task
    background_tasks.add_task(
        execute_document_pipeline,
        job_id=job_id,
        document_id=doc_id,
        file_url=request.file_url,
        raw_text=request.raw_text,
        subject=request.subject,
        title=doc_title,
    )

    job_status = job_registry.get_job(job_id)
    return job_status


@router.post(
    "/documents/upload",
    response_model=JobStatusResponse,
    status_code=status.HTTP_202_ACCEPTED,
    summary="Upload a PDF document directly and process it",
    description="Accepts multipart/form-data PDF file, extracts text with PyMuPDF, and runs Gemini AI synthesis.",
)
async def upload_and_process_document(
    background_tasks: BackgroundTasks,
    file: UploadFile = File(...),
    subject: Optional[str] = Form(None),
    title: Optional[str] = Form(None),
    user_id: Optional[str] = Form(None),
):
    """
    Direct file upload endpoint for testing and clients without Supabase Storage direct uploads.
    """
    if not file.filename.lower().endswith(".pdf") and file.content_type != "application/pdf":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Only PDF documents are supported for direct document upload.",
        )

    file_bytes = await file.read()
    if not file_bytes:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Uploaded file is empty.",
        )

    repo = get_repository()
    doc_id = str(uuid4())
    doc_title = title or file.filename.replace(".pdf", "").replace("_", " ").title()
    u_id = user_id or str(uuid4())

    # Create document record
    await repo.create_document(
        title=doc_title,
        file_url=f"upload://{file.filename}",
        user_id=u_id,
        status=DocumentStatus.QUEUED,
        document_id=doc_id,
    )

    job_id = job_registry.create_job(document_id=doc_id)

    background_tasks.add_task(
        execute_document_pipeline,
        job_id=job_id,
        document_id=doc_id,
        file_bytes=file_bytes,
        subject=subject,
        title=doc_title,
    )

    job_status = job_registry.get_job(job_id)
    return job_status


@router.get(
    "/jobs/{job_id}",
    response_model=JobStatusResponse,
    summary="Poll job status by Job ID",
    description="Used by the iOS app to poll background progress (every 2s).",
)
async def get_job_status(job_id: str):
    """Poll job status for background tasks."""
    job = job_registry.get_job(job_id)
    if not job:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Job {job_id} not found.",
        )
    return job


@router.get(
    "/documents/{document_id}/status",
    response_model=JobStatusResponse,
    summary="Poll job status by Document ID",
    description="Alternative polling endpoint that maps document ID to its background job.",
)
async def get_document_status(document_id: str):
    """Retrieve job status using document_id."""
    job = job_registry.get_job_by_document(document_id)
    if not job:
        # Check if document exists in DB
        repo = get_repository()
        doc = await repo.get_document(document_id)
        if not doc:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Document {document_id} not found.",
            )
        # Construct response from DB document record
        from datetime import datetime, timezone
        from app.models.schemas import JobStage
        return JobStatusResponse(
            job_id="db-recorded",
            document_id=document_id,
            status=DocumentStatus(doc["status"]),
            progress=1.0 if doc["status"] == DocumentStatus.READY.value else 0.0,
            stage=JobStage.COMPLETED if doc["status"] == DocumentStatus.READY.value else JobStage.FAILED,
            error=doc.get("error_message"),
            created_at=datetime.fromisoformat(doc["created_at"]),
            updated_at=datetime.fromisoformat(doc["updated_at"]),
        )
    return job


@router.get(
    "/documents/{document_id}",
    response_model=DocumentDetailResponse,
    summary="Get complete study materials for a document",
    description="Returns the document along with synthesized slides, 15 flashcards, and 5 mock questions.",
)
async def get_document_details(document_id: str):
    """Retrieve full document study materials."""
    repo = get_repository()
    doc_details = await repo.get_document_full(document_id)
    if not doc_details:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Document {document_id} not found.",
        )
    return doc_details


@router.get(
    "/health",
    summary="Health check endpoint",
    description="Returns system operational status.",
)
async def health_check():
    """System health check."""
    repo = get_repository()
    return {
        "status": "healthy",
        "service": "kognit-backend",
        "database": "connected (supabase)" if not repo.use_fallback else "in-memory (fallback)",
        "gemini": "configured" if get_repository() else "mock-ready",
    }
