"""Pydantic schemas for requests, responses, and structured Gemini outputs."""

from datetime import datetime
from enum import Enum
from typing import List, Optional
from uuid import UUID, uuid4
from pydantic import BaseModel, Field


class DocumentStatus(str, Enum):
    """Lifecycle status of a document."""
    QUEUED = "queued"
    PROCESSING = "processing"
    READY = "ready"
    FAILED = "failed"


class JobStage(str, Enum):
    """Processing stages for background job execution."""
    QUEUED = "queued"
    EXTRACTING_TEXT = "extracting_text"
    SYNTHESIZING_AI = "synthesizing_ai"
    SAVING_DATABASE = "saving_database"
    COMPLETED = "completed"
    FAILED = "failed"


# ==========================================
# Gemini Structured Generation Schemas
# ==========================================

class SlideItem(BaseModel):
    """Digestible slide summary representation."""
    slide_number: int = Field(..., description="Sequential number of the slide starting from 1")
    title: str = Field(..., description="Clear, concise slide title")
    content: str = Field(..., description="Bullet points or concise summary of the core concept")
    key_takeaway: Optional[str] = Field(None, description="Primary takeaway or high-yield exam point")
    formula_latex: Optional[str] = Field(None, description="LaTeX formatted formula if applicable (e.g., $E = mc^2$)")


class FlashcardItem(BaseModel):
    """Atomic spaced repetition flashcard."""
    question: str = Field(..., description="Direct, atomic question testing one concept")
    answer: str = Field(..., description="Concise, unambiguous answer")
    hint: Optional[str] = Field(None, description="Helpful hint without giving away the answer")
    interval_days: int = Field(1, description="Initial interval for spaced repetition")


class MockOption(BaseModel):
    """Multiple choice option."""
    text: str = Field(..., description="Option answer text")
    is_correct: bool = Field(..., description="True if this option is the correct answer")


class MockQuestionItem(BaseModel):
    """Practice quiz / exam question."""
    question_text: str = Field(..., description="Question stem or problem description")
    options: List[MockOption] = Field(..., min_length=2, max_length=5, description="Multiple choice options")
    explanation: str = Field(..., description="Detailed explanation of why the answer is correct")


class StudyMaterialGeneration(BaseModel):
    """Complete structured synthesis produced by Gemini."""
    slides: List[SlideItem] = Field(..., description="List of synthesized slides")
    flashcards: List[FlashcardItem] = Field(..., description="List of atomic active recall flashcards")
    mock_questions: List[MockQuestionItem] = Field(..., description="List of mock exam questions")


# ==========================================
# API Request & Response Schemas
# ==========================================

class ProcessDocumentRequest(BaseModel):
    """Request payload to initiate document processing."""
    file_url: Optional[str] = Field(None, description="URL of the uploaded file in Supabase Storage or external link")
    subject: Optional[str] = Field(None, description="Academic subject or course name (e.g. 'AP Biology', 'AP Calculus')")
    title: Optional[str] = Field(None, description="Optional custom title for the document")
    user_id: Optional[str] = Field(None, description="UUID of the student/user")
    raw_text: Optional[str] = Field(None, description="Direct text input or on-device OCR text from iOS VisionKit")


class JobStatusResponse(BaseModel):
    """Response payload for job polling."""
    job_id: str = Field(..., description="Unique job identifier")
    document_id: str = Field(..., description="Associated document ID")
    status: DocumentStatus = Field(..., description="Current status")
    progress: float = Field(..., ge=0.0, le=1.0, description="Progress from 0.0 to 1.0")
    stage: JobStage = Field(..., description="Current stage description")
    error: Optional[str] = Field(None, description="Error message if failed")
    created_at: datetime = Field(..., description="Timestamp when job was created")
    updated_at: datetime = Field(..., description="Timestamp when job was last updated")


class DocumentDetailResponse(BaseModel):
    """Full document details with generated study materials."""
    id: str = Field(..., description="Document UUID")
    user_id: str = Field(..., description="User UUID")
    title: str = Field(..., description="Document title")
    file_url: Optional[str] = Field(None, description="Storage URL")
    status: DocumentStatus = Field(..., description="Document status")
    created_at: datetime = Field(..., description="Creation timestamp")
    slides: List[SlideItem] = Field(default_factory=list, description="Synthesized slides")
    flashcards: List[FlashcardItem] = Field(default_factory=list, description="Synthesized flashcards")
    mock_questions: List[MockQuestionItem] = Field(default_factory=list, description="Synthesized mock questions")
