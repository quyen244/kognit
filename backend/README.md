# Kognit — Lean MVP FastAPI Backend

Cost-optimized, production-ready backend for **Kognit** based on the lean MVP specification in `.lavish/studymate-backend.html`.

## Key Features

1. **FastAPI Modern Architecture**: Async endpoints, Pydantic v2 schemas, type-safety, and CORS enabled.
2. **PyMuPDF Document Parsing**: Fast and robust text and metadata extraction from PDF course documents.
3. **Google Gemini 1.5 Flash**: Native structured JSON output generating:
   - **Slide Decks**: Digestible concept summaries with key takeaways and LaTeX formulas.
   - **15 Active Recall Flashcards**: Atomic cards with questions, answers, and hints.
   - **5 Mock Exam Questions**: Collegiate/AP-level questions with 4 options and detailed explanations.
4. **In-Process BackgroundTasks Queue**: Lightweight, zero-overhead task queue (no Redis/Celery required) with progress tracking and job polling.
5. **Supabase & PostgreSQL**: Schema with cascading foreign keys, RLS policies, and an offline-resilient client repository with in-memory fallback.

---

## Directory Structure

```text
backend/
├── app/
│   ├── api/
│   │   ├── __init__.py
│   │   └── routes.py           # HTTP endpoints (/documents, /jobs, /health)
│   ├── models/
│   │   ├── __init__.py
│   │   └── schemas.py          # Pydantic models for I/O and Gemini structured JSON
│   ├── services/
│   │   ├── __init__.py
│   │   ├── parser.py           # PyMuPDF PDF parsing service
│   │   ├── gemini.py           # Gemini 1.5 Flash structured synthesis service
│   │   ├── job_runner.py       # In-process BackgroundTasks runner & JobRegistry
│   │   └── supabase_client.py  # Supabase client & repository with fallback
│   ├── config.py               # Pydantic Settings
│   ├── main.py                 # FastAPI application factory and entrypoint
│   └── __init__.py
├── db/
│   └── schema.sql              # Supabase / PostgreSQL schema & RLS policies
├── tests/
│   ├── test_api.py             # API integration tests
│   ├── test_gemini.py          # Gemini structured output tests
│   └── test_parser.py          # PyMuPDF parser tests
├── .env.example
├── requirements.txt
└── README.md
```

---

## Quick Start

### 1. Install Dependencies

```bash
cd backend
pip install -r requirements.txt
```

### 2. Environment Configuration

Copy `.env.example` to `.env` and fill in your keys:

```bash
cp .env.example .env
```

Key environment variables:
- `GEMINI_API_KEY`: Your Google Gemini API key. If left blank, the service operates in deterministic offline mock mode.
- `GEMINI_MODEL`: Defaults to `gemini-1.5-flash`.
- `SUPABASE_URL`: Your Supabase project URL.
- `SUPABASE_KEY`: Supabase anon/service-role key. If left blank, the app uses an in-memory repository for local development and testing.

### 3. Run Database Migrations

Apply `backend/db/schema.sql` in your Supabase SQL Editor or run it against your PostgreSQL database:

```bash
psql -h <host> -U <user> -d <database> -f db/schema.sql
```

### 4. Start the Backend Server

```bash
uvicorn app.main:app --reload --port 8000
```

Interactive API documentation will be available at:
- Swagger UI: `http://localhost:8000/docs`
- ReDoc: `http://localhost:8000/redoc`

---

## API Endpoints

| Method | Path | Description |
| :--- | :--- | :--- |
| `POST` | `/api/documents/process` | Initiate processing from URL or text (Returns 202 Accepted) |
| `POST` | `/api/documents/upload` | Upload PDF file directly and process (Returns 202 Accepted) |
| `GET` | `/api/jobs/{job_id}` | Poll background processing job status and progress |
| `GET` | `/api/documents/{document_id}/status` | Check processing status of a document |
| `GET` | `/api/documents/{document_id}` | Retrieve complete document, slides, 15 flashcards, and 5 mock questions |
| `GET` | `/api/health` | Health check endpoint |

---

## Running Tests

Execute pytest:

```bash
pytest
```
