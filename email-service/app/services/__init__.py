"""Service layer components for the email service."""

from .auth_code_service import AuthCodeService, AuthCodeServiceError
from .template_manager import TemplateManager, TemplateManagerError, TemplateNotFoundError, TemplateRenderError

__all__ = [
    "AuthCodeService",
    "AuthCodeServiceError",
    "TemplateManager",
    "TemplateManagerError",
    "TemplateNotFoundError",
    "TemplateRenderError",
]