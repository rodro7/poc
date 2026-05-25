"""Worker - LangGraph FastAPI Service."""

import os
from contextlib import asynccontextmanager

from fastapi import FastAPI
from pydantic import BaseModel


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan handler."""
    # Startup: initialize LangGraph, Neo4j/Graphiti connections
    yield
    # Shutdown: close connections


app = FastAPI(
    title="Worker Service",
    version="0.1.0",
    lifespan=lifespan,
)


class HealthResponse(BaseModel):
    status: str
    service: str


class TaskRequest(BaseModel):
    task_id: str
    payload: dict


class TaskResponse(BaseModel):
    task_id: str
    status: str
    result: dict | None = None


@app.get("/health", response_model=HealthResponse)
async def health():
    return HealthResponse(status="ok", service="worker")


@app.post("/api/worker/process", response_model=TaskResponse)
async def process_task(task: TaskRequest):
    # TODO: Implement LangGraph workflow processing
    return TaskResponse(
        task_id=task.task_id,
        status="received",
        result=None,
    )
