"""Repository for managing authentication codes in the database."""

import logging
from datetime import datetime, timezone
from typing import List, Optional

import bcrypt
from supabase import Client, create_client

from app.config import settings
from app.models.auth_code import AuthCode, AuthCodeType


logger = logging.getLogger(__name__)


class AuthCodeRepositoryError(Exception):
    """Base exception for AuthCodeRepository operations."""
    pass


class AuthCodeRepository:
    """Repository for managing authentication codes in Supabase database."""
    
    def __init__(self, supabase_client: Optional[Client] = None):
        """Initialize the repository with a Supabase client.
        
        Args:
            supabase_client: Optional Supabase client. If not provided, creates one from settings.
        """
        self._client = supabase_client or create_client(
            settings.supabase_url, 
            settings.supabase_service_role_key
        )
        self._table_name = "auth_codes"
        logger.info("AuthCodeRepository initialized")
    
    def _hash_code(self, code: str) -> str:
        """Hash an authentication code using bcrypt.
        
        Args:
            code: Plain text authentication code
            
        Returns:
            Hashed authentication code
        """
        try:
            salt = bcrypt.gensalt()
            hashed = bcrypt.hashpw(code.encode('utf-8'), salt)
            return hashed.decode('utf-8')
        except Exception as e:
            logger.error(f"Failed to hash authentication code: {e}")
            raise AuthCodeRepositoryError(f"Code hashing failed: {e}")
    
    def _verify_code(self, plain_code: str, hashed_code: str) -> bool:
        """Verify a plain text code against a hashed code.
        
        Args:
            plain_code: Plain text authentication code
            hashed_code: Hashed authentication code from database
            
        Returns:
            True if codes match, False otherwise
        """
        try:
            return bcrypt.checkpw(plain_code.encode('utf-8'), hashed_code.encode('utf-8'))
        except Exception as e:
            logger.error(f"Failed to verify authentication code: {e}")
            return False
    
    def store_auth_code(self, auth_code: AuthCode, plain_code: str) -> bool:
        """Store an authentication code in the database.
        
        Args:
            auth_code: AuthCode instance with metadata
            plain_code: Plain text authentication code to hash and store
            
        Returns:
            True if stored successfully, False otherwise
            
        Raises:
            AuthCodeRepositoryError: If database operation fails
        """
        try:
            # Hash the plain code before storing
            hashed_code = self._hash_code(plain_code)
            
            # Create a copy with the hashed code
            auth_code_data = auth_code.to_dict()
            auth_code_data['code'] = hashed_code
            
            logger.info(f"Storing auth code for user {auth_code.user_id}, type: {auth_code.type}")
            
            result = self._client.table(self._table_name).insert(auth_code_data).execute()
            
            if result.data:
                logger.info(f"Successfully stored auth code {auth_code.id}")
                return True
            else:
                logger.error(f"Failed to store auth code {auth_code.id}: No data returned")
                return False
                
        except Exception as e:
            logger.error(f"Database error storing auth code {auth_code.id}: {e}")
            raise AuthCodeRepositoryError(f"Failed to store auth code: {e}")
    
    def get_auth_code_by_code(self, plain_code: str, code_type: AuthCodeType) -> Optional[AuthCode]:
        """Retrieve an authentication code by its plain text value.
        
        Args:
            plain_code: Plain text authentication code to search for
            code_type: Type of authentication code to filter by
            
        Returns:
            AuthCode instance if found and valid, None otherwise
            
        Raises:
            AuthCodeRepositoryError: If database operation fails
        """
        try:
            logger.info(f"Searching for auth code of type: {code_type}")
            
            # Get all unused codes of the specified type
            result = self._client.table(self._table_name).select("*").eq(
                "type", code_type.value
            ).eq("is_used", False).execute()
            
            if not result.data:
                logger.info(f"No unused auth codes found for type: {code_type}")
                return None
            
            # Check each code to find a match
            for row in result.data:
                if self._verify_code(plain_code, row['code']):
                    logger.info(f"Found matching auth code {row['id']}")
                    return AuthCode.from_dict(row)
            
            logger.info(f"No matching auth code found for provided code")
            return None
            
        except Exception as e:
            logger.error(f"Database error retrieving auth code: {e}")
            raise AuthCodeRepositoryError(f"Failed to retrieve auth code: {e}")
    
    def get_auth_code_by_id(self, code_id: str) -> Optional[AuthCode]:
        """Retrieve an authentication code by its ID.
        
        Args:
            code_id: Unique identifier of the authentication code
            
        Returns:
            AuthCode instance if found, None otherwise
            
        Raises:
            AuthCodeRepositoryError: If database operation fails
        """
        try:
            logger.info(f"Retrieving auth code by ID: {code_id}")
            
            result = self._client.table(self._table_name).select("*").eq(
                "id", code_id
            ).execute()
            
            if result.data and len(result.data) > 0:
                logger.info(f"Found auth code {code_id}")
                return AuthCode.from_dict(result.data[0])
            else:
                logger.info(f"Auth code {code_id} not found")
                return None
                
        except Exception as e:
            logger.error(f"Database error retrieving auth code {code_id}: {e}")
            raise AuthCodeRepositoryError(f"Failed to retrieve auth code: {e}")
    
    def mark_code_as_used(self, code_id: str) -> bool:
        """Mark an authentication code as used.
        
        Args:
            code_id: Unique identifier of the authentication code
            
        Returns:
            True if marked successfully, False otherwise
            
        Raises:
            AuthCodeRepositoryError: If database operation fails
        """
        try:
            logger.info(f"Marking auth code {code_id} as used")
            
            current_time = datetime.now(timezone.utc).isoformat()
            
            result = self._client.table(self._table_name).update({
                "is_used": True,
                "used_at": current_time
            }).eq("id", code_id).execute()
            
            if result.data and len(result.data) > 0:
                logger.info(f"Successfully marked auth code {code_id} as used")
                return True
            else:
                logger.warning(f"No auth code found with ID {code_id} to mark as used")
                return False
                
        except Exception as e:
            logger.error(f"Database error marking auth code {code_id} as used: {e}")
            raise AuthCodeRepositoryError(f"Failed to mark auth code as used: {e}")
    
    def delete_expired_codes(self) -> int:
        """Delete all expired authentication codes from the database.
        
        Returns:
            Number of codes deleted
            
        Raises:
            AuthCodeRepositoryError: If database operation fails
        """
        try:
            current_time = datetime.now(timezone.utc).isoformat()
            
            logger.info("Cleaning up expired authentication codes")
            
            result = self._client.table(self._table_name).delete().lt(
                "expires_at", current_time
            ).execute()
            
            deleted_count = len(result.data) if result.data else 0
            logger.info(f"Deleted {deleted_count} expired authentication codes")
            
            return deleted_count
            
        except Exception as e:
            logger.error(f"Database error deleting expired codes: {e}")
            raise AuthCodeRepositoryError(f"Failed to delete expired codes: {e}")
    
    def delete_used_codes_older_than_hours(self, hours: int = 24) -> int:
        """Delete used authentication codes older than specified hours.
        
        Args:
            hours: Number of hours after which used codes should be deleted
            
        Returns:
            Number of codes deleted
            
        Raises:
            AuthCodeRepositoryError: If database operation fails
        """
        try:
            from datetime import timedelta
            
            cutoff_time = datetime.now(timezone.utc) - timedelta(hours=hours)
            cutoff_time_str = cutoff_time.isoformat()
            
            logger.info(f"Cleaning up used authentication codes older than {hours} hours")
            
            result = self._client.table(self._table_name).delete().eq(
                "is_used", True
            ).lt("used_at", cutoff_time_str).execute()
            
            deleted_count = len(result.data) if result.data else 0
            logger.info(f"Deleted {deleted_count} old used authentication codes")
            
            return deleted_count
            
        except Exception as e:
            logger.error(f"Database error deleting old used codes: {e}")
            raise AuthCodeRepositoryError(f"Failed to delete old used codes: {e}")
    
    def get_codes_by_user_id(self, user_id: str, code_type: Optional[AuthCodeType] = None) -> List[AuthCode]:
        """Get all authentication codes for a specific user.
        
        Args:
            user_id: User ID to search for
            code_type: Optional code type to filter by
            
        Returns:
            List of AuthCode instances
            
        Raises:
            AuthCodeRepositoryError: If database operation fails
        """
        try:
            logger.info(f"Retrieving auth codes for user {user_id}")
            
            query = self._client.table(self._table_name).select("*").eq("user_id", user_id)
            
            if code_type:
                query = query.eq("type", code_type.value)
            
            result = query.execute()
            
            codes = [AuthCode.from_dict(row) for row in result.data] if result.data else []
            logger.info(f"Found {len(codes)} auth codes for user {user_id}")
            
            return codes
            
        except Exception as e:
            logger.error(f"Database error retrieving codes for user {user_id}: {e}")
            raise AuthCodeRepositoryError(f"Failed to retrieve user codes: {e}")
    
    def cleanup_all_expired_and_used_codes(self) -> dict:
        """Perform comprehensive cleanup of expired and old used codes.
        
        Returns:
            Dictionary with cleanup statistics
            
        Raises:
            AuthCodeRepositoryError: If database operation fails
        """
        try:
            logger.info("Starting comprehensive auth code cleanup")
            
            expired_deleted = self.delete_expired_codes()
            used_deleted = self.delete_used_codes_older_than_hours(24)
            
            stats = {
                "expired_deleted": expired_deleted,
                "old_used_deleted": used_deleted,
                "total_deleted": expired_deleted + used_deleted
            }
            
            logger.info(f"Cleanup completed: {stats}")
            return stats
            
        except Exception as e:
            logger.error(f"Error during comprehensive cleanup: {e}")
            raise AuthCodeRepositoryError(f"Cleanup operation failed: {e}")