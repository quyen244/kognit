"""Unit tests for Gemini service schemas and structured synthesis."""

import pytest
from app.services.gemini import GeminiService
from app.models.schemas import StudyMaterialGeneration


@pytest.mark.asyncio
async def test_fallback_study_materials_generation():
    """Verify that the fallback generator strictly adheres to the required structured output schema."""
    service = GeminiService()
    sample_text = """
    Photosynthesis occurs in chloroplasts. Light-dependent reactions generate ATP and NADPH.
    The Calvin cycle uses ATP and NADPH to convert CO2 into glucose.
    """

    materials = await service.generate_study_materials(
        document_text=sample_text,
        subject="AP Biology",
        title="Photosynthesis"
    )

    assert isinstance(materials, StudyMaterialGeneration)
    assert len(materials.slides) >= 4
    assert len(materials.flashcards) == 15
    assert len(materials.mock_questions) == 5

    # Check slide structure
    for slide in materials.slides:
        assert slide.slide_number >= 1
        assert len(slide.title) > 0
        assert len(slide.content) > 0

    # Check flashcard structure
    for card in materials.flashcards:
        assert len(card.question) > 0
        assert len(card.answer) > 0
        assert card.interval_days >= 1

    # Check mock questions structure
    for q in materials.mock_questions:
        assert len(q.question_text) > 0
        assert len(q.options) >= 2
        assert len(q.explanation) > 0
        # Exactly one option should be correct
        correct_count = sum(1 for opt in q.options if opt.is_correct)
        assert correct_count == 1
