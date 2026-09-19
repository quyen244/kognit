"""Kognit Lean MVP FastAPI Backend Entrypoint."""

import logging
from contextlib import asynccontextmanager
from fastapi import FastAPI, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.config import get_settings
from app.api.routes import router as api_router
from app.services.parser import DocumentParsingError

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)
logger = logging.getLogger("kognit")


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifecycle events."""
    settings = get_settings()
    logger.info("================================================")
    logger.info("Starting Kognit Lean MVP Backend")
    logger.info(f"Environment: {settings.environment}")
    logger.info(f"Debug: {settings.debug}")
    logger.info(f"Gemini Model: {settings.gemini_model}")
    logger.info(f"Supabase URL: {settings.supabase_url or 'Not set (using in-memory fallback)'}")
    logger.info("================================================")
    yield
    logger.info("Shutting down Kognit Backend.")


def create_app() -> FastAPI:
    """Factory creating and configuring the FastAPI application."""
    settings = get_settings()

    app = FastAPI(
        title="Kognit Backend API",
        description="Lean MVP backend for transforming course documents into slides, flashcards, and mock exams.",
        version="0.1.0",
        docs_url="/docs",
        redoc_url="/redoc",
        lifespan=lifespan,
    )

    # CORS configuration
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    # Exception handler for document parsing errors
    @app.exception_handler(DocumentParsingError)
    async def document_parsing_exception_handler(request: Request, exc: DocumentParsingError):
        return JSONResponse(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            content={"detail": str(exc), "error_type": exc.__class__.__name__},
        )

    # Mount API routers
    app.include_router(api_router, prefix=settings.api_prefix)

    @app.get("/", tags=["Root"])
    async def root():
        return {
            "name": "Kognit Backend API",
            "version": "0.1.0",
            "status": "online",
            "docs": "/docs",
        }

    return app


app = create_app()

if __name__ == "__main__":
    import uvicorn
    settings = get_settings()
    uvicorn.run("app.main:app", host=settings.host, port=settings.port, reload=settings.debug)
