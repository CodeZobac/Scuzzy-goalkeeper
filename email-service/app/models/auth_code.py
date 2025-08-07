"""Data models for authentication codes."""

from datetime import datetime
from enum import Enum
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, Field, validator


class AuthCodeType(str, Enum):
    """Enum representing the type of authentication code."""
    
    EMAIL_CONFIRMATION = "email_confirmation"
    PASSWORD_RESET = "password_reset"


class AuthCode(BaseModel):
    """Data model for authentication codes used in email confirmation and password reset."""
    
    id: str = Field(..., description="Unique identifier for the authentication code")
    code: str = Field(..., description="Hashed authentication code")
    user_id: str = Field(..., description="ID of the user this code belongs to")
    type: AuthCodeType = Field(..., description="Type of authentication code")
    created_at: datetime = Field(..., description="When the code was created")
    expires_at: datetime = Field(..., description="When the code expires")
    is_used: bool = Field(default=False, description="Whether the code has been used")
    used_at: Optional[datetime] = Field(None, description="When the code was used")
    
    class Config:
        """Pydantic configuration."""
        use_enum_values = True
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }
    
    @validator('user_id')
    def validate_user_id(cls, v):
        """Validate user_id is not empty."""
        if not v or not v.strip():
            raise ValueError("user_id cannot be empty")
        return v
    
    @validator('code')
    def validate_code(cls, v):
        """Validate code is not empty."""
        if not v or not v.strip():
            raise ValueError("code cannot be empty")
        return v
    
    @validator('expires_at')
    def validate_expires_at(cls, v, values):
        """Validate expires_at is after created_at."""
        if 'created_at' in values and v <= values['created_at']:
            raise ValueError("expires_at must be after created_at")
        return v
    
    @property
    def is_expired(self) -> bool:
        """Check if the authentication code has expired."""
        from datetime import timezone
        return datetime.now(timezone.utc) > self.expires_at.replace(tzinfo=timezone.utc)
    
    @property
    def is_valid(self) -> bool:
        """Check if the authentication code is valid (not used and not expired)."""
        return not self.is_used and not self.is_expired
    
    def to_dict(self) -> dict:
        """Convert to dictionary for database operations."""
        return {
            'id': self.id,
            'code': self.code,
            'user_id': self.user_id,
            'type': self.type if isinstance(self.type, str) else self.type.value,
            'created_at': self.created_at.isoformat(),
            'expires_at': self.expires_at.isoformat(),
            'is_used': self.is_used,
            'used_at': self.used_at.isoformat() if self.used_at else None,
        }
    
    @classmethod
    def from_dict(cls, data: dict) -> 'AuthCode':
        """Create AuthCode from database row dictionary."""
        return cls(
            id=data['id'],
            code=data['code'],
            user_id=data['user_id'],
            type=AuthCodeType(data['type']),
            created_at=datetime.fromisoformat(data['created_at'].replace('Z', '+00:00')),
            expires_at=datetime.fromisoformat(data['expires_at'].replace('Z', '+00:00')),
            is_used=data['is_used'],
            used_at=datetime.fromisoformat(data['used_at'].replace('Z', '+00:00')) if data['used_at'] else None,
        )