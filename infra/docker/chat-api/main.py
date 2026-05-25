"""Chat API - FastAPI Service."""

import os
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan handler."""
    # Startup
    yield
    # Shutdown


app = FastAPI(
    title="Chat API",
    version="0.1.0",
    lifespan=lifespan,
)


class HealthResponse(BaseModel):
    status: str
    service: str


class ChatMessage(BaseModel):
    content: str
    user_id: str | None = None


class ChatResponse(BaseModel):
    message_id: str
    content: str
    status: str


@app.get("/health", response_model=HealthResponse)
async def health():
    return HealthResponse(status="ok", service="chat-api")


@app.post("/api/chat", response_model=ChatResponse)
async def chat(message: ChatMessage):
    # TODO: Implement chat logic with NATS, PostgreSQL, and worker
    return ChatResponse(
        message_id="placeholder",
        content="Service is running. Implement your chat logic here.",
        status="received",
    )
