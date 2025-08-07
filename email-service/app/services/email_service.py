"""Core email service for orchestrating the complete email sending process."""

import logging
from typing import Optional

from app.clients.azure_client import AzureClient, AzureClientError
from app.config import settings
from app.models.auth_code import AuthCodeType
from app.models.requests import EmailRequest
from app.models.responses import EmailResponse
from app.services.auth_code_service import AuthCodeService, AuthCodeServiceError
from app.services.template_manager import TemplateManager, TemplateManagerError


logger = logging.getLogger(__name__)


class EmailServiceError(Exception):
    """Base exception for EmailService operations."""
    pass


class EmailService:
    """Core service for orchestrating the complete email sending process."""
    
    def __init__(
        self,
        auth_code_service: Optional[AuthCodeService] = None,
        template_manager: Optional[TemplateManager] = None,
        azure_client: Optional[AzureClient] = None
    ):
        """
        Initialize the email service with required dependencies.
        
        Args:
            auth_code_service: Service for managing authentication codes
            template_manager: Service for managing email templates
            azure_client: Client for Azure Communication Services
        """
        self._auth_code_service = auth_code_service or AuthCodeService()
        self._template_manager = template_manager or TemplateManager()
        self._azure_client = azure_client or AzureClient()
        
        logger.info("EmailService initialized with all dependencies")
    
    async def send_confirmation_email(self, email: str, user_id: str) -> EmailResponse:
        """
        Send an email confirmation email to the user.
        
        Args:
            email: Recipient email address
            user_id: User ID for the recipient
            
        Returns:
            EmailResponse: Response indicating success or failure
            
        Raises:
            EmailServiceError: If email sending process fails
        """
        logger.info(
            "Starting confirmation email send process",
            extra={
                "email": email,
                "user_id": user_id,
                "email_type": "confirmation"
            }
        )
        
        try:
            # Generate authentication code
            auth_code = self._auth_code_service.generate_code(
                user_id=user_id,
                code_type=AuthCodeType.EMAIL_CONFIRMATION
            )
            
            logger.debug(
                "Generated authentication code for confirmation email",
                extra={
                    "user_id": user_id,
                    "code_preview": auth_code[:8] + "..."
                }
            )
            
            # Compose email content using template
            html_content = self._compose_email(
                template_type=AuthCodeType.EMAIL_CONFIRMATION,
                auth_code=auth_code
            )
            
            # Send email via Azure
            azure_response = await self._send_via_azure(
                to_email=email,
                subject="Confirm Your Email Address",
                html_content=html_content
            )
            
            if azure_response.success:
                logger.info(
                    "Confirmation email sent successfully",
                    extra={
                        "email": email,
                        "user_id": user_id,
                        "message_id": azure_response.message_id
                    }
                )
                
                return EmailResponse(
                    success=True,
                    message="Confirmation email sent successfully",
                    message_id=azure_response.message_id
                )
            else:
                logger.error(
                    "Failed to send confirmation email via Azure",
                    extra={
                        "email": email,
                        "user_id": user_id,
                        "error": azure_response.error_message
                    }
                )
                
                # Clean up the generated auth code since email failed
                try:
                    self._auth_code_service.invalidate_code(auth_code, AuthCodeType.EMAIL_CONFIRMATION)
                except Exception as cleanup_error:
                    logger.warning(
                        "Failed to clean up auth code after email failure",
                        extra={"error": str(cleanup_error)}
                    )
                
                return EmailResponse(
                    success=False,
                    message=f"Failed to send confirmation email: {azure_response.error_message}"
                )
                
        except AuthCodeServiceError as e:
            logger.error(
                "Authentication code generation failed for confirmation email",
                extra={
                    "email": email,
                    "user_id": user_id,
                    "error": str(e)
                }
            )
            raise EmailServiceError(f"Failed to generate authentication code: {e}")
            
        except TemplateManagerError as e:
            logger.error(
                "Template processing failed for confirmation email",
                extra={
                    "email": email,
                    "user_id": user_id,
                    "error": str(e)
                }
            )
            raise EmailServiceError(f"Failed to process email template: {e}")
            
        except AzureClientError as e:
            logger.error(
                "Azure client error sending confirmation email",
                extra={
                    "email": email,
                    "user_id": user_id,
                    "error": str(e),
                    "status_code": e.status_code
                }
            )
            raise EmailServiceError(f"Failed to send email via Azure: {e}")
            
        except Exception as e:
            logger.error(
                "Unexpected error sending confirmation email",
                extra={
                    "email": email,
                    "user_id": user_id,
                    "error": str(e)
                }
            )
            raise EmailServiceError(f"Unexpected error: {e}")
    
    async def send_password_reset_email(self, email: str, user_id: str) -> EmailResponse:
        """
        Send a password reset email to the user.
        
        Args:
            email: Recipient email address
            user_id: User ID for the recipient
            
        Returns:
            EmailResponse: Response indicating success or failure
            
        Raises:
            EmailServiceError: If email sending process fails
        """
        logger.info(
            "Starting password reset email send process",
            extra={
                "email": email,
                "user_id": user_id,
                "email_type": "password_reset"
            }
        )
        
        try:
            # Generate authentication code
            auth_code = self._auth_code_service.generate_code(
                user_id=user_id,
                code_type=AuthCodeType.PASSWORD_RESET
            )
            
            logger.debug(
                "Generated authentication code for password reset email",
                extra={
                    "user_id": user_id,
                    "code_preview": auth_code[:8] + "..."
                }
            )
            
            # Compose email content using template
            html_content = self._compose_email(
                template_type=AuthCodeType.PASSWORD_RESET,
                auth_code=auth_code
            )
            
            # Send email via Azure
            azure_response = await self._send_via_azure(
                to_email=email,
                subject="Reset Your Password",
                html_content=html_content
            )
            
            if azure_response.success:
                logger.info(
                    "Password reset email sent successfully",
                    extra={
                        "email": email,
                        "user_id": user_id,
                        "message_id": azure_response.message_id
                    }
                )
                
                return EmailResponse(
                    success=True,
                    message="Password reset email sent successfully",
                    message_id=azure_response.message_id
                )
            else:
                logger.error(
                    "Failed to send password reset email via Azure",
                    extra={
                        "email": email,
                        "user_id": user_id,
                        "error": azure_response.error_message
                    }
                )
                
                # Clean up the generated auth code since email failed
                try:
                    self._auth_code_service.invalidate_code(auth_code, AuthCodeType.PASSWORD_RESET)
                except Exception as cleanup_error:
                    logger.warning(
                        "Failed to clean up auth code after email failure",
                        extra={"error": str(cleanup_error)}
                    )
                
                return EmailResponse(
                    success=False,
                    message=f"Failed to send password reset email: {azure_response.error_message}"
                )
                
        except AuthCodeServiceError as e:
            logger.error(
                "Authentication code generation failed for password reset email",
                extra={
                    "email": email,
                    "user_id": user_id,
                    "error": str(e)
                }
            )
            raise EmailServiceError(f"Failed to generate authentication code: {e}")
            
        except TemplateManagerError as e:
            logger.error(
                "Template processing failed for password reset email",
                extra={
                    "email": email,
                    "user_id": user_id,
                    "error": str(e)
                }
            )
            raise EmailServiceError(f"Failed to process email template: {e}")
            
        except AzureClientError as e:
            logger.error(
                "Azure client error sending password reset email",
                extra={
                    "email": email,
                    "user_id": user_id,
                    "error": str(e),
                    "status_code": e.status_code
                }
            )
            raise EmailServiceError(f"Failed to send email via Azure: {e}")
            
        except Exception as e:
            logger.error(
                "Unexpected error sending password reset email",
                extra={
                    "email": email,
                    "user_id": user_id,
                    "error": str(e)
                }
            )
            raise EmailServiceError(f"Unexpected error: {e}")
    
    def _compose_email(self, template_type: AuthCodeType, auth_code: str) -> str:
        """
        Compose email content by combining templates with authentication codes.
        
        Args:
            template_type: Type of email template to use
            auth_code: Authentication code to include in the email
            
        Returns:
            Rendered HTML email content
            
        Raises:
            TemplateManagerError: If template processing fails
        """
        logger.debug(
            "Composing email content",
            extra={
                "template_type": template_type.value,
                "code_preview": auth_code[:8] + "..."
            }
        )
        
        try:
            # Use template manager to render the appropriate template
            html_content = self._template_manager.render_email_by_type(
                code_type=template_type,
                auth_code=auth_code
            )
            
            logger.debug(
                "Email content composed successfully",
                extra={
                    "template_type": template_type.value,
                    "content_length": len(html_content)
                }
            )
            
            return html_content
            
        except Exception as e:
            logger.error(
                "Failed to compose email content",
                extra={
                    "template_type": template_type.value,
                    "error": str(e)
                }
            )
            raise TemplateManagerError(f"Email composition failed: {e}")
    
    async def _send_via_azure(self, to_email: str, subject: str, html_content: str) -> 'AzureResponse':
        """
        Send email via Azure Communication Services.
        
        Args:
            to_email: Recipient email address
            subject: Email subject
            html_content: HTML content of the email
            
        Returns:
            AzureResponse: Response from Azure API
            
        Raises:
            AzureClientError: If Azure API call fails
        """
        logger.debug(
            "Sending email via Azure Communication Services",
            extra={
                "to_email": to_email,
                "subject": subject,
                "content_length": len(html_content)
            }
        )
        
        try:
            response = await self._azure_client.send_email(
                to_email=to_email,
                subject=subject,
                html_content=html_content
            )
            
            logger.debug(
                "Azure email send completed",
                extra={
                    "to_email": to_email,
                    "success": response.success,
                    "message_id": response.message_id
                }
            )
            
            return response
            
        except Exception as e:
            logger.error(
                "Azure email send failed",
                extra={
                    "to_email": to_email,
                    "subject": subject,
                    "error": str(e)
                }
            )
            raise
    
    async def health_check(self) -> dict:
        """
        Perform a health check of all email service dependencies.
        
        Returns:
            Dictionary with health status of all components
        """
        logger.debug("Performing email service health check")
        
        health_status = {
            "email_service": "healthy",
            "auth_code_service": "unknown",
            "template_manager": "unknown",
            "azure_client": "unknown",
            "overall": "unknown"
        }
        
        try:
            # Check auth code service
            try:
                stats = self._auth_code_service.get_service_stats()
                health_status["auth_code_service"] = "healthy" if stats.get("service_status") == "operational" else "unhealthy"
            except Exception as e:
                logger.warning(f"Auth code service health check failed: {e}")
                health_status["auth_code_service"] = "unhealthy"
            
            # Check template manager
            try:
                templates = self._template_manager.get_available_templates()
                health_status["template_manager"] = "healthy" if templates else "unhealthy"
            except Exception as e:
                logger.warning(f"Template manager health check failed: {e}")
                health_status["template_manager"] = "unhealthy"
            
            # Check Azure client
            try:
                azure_healthy = await self._azure_client.health_check()
                health_status["azure_client"] = "healthy" if azure_healthy else "unhealthy"
            except Exception as e:
                logger.warning(f"Azure client health check failed: {e}")
                health_status["azure_client"] = "unhealthy"
            
            # Determine overall health
            component_statuses = [
                health_status["auth_code_service"],
                health_status["template_manager"],
                health_status["azure_client"]
            ]
            
            if all(status == "healthy" for status in component_statuses):
                health_status["overall"] = "healthy"
            elif any(status == "healthy" for status in component_statuses):
                health_status["overall"] = "degraded"
            else:
                health_status["overall"] = "unhealthy"
            
            logger.info(
                "Email service health check completed",
                extra={"health_status": health_status}
            )
            
            return health_status
            
        except Exception as e:
            logger.error(f"Email service health check failed: {e}")
            health_status["overall"] = "unhealthy"
            return health_status
    
    def get_service_info(self) -> dict:
        """
        Get information about the email service configuration.
        
        Returns:
            Dictionary with service information
        """
        return {
            "service_name": "EmailService",
            "version": "0.1.0",
            "from_address": settings.email_from_address,
            "from_name": settings.email_from_name,
            "azure_endpoint": settings.email_service,
            "supported_email_types": [
                AuthCodeType.EMAIL_CONFIRMATION.value,
                AuthCodeType.PASSWORD_RESET.value
            ]
        }