"""Service for managing authentication codes with secure generation and validation."""

import logging
import secrets
import string
import uuid
from datetime import datetime, timedelta, timezone
from typing import Optional

from app.config import settings
from app.models.auth_code import AuthCode, AuthCodeType
from app.repositories.auth_code_repository import AuthCodeRepository, AuthCodeRepositoryError


logger = logging.getLogger(__name__)


class AuthCodeServiceError(Exception):
    """Base exception for AuthCodeService operations."""
    pass


class AuthCodeService:
    """Service for managing authentication codes with secure generation and validation."""
    
    def __init__(self, repository: Optional[AuthCodeRepository] = None):
        """Initialize the service with a repository.
        
        Args:
            repository: Optional AuthCodeRepository instance. If not provided, creates a new one.
        """
        self._repository = repository or AuthCodeRepository()
        self._code_length = 32
        self._expiration_minutes = 5
        logger.info("AuthCodeService initialized")
    
    def _generate_secure_code(self) -> str:
        """Generate a cryptographically secure authentication code.
        
        Returns:
            32-character alphanumeric authentication code
        """
        try:
            # Use secrets module for cryptographically secure random generation
            alphabet = string.ascii_letters + string.digits
            code = ''.join(secrets.choice(alphabet) for _ in range(self._code_length))
            
            logger.debug("Generated secure authentication code")
            return code
            
        except Exception as e:
            logger.error(f"Failed to generate secure authentication code: {e}")
            raise AuthCodeServiceError(f"Code generation failed: {e}")
    
    def _generate_unique_id(self) -> str:
        """Generate a unique identifier for the authentication code.
        
        Returns:
            UUID string for the authentication code
        """
        return str(uuid.uuid4())
    
    def _calculate_expiration_time(self) -> datetime:
        """Calculate the expiration time for a new authentication code.
        
        Returns:
            Datetime object representing when the code expires
        """
        return datetime.now(timezone.utc) + timedelta(minutes=self._expiration_minutes)
    
    def generate_code(self, user_id: str, code_type: AuthCodeType) -> str:
        """Generate a new authentication code for a user.
        
        Args:
            user_id: ID of the user the code is for
            code_type: Type of authentication code (email_confirmation or password_reset)
            
        Returns:
            Plain text authentication code (to be sent in email)
            
        Raises:
            AuthCodeServiceError: If code generation or storage fails
        """
        try:
            logger.info(f"Generating authentication code for user {user_id}, type: {code_type}")
            
            # Validate inputs
            if not user_id or not user_id.strip():
                raise AuthCodeServiceError("user_id cannot be empty")
            
            # Convert string to AuthCodeType if needed
            if isinstance(code_type, str):
                try:
                    code_type = AuthCodeType(code_type)
                except ValueError:
                    raise AuthCodeServiceError("Invalid code_type provided")
            elif not isinstance(code_type, AuthCodeType):
                raise AuthCodeServiceError("Invalid code_type provided")
            
            # Generate secure code and metadata
            plain_code = self._generate_secure_code()
            code_id = self._generate_unique_id()
            current_time = datetime.now(timezone.utc)
            expiration_time = self._calculate_expiration_time()
            
            # Create AuthCode instance
            auth_code = AuthCode(
                id=code_id,
                code="placeholder",  # Will be set to hashed version in repository
                user_id=user_id.strip(),
                type=code_type,
                created_at=current_time,
                expires_at=expiration_time,
                is_used=False,
                used_at=None
            )
            
            # Store in database (repository will hash the code)
            success = self._repository.store_auth_code(auth_code, plain_code)
            
            if not success:
                logger.error(f"Failed to store authentication code {code_id}")
                raise AuthCodeServiceError("Failed to store authentication code")
            
            logger.info(f"Successfully generated authentication code {code_id} for user {user_id}")
            return plain_code
            
        except AuthCodeRepositoryError as e:
            logger.error(f"Repository error generating code for user {user_id}: {e}")
            raise AuthCodeServiceError(f"Database error: {e}")
        except Exception as e:
            logger.error(f"Unexpected error generating code for user {user_id}: {e}")
            raise AuthCodeServiceError(f"Code generation failed: {e}")
    
    def validate_code(self, code: str, code_type: AuthCodeType) -> Optional[AuthCode]:
        """Validate an authentication code.
        
        Args:
            code: Plain text authentication code to validate
            code_type: Expected type of authentication code
            
        Returns:
            AuthCode instance if valid, None if invalid
            
        Raises:
            AuthCodeServiceError: If validation process fails
        """
        try:
            logger.info(f"Validating authentication code of type: {code_type}")
            
            # Validate inputs
            if not code or not code.strip():
                logger.warning("Empty authentication code provided for validation")
                return None
            
            # Convert string to AuthCodeType if needed
            if isinstance(code_type, str):
                try:
                    code_type = AuthCodeType(code_type)
                except ValueError:
                    raise AuthCodeServiceError("Invalid code_type provided")
            elif not isinstance(code_type, AuthCodeType):
                raise AuthCodeServiceError("Invalid code_type provided")
            
            # Retrieve code from database
            auth_code = self._repository.get_auth_code_by_code(code.strip(), code_type)
            
            if not auth_code:
                logger.info("Authentication code not found in database")
                return None
            
            # Check if code is already used
            if auth_code.is_used:
                logger.warning(f"Authentication code {auth_code.id} has already been used")
                return None
            
            # Check if code has expired
            if auth_code.is_expired:
                logger.warning(f"Authentication code {auth_code.id} has expired")
                return None
            
            # Code is valid
            logger.info(f"Authentication code {auth_code.id} is valid for user {auth_code.user_id}")
            return auth_code
            
        except AuthCodeRepositoryError as e:
            logger.error(f"Repository error validating code: {e}")
            raise AuthCodeServiceError(f"Database error: {e}")
        except Exception as e:
            logger.error(f"Unexpected error validating code: {e}")
            raise AuthCodeServiceError(f"Code validation failed: {e}")
    
    def invalidate_code(self, code: str, code_type: AuthCodeType) -> bool:
        """Invalidate an authentication code by marking it as used.
        
        Args:
            code: Plain text authentication code to invalidate
            code_type: Type of authentication code
            
        Returns:
            True if code was successfully invalidated, False if code was not found
            
        Raises:
            AuthCodeServiceError: If invalidation process fails
        """
        try:
            logger.info(f"Invalidating authentication code of type: {code_type}")
            
            # Validate inputs
            if not code or not code.strip():
                logger.warning("Empty authentication code provided for invalidation")
                return False
            
            # Convert string to AuthCodeType if needed
            if isinstance(code_type, str):
                try:
                    code_type = AuthCodeType(code_type)
                except ValueError:
                    raise AuthCodeServiceError("Invalid code_type provided")
            elif not isinstance(code_type, AuthCodeType):
                raise AuthCodeServiceError("Invalid code_type provided")
            
            # First validate the code to get its ID
            auth_code = self.validate_code(code, code_type)
            
            if not auth_code:
                logger.info("Cannot invalidate: authentication code not found or already invalid")
                return False
            
            # Mark code as used in database
            success = self._repository.mark_code_as_used(auth_code.id)
            
            if success:
                logger.info(f"Successfully invalidated authentication code {auth_code.id}")
            else:
                logger.error(f"Failed to invalidate authentication code {auth_code.id}")
            
            return success
            
        except AuthCodeRepositoryError as e:
            logger.error(f"Repository error invalidating code: {e}")
            raise AuthCodeServiceError(f"Database error: {e}")
        except Exception as e:
            logger.error(f"Unexpected error invalidating code: {e}")
            raise AuthCodeServiceError(f"Code invalidation failed: {e}")
    
    def invalidate_code_by_id(self, code_id: str) -> bool:
        """Invalidate an authentication code by its ID.
        
        Args:
            code_id: Unique identifier of the authentication code
            
        Returns:
            True if code was successfully invalidated, False if code was not found
            
        Raises:
            AuthCodeServiceError: If invalidation process fails
        """
        try:
            logger.info(f"Invalidating authentication code by ID: {code_id}")
            
            # Validate input
            if not code_id or not code_id.strip():
                logger.warning("Empty code_id provided for invalidation")
                return False
            
            # Check if code exists and is valid
            auth_code = self._repository.get_auth_code_by_id(code_id.strip())
            
            if not auth_code:
                logger.info(f"Authentication code {code_id} not found")
                return False
            
            if auth_code.is_used:
                logger.info(f"Authentication code {code_id} is already used")
                return True  # Already invalidated, consider this success
            
            # Mark code as used in database
            success = self._repository.mark_code_as_used(code_id.strip())
            
            if success:
                logger.info(f"Successfully invalidated authentication code {code_id}")
            else:
                logger.error(f"Failed to invalidate authentication code {code_id}")
            
            return success
            
        except AuthCodeRepositoryError as e:
            logger.error(f"Repository error invalidating code {code_id}: {e}")
            raise AuthCodeServiceError(f"Database error: {e}")
        except Exception as e:
            logger.error(f"Unexpected error invalidating code {code_id}: {e}")
            raise AuthCodeServiceError(f"Code invalidation failed: {e}")
    
    def cleanup_expired_codes(self) -> int:
        """Clean up expired authentication codes from the database.
        
        Returns:
            Number of codes cleaned up
            
        Raises:
            AuthCodeServiceError: If cleanup process fails
        """
        try:
            logger.info("Starting cleanup of expired authentication codes")
            
            deleted_count = self._repository.delete_expired_codes()
            
            logger.info(f"Cleanup completed: removed {deleted_count} expired codes")
            return deleted_count
            
        except AuthCodeRepositoryError as e:
            logger.error(f"Repository error during cleanup: {e}")
            raise AuthCodeServiceError(f"Database error: {e}")
        except Exception as e:
            logger.error(f"Unexpected error during cleanup: {e}")
            raise AuthCodeServiceError(f"Cleanup failed: {e}")
    
    def get_user_codes(self, user_id: str, code_type: Optional[AuthCodeType] = None) -> list[AuthCode]:
        """Get all authentication codes for a specific user.
        
        Args:
            user_id: ID of the user
            code_type: Optional filter by code type
            
        Returns:
            List of AuthCode instances for the user
            
        Raises:
            AuthCodeServiceError: If retrieval process fails
        """
        try:
            logger.info(f"Retrieving authentication codes for user {user_id}")
            
            # Validate input
            if not user_id or not user_id.strip():
                raise AuthCodeServiceError("user_id cannot be empty")
            
            codes = self._repository.get_codes_by_user_id(user_id.strip(), code_type)
            
            logger.info(f"Retrieved {len(codes)} authentication codes for user {user_id}")
            return codes
            
        except AuthCodeRepositoryError as e:
            logger.error(f"Repository error retrieving codes for user {user_id}: {e}")
            raise AuthCodeServiceError(f"Database error: {e}")
        except Exception as e:
            logger.error(f"Unexpected error retrieving codes for user {user_id}: {e}")
            raise AuthCodeServiceError(f"Code retrieval failed: {e}")
    
    def is_code_valid_for_user(self, code: str, code_type: AuthCodeType, user_id: str) -> bool:
        """Check if a code is valid for a specific user.
        
        Args:
            code: Plain text authentication code
            code_type: Type of authentication code
            user_id: Expected user ID
            
        Returns:
            True if code is valid for the user, False otherwise
            
        Raises:
            AuthCodeServiceError: If validation process fails
        """
        try:
            logger.info(f"Validating code for specific user {user_id}, type: {code_type}")
            
            # Validate the code
            auth_code = self.validate_code(code, code_type)
            
            if not auth_code:
                logger.info("Code validation failed")
                return False
            
            # Check if code belongs to the expected user
            if auth_code.user_id != user_id:
                logger.warning(f"Code belongs to user {auth_code.user_id}, expected {user_id}")
                return False
            
            logger.info(f"Code is valid for user {user_id}")
            return True
            
        except Exception as e:
            logger.error(f"Error validating code for user {user_id}: {e}")
            raise AuthCodeServiceError(f"User code validation failed: {e}")
    
    def get_service_stats(self) -> dict:
        """Get statistics about the authentication code service.
        
        Returns:
            Dictionary with service statistics
            
        Raises:
            AuthCodeServiceError: If stats retrieval fails
        """
        try:
            logger.info("Retrieving authentication code service statistics")
            
            # Perform cleanup to get accurate stats
            expired_cleaned = self.cleanup_expired_codes()
            
            stats = {
                "code_length": self._code_length,
                "expiration_minutes": self._expiration_minutes,
                "expired_codes_cleaned": expired_cleaned,
                "service_status": "operational"
            }
            
            logger.info(f"Service statistics: {stats}")
            return stats
            
        except Exception as e:
            logger.error(f"Error retrieving service statistics: {e}")
            raise AuthCodeServiceError(f"Stats retrieval failed: {e}")