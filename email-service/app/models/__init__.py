"""Data models for the email service."""

from .auth_code import AuthCode, AuthCodeType
from .requests import EmailRequest, CodeValidationRequest
from .responses import EmailResponse, CodeValidationResponse, HealthResponse, ErrorResponse
from .azure import AzureEmailRequest, AzureEmailResponse, AzureEmailRecipient, AzureEmailRecipients, AzureEmailContent

__all__ = [
    "AuthCode",
    "AuthCodeType", 
    "EmailRequest",
    "CodeValidationRequest",
    "EmailResponse",
    "CodeValidationResponse",
    "HealthResponse",
    "ErrorResponse",
    "AzureEmailRequest",
    "AzureEmailResponse", 
    "AzureEmailRecipient",
    "AzureEmailRecipients",
    "AzureEmailContent",
]