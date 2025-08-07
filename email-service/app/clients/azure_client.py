"""Azure Communication Services client for sending emails."""

import asyncio
import base64
import hashlib
import hmac
import logging
from datetime import datetime
from typing import Dict, Any, Optional
from urllib.parse import urljoin, quote

import httpx
from pydantic import BaseModel

from ..config import settings


logger = logging.getLogger(__name__)


class AzureEmailRequest(BaseModel):
    """Request model for Azure Communication Services email API."""
    
    senderAddress: str
    recipients: Dict[str, Any]
    content: Dict[str, Any]


class AzureResponse(BaseModel):
    """Response model for Azure Communication Services API."""
    
    success: bool
    message_id: Optional[str] = None
    error_message: Optional[str] = None
    status_code: Optional[int] = None
    details: Optional[Dict[str, Any]] = None


class AzureClientError(Exception):
    """Custom exception for Azure client errors."""
    
    def __init__(self, message: str, status_code: Optional[int] = None, details: Optional[Dict[str, Any]] = None):
        self.message = message
        self.status_code = status_code
        self.details = details or {}
        super().__init__(self.message)


class AzureClient:
    """Client for Azure Communication Services email operations."""
    
    def __init__(self):
        """Initialize the Azure client with configuration."""
        self.base_url = settings.email_service.rstrip('/')
        self.api_key = settings.azure_key
        self.from_address = settings.email_from_address
        self.from_name = settings.email_from_name
        
        # Check if mock mode is enabled
        self.mock_mode = getattr(settings, 'azure_mock_mode', False)
        
        # Configure HTTP client with timeouts and retry settings
        self.timeout = httpx.Timeout(30.0, connect=10.0)
        self.max_retries = 3
        self.retry_delay = 1.0  # Base delay in seconds
        
        logger.info(
            "Azure client initialized",
            extra={
                "base_url": self.base_url,
                "from_address": self.from_address,
                "from_name": self.from_name,
                "mock_mode": self.mock_mode
            }
        )
    
    async def send_email(
        self,
        to_email: str,
        subject: str,
        html_content: str,
        plain_text_content: Optional[str] = None
    ) -> AzureResponse:
        """
        Send an email via Azure Communication Services.
        
        Args:
            to_email: Recipient email address
            subject: Email subject
            html_content: HTML content of the email
            plain_text_content: Plain text content (optional)
            
        Returns:
            AzureResponse: Response from Azure API
            
        Raises:
            AzureClientError: If email sending fails after retries
        """
        logger.info(
            "Sending email via Azure Communication Services",
            extra={
                "to_email": to_email,
                "subject": subject,
                "has_html": bool(html_content),
                "has_plain_text": bool(plain_text_content)
            }
        )
        
        # Build the Azure API request
        azure_request = self._build_azure_request(
            to_email=to_email,
            subject=subject,
            html_content=html_content,
            plain_text_content=plain_text_content
        )
        
        # Attempt to send with retry logic
        last_exception = None
        for attempt in range(self.max_retries):
            try:
                logger.debug(
                    f"Email send attempt {attempt + 1}/{self.max_retries}",
                    extra={"to_email": to_email, "attempt": attempt + 1}
                )
                
                response = await self._make_azure_request(azure_request)
                
                logger.info(
                    "Email sent successfully via Azure",
                    extra={
                        "to_email": to_email,
                        "message_id": response.message_id,
                        "attempt": attempt + 1
                    }
                )
                
                return response
                
            except AzureClientError as e:
                last_exception = e
                logger.warning(
                    f"Email send attempt {attempt + 1} failed",
                    extra={
                        "to_email": to_email,
                        "attempt": attempt + 1,
                        "error": str(e),
                        "status_code": e.status_code
                    }
                )
                
                # Don't retry on client errors (4xx status codes)
                if e.status_code and 400 <= e.status_code < 500:
                    logger.error(
                        "Client error encountered, not retrying",
                        extra={
                            "to_email": to_email,
                            "status_code": e.status_code,
                            "error": str(e)
                        }
                    )
                    raise e
                
                # Wait before retrying (exponential backoff)
                if attempt < self.max_retries - 1:
                    delay = self.retry_delay * (2 ** attempt)
                    logger.debug(f"Waiting {delay}s before retry", extra={"delay": delay})
                    await asyncio.sleep(delay)
        
        # All retries failed
        logger.error(
            "All email send attempts failed",
            extra={
                "to_email": to_email,
                "max_retries": self.max_retries,
                "final_error": str(last_exception)
            }
        )
        
        raise last_exception or AzureClientError("Email sending failed after all retries")
    
    def _build_azure_request(
        self,
        to_email: str,
        subject: str,
        html_content: str,
        plain_text_content: Optional[str] = None
    ) -> AzureEmailRequest:
        """
        Build the Azure Communication Services API request.
        
        Args:
            to_email: Recipient email address
            subject: Email subject
            html_content: HTML content of the email
            plain_text_content: Plain text content (optional)
            
        Returns:
            AzureEmailRequest: Formatted request for Azure API
        """
        # Build content object
        content = {
            "subject": subject,
            "html": html_content
        }
        
        # Add plain text if provided
        if plain_text_content:
            content["plainText"] = plain_text_content
        
        # Build recipients object
        recipients = {
            "to": [
                {
                    "address": to_email
                }
            ]
        }
        
        return AzureEmailRequest(
            senderAddress=self.from_address,
            recipients=recipients,
            content=content
        )
    
    async def _make_azure_request(self, azure_request: AzureEmailRequest) -> AzureResponse:
        """
        Make the actual HTTP request to Azure Communication Services.
        
        Args:
            azure_request: The formatted Azure API request
            
        Returns:
            AzureResponse: Parsed response from Azure
            
        Raises:
            AzureClientError: If the request fails
        """
        # Return mock response if mock mode is enabled
        if self.mock_mode:
            logger.info("Azure mock mode enabled - simulating successful email send")
            mock_message_id = f"mock_msg_{datetime.now().timestamp()}"
            return AzureResponse(
                success=True,
                message_id=mock_message_id,
                status_code=202,
                details={"message": "Mock email sent successfully"}
            )
        
        url = urljoin(self.base_url, "/emails:send?api-version=2023-03-31")
        request_data = azure_request.model_dump()
        
        import json
        request_body = json.dumps(request_data).encode('utf-8')
        
        # Generate HMAC authentication headers
        headers = self._generate_auth_headers(
            method="POST",
            url=url,
            body=request_body
        )
        
        logger.debug(
            "Making Azure API request",
            extra={
                "url": url,
                "headers": {k: v if k != "Ocp-Apim-Subscription-Key" else "***" for k, v in headers.items()},
                "request_data": {
                    **request_data,
                    "recipients": {"to": [{"address": "***"}]}  # Mask email for logging
                }
            }
        )
        
        try:
            async with httpx.AsyncClient(timeout=self.timeout) as client:
                response = await client.post(
                    url=url,
                    headers=headers,
                    content=request_body
                )
                
                return self._handle_azure_response(response)
                
        except httpx.TimeoutException as e:
            logger.error(
                "Azure API request timed out",
                extra={"url": url, "timeout": self.timeout.total, "error": str(e)}
            )
            raise AzureClientError(
                message="Request to Azure Communication Services timed out",
                details={"timeout": self.timeout.total, "error": str(e)}
            )
            
        except httpx.ConnectError as e:
            logger.error(
                "Failed to connect to Azure API",
                extra={"url": url, "error": str(e)}
            )
            raise AzureClientError(
                message="Failed to connect to Azure Communication Services",
                details={"url": url, "error": str(e)}
            )
            
        except httpx.RequestError as e:
            logger.error(
                "Azure API request failed",
                extra={"url": url, "error": str(e)}
            )
            raise AzureClientError(
                message="Request to Azure Communication Services failed",
                details={"url": url, "error": str(e)}
            )
    
    def _handle_azure_response(self, response: httpx.Response) -> AzureResponse:
        """
        Handle and parse the response from Azure Communication Services.
        
        Args:
            response: HTTP response from Azure API
            
        Returns:
            AzureResponse: Parsed response object
            
        Raises:
            AzureClientError: If the response indicates an error
        """
        status_code = response.status_code
        
        logger.debug(
            "Received Azure API response",
            extra={
                "status_code": status_code,
                "headers": dict(response.headers),
                "response_size": len(response.content)
            }
        )
        
        try:
            response_data = response.json() if response.content else {}
        except Exception as e:
            logger.warning(
                "Failed to parse Azure API response as JSON",
                extra={"status_code": status_code, "content": response.text[:500], "error": str(e)}
            )
            response_data = {}
        
        # Handle successful responses (2xx status codes)
        if 200 <= status_code < 300:
            message_id = response_data.get("id") or response.headers.get("x-ms-request-id")
            
            logger.debug(
                "Azure API request successful",
                extra={
                    "status_code": status_code,
                    "message_id": message_id,
                    "response_data": response_data
                }
            )
            
            return AzureResponse(
                success=True,
                message_id=message_id,
                status_code=status_code,
                details=response_data
            )
        
        # Handle error responses
        error_message = self._extract_error_message(response_data, status_code)
        
        logger.error(
            "Azure API request failed",
            extra={
                "status_code": status_code,
                "error_message": error_message,
                "response_data": response_data
            }
        )
        
        raise AzureClientError(
            message=error_message,
            status_code=status_code,
            details=response_data
        )
    
    def _extract_error_message(self, response_data: Dict[str, Any], status_code: int) -> str:
        """
        Extract a meaningful error message from Azure API response.
        
        Args:
            response_data: Parsed JSON response from Azure
            status_code: HTTP status code
            
        Returns:
            str: Human-readable error message
        """
        # Try to extract error message from various possible fields
        error_message = None
        
        if isinstance(response_data, dict):
            # Common Azure error response formats
            error_message = (
                response_data.get("error", {}).get("message") or
                response_data.get("message") or
                response_data.get("error_description") or
                response_data.get("details")
            )
        
        # Fallback to generic message based on status code
        if not error_message:
            if status_code == 400:
                error_message = "Bad request - invalid email parameters"
            elif status_code == 401:
                error_message = "Unauthorized - invalid Azure API key"
            elif status_code == 403:
                error_message = "Forbidden - insufficient permissions"
            elif status_code == 404:
                error_message = "Not found - invalid Azure endpoint"
            elif status_code == 429:
                error_message = "Rate limit exceeded - too many requests"
            elif 500 <= status_code < 600:
                error_message = "Azure Communication Services internal error"
            else:
                error_message = f"Azure API request failed with status {status_code}"
        
        return error_message
    
    def _generate_auth_headers(self, method: str, url: str, body: bytes) -> Dict[str, str]:
        """
        Generate HMAC-SHA256 authentication headers for Azure Communication Services.
        
        Args:
            method: HTTP method (e.g., 'POST')
            url: Full URL including query parameters
            body: Request body as bytes
            
        Returns:
            Dictionary of headers including authentication
        """
        from urllib.parse import urlparse
        import time
        
        # Parse URL components
        parsed_url = urlparse(url)
        host = parsed_url.netloc
        path_and_query = parsed_url.path + ('?' + parsed_url.query if parsed_url.query else '')
        
        # Generate timestamp
        utc_now = datetime.utcnow()
        utc_string = utc_now.strftime('%a, %d %b %Y %H:%M:%S GMT')
        
        # Calculate content hash
        content_hash = hashlib.sha256(body).digest()
        content_hash_b64 = base64.b64encode(content_hash).decode()
        
        # Build string to sign
        string_to_sign = f"{method}\n{path_and_query}\n{utc_string};{host};{content_hash_b64}"
        
        # Generate signature
        key = base64.b64decode(self.api_key)
        signature = hmac.new(key, string_to_sign.encode(), hashlib.sha256).digest()
        signature_b64 = base64.b64encode(signature).decode()
        
        # Build authorization header
        auth_header = f"HMAC-SHA256 SignedHeaders=x-ms-date;host;x-ms-content-sha256&Signature={signature_b64}"
        
        return {
            "Authorization": auth_header,
            "x-ms-date": utc_string,
            "x-ms-content-sha256": content_hash_b64,
            "Content-Type": "application/json",
            "Host": host,
            "User-Agent": "goalkeeper-email-service/0.1.0"
        }
    
    async def health_check(self) -> bool:
        """
        Perform a health check to verify Azure Communication Services connectivity.
        
        Returns:
            bool: True if service is healthy, False otherwise
        """
        try:
            logger.debug("Performing Azure Communication Services health check")
            
            # Make a simple request to check connectivity
            # Note: Azure Communication Services doesn't have a dedicated health endpoint,
            # so we'll just verify we can connect to the service
            url = urljoin(self.base_url, "/")
            
            async with httpx.AsyncClient(timeout=httpx.Timeout(10.0)) as client:
                response = await client.get(url)
                
                # Any response (even 404) indicates the service is reachable
                is_healthy = True
                
                logger.debug(
                    "Azure health check completed",
                    extra={
                        "status_code": response.status_code,
                        "is_healthy": is_healthy
                    }
                )
                
                return is_healthy
                
        except Exception as e:
            logger.error(
                "Azure health check failed",
                extra={"error": str(e)}
            )
            return False