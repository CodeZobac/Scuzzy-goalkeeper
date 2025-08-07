"""Response models for the email service API."""

from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field


class EmailResponse(BaseModel):
    """Response model for email sending operations."""
    
    success: bool = Field(..., description="Whether email was sent successfully")
    message: str = Field(..., description="Response message")
    message_id: Optional[str] = Field(None, description="Azure message ID if successful")
    
    class Config:
        """Pydantic configuration."""
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }


class CodeValidationResponse(BaseModel):
    """Response model for authentication code validation."""
    
    valid: bool = Field(..., description="Whether code is valid")
    user_id: Optional[str] = Field(None, description="User ID if code is valid")
    message: str = Field(..., description="Validation result message")
    
    class Config:
        """Pydantic configuration."""
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }


class HealthResponse(BaseModel):
    """Response model for health check endpoint."""
    
    status: str = Field(..., description="Service health status")
    timestamp: datetime = Field(default_factory=datetime.utcnow, description="Health check timestamp")
    version: str = Field(default="0.1.0", description="Service version")
    environment: str = Field(..., description="Current environment")
    
    class Config:
        """Pydantic configuration."""
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }


class ErrorResponse(BaseModel):
    """Response model for error cases."""
    
    error: bool = Field(default=True, description="Indicates this is an error response")
    error_type: str = Field(..., description="Category of error")
    message: str = Field(..., description="Human-readable error message")
    details: Optional[dict] = Field(None, description="Additional error details")
    timestamp: datetime = Field(default_factory=datetime.utcnow, description="Error timestamp")
    
    class Config:
        """Pydantic configuration."""
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }