"""Models for Azure Communication Services API integration."""

from typing import Dict, List, Optional

from pydantic import BaseModel, Field


class AzureEmailRecipient(BaseModel):
    """Model for Azure email recipient."""
    
    address: str = Field(..., description="Email address")
    displayName: Optional[str] = Field(None, description="Display name")


class AzureEmailRecipients(BaseModel):
    """Model for Azure email recipients collection."""
    
    to: List[AzureEmailRecipient] = Field(..., description="List of recipients")


class AzureEmailContent(BaseModel):
    """Model for Azure email content."""
    
    subject: str = Field(..., description="Email subject")
    html: str = Field(..., description="HTML email content")


class AzureEmailRequest(BaseModel):
    """Model for Azure Communication Services email request."""
    
    senderAddress: str = Field(..., description="Sender email address")
    recipients: AzureEmailRecipients = Field(..., description="Email recipients")
    content: AzureEmailContent = Field(..., description="Email content")


class AzureEmailResponse(BaseModel):
    """Model for Azure Communication Services email response."""
    
    id: Optional[str] = Field(None, description="Message ID from Azure")
    status: str = Field(..., description="Response status")
    error: Optional[Dict] = Field(None, description="Error details if any")
    
    @property
    def is_success(self) -> bool:
        """Check if the response indicates success."""
        return self.error is None and self.status.lower() in ["accepted", "queued", "sent"]