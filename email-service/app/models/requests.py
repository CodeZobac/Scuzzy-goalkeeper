"""Request models for the email service API."""

from pydantic import BaseModel, Field, EmailStr, validator

from .auth_code import AuthCodeType


class EmailRequest(BaseModel):
    """Request model for sending emails."""
    
    email: EmailStr = Field(..., description="Recipient email address")
    user_id: str = Field(..., description="User ID for the recipient")
    
    @validator('user_id')
    def validate_user_id(cls, v):
        """Validate user_id is not empty."""
        if not v or not v.strip():
            raise ValueError("user_id cannot be empty")
        return v.strip()


class CodeValidationRequest(BaseModel):
    """Request model for validating authentication codes."""
    
    code: str = Field(..., description="Authentication code to validate")
    code_type: AuthCodeType = Field(..., description="Type of code to validate")
    
    @validator('code')
    def validate_code(cls, v):
        """Validate code is not empty and has reasonable length."""
        if not v or not v.strip():
            raise ValueError("code cannot be empty")
        
        code = v.strip()
        if len(code) < 8:
            raise ValueError("code must be at least 8 characters long")
        if len(code) > 64:
            raise ValueError("code must be at most 64 characters long")
        
        return code
    
    class Config:
        """Pydantic configuration."""
        use_enum_values = True