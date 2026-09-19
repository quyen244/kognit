"""Supabase and PostgreSQL repository and client with offline in-memory fallback."""

import logging
from datetime import datetime, timezone
from typing import Dict, List, Optional, Any
from uuid import uuid4

from app.config import get_settings
from app.models.schemas import (
    DocumentStatus,
    SlideItem,
    FlashcardItem,
    MockQuestionItem,
    DocumentDetailResponse,
)

logger = logging.getLogger(__name__)


class SupabaseRepository:
    """Repository handling database operations via Supabase or in-memory fallback."""

    def __init__(self):
        settings = get_settings()
        self.supabase_url = settings.supabase_url
        self.supabase_key = settings.supabase_service_role_key or settings.supabase_key
        self.client = None
        self.use_fallback = True

        # In-memory store for fallback / local testing
        self._memory_documents: Dict[str, Dict[str, Any]] = {}
        self._memory_slides: Dict[str, List[Dict[str, Any]]] = {}
        self._memory_flashcards: Dict[str, List[Dict[str, Any]]] = {}
        self._memory_mock_questions: Dict[str, List[Dict[str, Any]]] = {}

        if self.supabase_url and self.supabase_key:
            try:
                from supabase import create_client, Client
                self.client: Client = create_client(self.supabase_url, self.supabase_key)
                self.use_fallback = False
                logger.info("Connected to Supabase successfully.")
            except Exception as e:
                logger.warning(f"Could not connect to Supabase: {e}. Falling back to in-memory database.")
                self.use_fallback = True
        else:
            logger.info("Supabase credentials not configured. Using in-memory database store.")

    # --------------------------------------------------------------------------
    # Document operations
    # --------------------------------------------------------------------------

    async def create_document(
        self,
        title: str,
        file_url: Optional[str] = None,
        user_id: Optional[str] = None,
        status: DocumentStatus = DocumentStatus.QUEUED,
        document_id: Optional[str] = None
    ) -> Dict[str, Any]:
        """Create a new document record."""
        doc_id = document_id or str(uuid4())
        u_id = user_id or str(uuid4())
        now = datetime.now(timezone.utc).isoformat()

        doc_data = {
            "id": doc_id,
            "user_id": u_id,
            "title": title,
            "file_url": file_url or "",
            "status": status.value,
            "error_message": None,
            "created_at": now,
            "updated_at": now,
        }

        if not self.use_fallback and self.client:
            try:
                response = self.client.table("documents").insert(doc_data).execute()
                if response.data:
                    return response.data[0]
            except Exception as e:
                logger.error(f"Failed to insert document into Supabase: {e}. Using fallback.")

        self._memory_documents[doc_id] = doc_data
        return doc_data

    async def update_document_status(
        self,
        document_id: str,
        status: DocumentStatus,
        error_message: Optional[str] = None
    ) -> Optional[Dict[str, Any]]:
        """Update the processing status of a document."""
        now = datetime.now(timezone.utc).isoformat()
        update_data = {
            "status": status.value,
            "error_message": error_message,
            "updated_at": now,
        }

        if not self.use_fallback and self.client:
            try:
                response = (
                    self.client.table("documents")
                    .update(update_data)
                    .eq("id", document_id)
                    .execute()
                )
                if response.data:
                    return response.data[0]
            except Exception as e:
                logger.error(f"Failed to update document status in Supabase: {e}. Using fallback.")

        if document_id in self._memory_documents:
            self._memory_documents[document_id].update(update_data)
            return self._memory_documents[document_id]
        return None

    # --------------------------------------------------------------------------
    # Study Materials operations
    # --------------------------------------------------------------------------

    async def save_slides(self, document_id: str, slides: List[SlideItem]) -> List[Dict[str, Any]]:
        """Save slides associated with a document."""
        rows = [
            {
                "id": str(uuid4()),
                "document_id": document_id,
                "slide_number": slide.slide_number,
                "title": slide.title,
                "content": slide.content,
                "key_takeaway": slide.key_takeaway,
                "formula_latex": slide.formula_latex,
                "created_at": datetime.now(timezone.utc).isoformat(),
            }
            for slide in slides
        ]

        if not self.use_fallback and self.client and rows:
            try:
                response = self.client.table("slides").insert(rows).execute()
                if response.data:
                    return response.data
            except Exception as e:
                logger.error(f"Failed to insert slides into Supabase: {e}. Using fallback.")

        self._memory_slides[document_id] = rows
        return rows

    async def save_flashcards(self, document_id: str, flashcards: List[FlashcardItem]) -> List[Dict[str, Any]]:
        """Save flashcards associated with a document."""
        rows = [
            {
                "id": str(uuid4()),
                "document_id": document_id,
                "question": card.question,
                "answer": card.answer,
                "hint": card.hint,
                "interval_days": card.interval_days,
                "next_review_at": datetime.now(timezone.utc).isoformat(),
                "created_at": datetime.now(timezone.utc).isoformat(),
            }
            for card in flashcards
        ]

        if not self.use_fallback and self.client and rows:
            try:
                response = self.client.table("flashcards").insert(rows).execute()
                if response.data:
                    return response.data
            except Exception as e:
                logger.error(f"Failed to insert flashcards into Supabase: {e}. Using fallback.")

        self._memory_flashcards[document_id] = rows
        return rows

    async def save_mock_questions(self, document_id: str, mock_questions: List[MockQuestionItem]) -> List[Dict[str, Any]]:
        """Save mock questions associated with a document."""
        rows = [
            {
                "id": str(uuid4()),
                "document_id": document_id,
                "question_text": mq.question_text,
                "options": [opt.model_dump() for opt in mq.options],
                "explanation": mq.explanation,
                "created_at": datetime.now(timezone.utc).isoformat(),
            }
            for mq in mock_questions
        ]

        if not self.use_fallback and self.client and rows:
            try:
                response = self.client.table("mock_questions").insert(rows).execute()
                if response.data:
                    return response.data
            except Exception as e:
                logger.error(f"Failed to insert mock questions into Supabase: {e}. Using fallback.")

        self._memory_mock_questions[document_id] = rows
        return rows

    # --------------------------------------------------------------------------
    # Retrieval operations
    # --------------------------------------------------------------------------

    async def get_document(self, document_id: str) -> Optional[Dict[str, Any]]:
        """Get document record by ID."""
        if not self.use_fallback and self.client:
            try:
                response = (
                    self.client.table("documents")
                    .select("*")
                    .eq("id", document_id)
                    .execute()
                )
                if response.data:
                    return response.data[0]
            except Exception as e:
                logger.error(f"Failed to fetch document from Supabase: {e}. Using fallback.")

        return self._memory_documents.get(document_id)

    async def get_document_full(self, document_id: str) -> Optional[DocumentDetailResponse]:
        """Fetch document and all associated study materials."""
        doc = await self.get_document(document_id)
        if not doc:
            return None

        # Fetch slides
        slides: List[SlideItem] = []
        if not self.use_fallback and self.client:
            try:
                res = (
                    self.client.table("slides")
                    .select("*")
                    .eq("document_id", document_id)
                    .order("slide_number")
                    .execute()
                )
                slides = [
                    SlideItem(
                        slide_number=s["slide_number"],
                        title=s["title"],
                        content=s["content"],
                        key_takeaway=s.get("key_takeaway"),
                        formula_latex=s.get("formula_latex"),
                    )
                    for s in (res.data or [])
                ]
            except Exception as e:
                logger.error(f"Failed to fetch slides from Supabase: {e}")
        if not slides and document_id in self._memory_slides:
            slides = [
                SlideItem(
                    slide_number=s["slide_number"],
                    title=s["title"],
                    content=s["content"],
                    key_takeaway=s.get("key_takeaway"),
                    formula_latex=s.get("formula_latex"),
                )
                for s in self._memory_slides[document_id]
            ]

        # Fetch flashcards
        flashcards: List[FlashcardItem] = []
        if not self.use_fallback and self.client:
            try:
                res = (
                    self.client.table("flashcards")
                    .select("*")
                    .eq("document_id", document_id)
                    .execute()
                )
                flashcards = [
                    FlashcardItem(
                        question=f["question"],
                        answer=f["answer"],
                        hint=f.get("hint"),
                        interval_days=f.get("interval_days", 1),
                    )
                    for f in (res.data or [])
                ]
            except Exception as e:
                logger.error(f"Failed to fetch flashcards from Supabase: {e}")
        if not flashcards and document_id in self._memory_flashcards:
            flashcards = [
                FlashcardItem(
                    question=f["question"],
                    answer=f["answer"],
                    hint=f.get("hint"),
                    interval_days=f.get("interval_days", 1),
                )
                for f in self._memory_flashcards[document_id]
            ]

        # Fetch mock questions
        mock_questions: List[MockQuestionItem] = []
        if not self.use_fallback and self.client:
            try:
                res = (
                    self.client.table("mock_questions")
                    .select("*")
                    .eq("document_id", document_id)
                    .execute()
                )
                mock_questions = [
                    MockQuestionItem(
                        question_text=mq["question_text"],
                        options=mq["options"],
                        explanation=mq["explanation"],
                    )
                    for mq in (res.data or [])
                ]
            except Exception as e:
                logger.error(f"Failed to fetch mock questions from Supabase: {e}")
        if not mock_questions and document_id in self._memory_mock_questions:
            mock_questions = [
                MockQuestionItem(
                    question_text=mq["question_text"],
                    options=mq["options"],
                    explanation=mq["explanation"],
                )
                for mq in self._memory_mock_questions[document_id]
            ]

        return DocumentDetailResponse(
            id=doc["id"],
            user_id=doc["user_id"],
            title=doc["title"],
            file_url=doc.get("file_url"),
            status=DocumentStatus(doc["status"]),
            created_at=datetime.fromisoformat(doc["created_at"]),
            slides=slides,
            flashcards=flashcards,
            mock_questions=mock_questions,
        )


# Global singleton instance
_repository_instance: Optional[SupabaseRepository] = None


def get_repository() -> SupabaseRepository:
    """Get or create singleton repository instance."""
    global _repository_instance
    if _repository_instance is None:
        _repository_instance = SupabaseRepository()
    return _repository_instance
