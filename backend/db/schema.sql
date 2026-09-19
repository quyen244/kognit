-- ==============================================================================
-- Kognit / StudyMate - Lean MVP PostgreSQL & Supabase Database Schema
-- Reference: studymate-backend.html & studymate-sync-explainer.html
-- ==============================================================================

-- Enable UUID extension if not enabled
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ------------------------------------------------------------------------------
-- 1. DOCUMENTS TABLE (Uploaded & Processed Materials)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL, -- References auth.users(id) in production Supabase
    title TEXT NOT NULL,
    file_url TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'processing', -- 'queued', 'processing', 'ready', 'failed'
    error_message TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_documents_user_id ON documents(user_id);
CREATE INDEX IF NOT EXISTS idx_documents_status ON documents(status);

-- ------------------------------------------------------------------------------
-- 2. SLIDES TABLE (Digestible Summaries)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS slides (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id UUID NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
    slide_number INT NOT NULL,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    key_takeaway TEXT,
    formula_latex TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_slides_document_id ON slides(document_id);
CREATE INDEX IF NOT EXISTS idx_slides_document_number ON slides(document_id, slide_number);

-- ------------------------------------------------------------------------------
-- 3. FLASHCARDS TABLE (Active Recall & Spaced Repetition)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS flashcards (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id UUID NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
    question TEXT NOT NULL,
    answer TEXT NOT NULL,
    hint TEXT,
    interval_days INT NOT NULL DEFAULT 1,
    next_review_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_flashcards_document_id ON flashcards(document_id);
CREATE INDEX IF NOT EXISTS idx_flashcards_next_review ON flashcards(next_review_at);

-- ------------------------------------------------------------------------------
-- 4. MOCK QUESTIONS TABLE (Adaptive Practice Quizzes)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS mock_questions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id UUID NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
    question_text TEXT NOT NULL,
    options JSONB NOT NULL, -- [{"text": "...", "is_correct": bool}]
    explanation TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_mock_questions_document_id ON mock_questions(document_id);

-- ------------------------------------------------------------------------------
-- 5. OFFLINE SYNC MUTATIONS TABLE (Monotonic Deduplication Log)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS sync_mutations (
    id UUID PRIMARY KEY, -- Client generated UUID for idempotency
    user_id UUID NOT NULL,
    action TEXT NOT NULL, -- e.g., 'REVIEW_FLASHCARD'
    card_id UUID,
    rating TEXT, -- 'Again', 'Hard', 'Good', 'Easy'
    client_timestamp TIMESTAMPTZ NOT NULL,
    server_rev BIGSERIAL NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sync_mutations_user_rev ON sync_mutations(user_id, server_rev);

-- ------------------------------------------------------------------------------
-- 6. FSRS CARDS TABLE (Deterministic Spaced Repetition State)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS fsrs_cards (
    card_id UUID PRIMARY KEY REFERENCES flashcards(id) ON DELETE CASCADE,
    stability FLOAT NOT NULL DEFAULT 1.0,
    difficulty FLOAT NOT NULL DEFAULT 4.8,
    reps INT NOT NULL DEFAULT 0,
    lapses INT NOT NULL DEFAULT 0,
    state INT NOT NULL DEFAULT 0, -- 0=New, 1=Learning, 2=Review, 3=Relearning
    last_review TIMESTAMPTZ,
    due TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_fsrs_cards_due ON fsrs_cards(due);

-- ------------------------------------------------------------------------------
-- SUPABASE ROW LEVEL SECURITY (RLS) POLICIES
-- ------------------------------------------------------------------------------
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE slides ENABLE ROW LEVEL SECURITY;
ALTER TABLE flashcards ENABLE ROW LEVEL SECURITY;
ALTER TABLE mock_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE sync_mutations ENABLE ROW LEVEL SECURITY;
ALTER TABLE fsrs_cards ENABLE ROW LEVEL SECURITY;

-- Allow users to manage their own documents
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'documents' AND policyname = 'Users can manage their own documents'
    ) THEN
        CREATE POLICY "Users can manage their own documents"
            ON documents FOR ALL
            USING (auth.uid() = user_id)
            WITH CHECK (auth.uid() = user_id);
    END IF;
END $$;
