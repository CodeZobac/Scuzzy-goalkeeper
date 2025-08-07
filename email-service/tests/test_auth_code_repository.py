"""Tests for AuthCodeRepository."""

import pytest
from datetime import datetime, timezone, timedelta
from unittest.mock import Mock, patch
import uuid

from app.models.auth_code import AuthCode, AuthCodeType
from app.repositories.auth_code_repository import AuthCodeRepository, AuthCodeRepositoryError


class TestAuthCodeRepository:
    """Test cases for AuthCodeRepository."""
    
    @pytest.fixture
    def mock_supabase_client(self):
        """Create a mock Supabase client."""
        return Mock()
    
    @pytest.fixture
    def repository(self, mock_supabase_client):
        """Create a repository instance with mocked client."""
        return AuthCodeRepository(supabase_client=mock_supabase_client)
    
    @pytest.fixture
    def sample_auth_code(self):
        """Create a sample AuthCode for testing."""
        now = datetime.now(timezone.utc)
        return AuthCode(
            id=str(uuid.uuid4()),
            code="hashed_code_here",
            user_id="test-user-123",
            type=AuthCodeType.EMAIL_CONFIRMATION,
            created_at=now,
            expires_at=now + timedelta(minutes=5),
            is_used=False,
            used_at=None
        )
    
    def test_hash_code(self, repository):
        """Test code hashing functionality."""
        plain_code = "ABC123DEF456"
        hashed = repository._hash_code(plain_code)
        
        assert hashed != plain_code
        assert len(hashed) > 0
        assert isinstance(hashed, str)
    
    def test_verify_code(self, repository):
        """Test code verification functionality."""
        plain_code = "ABC123DEF456"
        hashed = repository._hash_code(plain_code)
        
        # Should verify correctly
        assert repository._verify_code(plain_code, hashed) is True
        
        # Should fail with wrong code
        assert repository._verify_code("WRONG123", hashed) is False
    
    def test_store_auth_code_success(self, repository, mock_supabase_client, sample_auth_code):
        """Test successful auth code storage."""
        # Mock successful database response
        mock_table = Mock()
        mock_supabase_client.table.return_value = mock_table
        mock_table.insert.return_value.execute.return_value.data = [{"id": sample_auth_code.id}]
        
        plain_code = "ABC123DEF456"
        result = repository.store_auth_code(sample_auth_code, plain_code)
        
        assert result is True
        mock_supabase_client.table.assert_called_with("auth_codes")
        mock_table.insert.assert_called_once()
    
    def test_store_auth_code_failure(self, repository, mock_supabase_client, sample_auth_code):
        """Test auth code storage failure."""
        # Mock database error
        mock_table = Mock()
        mock_supabase_client.table.return_value = mock_table
        mock_table.insert.return_value.execute.side_effect = Exception("Database error")
        
        plain_code = "ABC123DEF456"
        
        with pytest.raises(AuthCodeRepositoryError):
            repository.store_auth_code(sample_auth_code, plain_code)
    
    def test_get_auth_code_by_code_found(self, repository, mock_supabase_client):
        """Test retrieving auth code by code when found."""
        # Mock database response with matching code
        mock_table = Mock()
        mock_supabase_client.table.return_value = mock_table
        
        now = datetime.now(timezone.utc)
        mock_data = {
            "id": "test-id-123",
            "code": repository._hash_code("ABC123DEF456"),
            "user_id": "test-user-123",
            "type": "email_confirmation",
            "created_at": now.isoformat(),
            "expires_at": (now + timedelta(minutes=5)).isoformat(),
            "is_used": False,
            "used_at": None
        }
        
        mock_table.select.return_value.eq.return_value.eq.return_value.execute.return_value.data = [mock_data]
        
        result = repository.get_auth_code_by_code("ABC123DEF456", AuthCodeType.EMAIL_CONFIRMATION)
        
        assert result is not None
        assert result.id == "test-id-123"
        assert result.user_id == "test-user-123"
        assert result.type == AuthCodeType.EMAIL_CONFIRMATION
    
    def test_get_auth_code_by_code_not_found(self, repository, mock_supabase_client):
        """Test retrieving auth code by code when not found."""
        # Mock empty database response
        mock_table = Mock()
        mock_supabase_client.table.return_value = mock_table
        mock_table.select.return_value.eq.return_value.eq.return_value.execute.return_value.data = []
        
        result = repository.get_auth_code_by_code("NONEXISTENT", AuthCodeType.EMAIL_CONFIRMATION)
        
        assert result is None
    
    def test_mark_code_as_used_success(self, repository, mock_supabase_client):
        """Test successfully marking code as used."""
        # Mock successful update response
        mock_table = Mock()
        mock_supabase_client.table.return_value = mock_table
        mock_table.update.return_value.eq.return_value.execute.return_value.data = [{"id": "test-id"}]
        
        result = repository.mark_code_as_used("test-id")
        
        assert result is True
        mock_table.update.assert_called_once()
    
    def test_mark_code_as_used_not_found(self, repository, mock_supabase_client):
        """Test marking code as used when code doesn't exist."""
        # Mock empty update response
        mock_table = Mock()
        mock_supabase_client.table.return_value = mock_table
        mock_table.update.return_value.eq.return_value.execute.return_value.data = []
        
        result = repository.mark_code_as_used("nonexistent-id")
        
        assert result is False
    
    def test_delete_expired_codes(self, repository, mock_supabase_client):
        """Test deleting expired codes."""
        # Mock delete response
        mock_table = Mock()
        mock_supabase_client.table.return_value = mock_table
        mock_table.delete.return_value.lt.return_value.execute.return_value.data = [
            {"id": "expired1"}, {"id": "expired2"}
        ]
        
        result = repository.delete_expired_codes()
        
        assert result == 2
        mock_table.delete.assert_called_once()
    
    def test_get_codes_by_user_id(self, repository, mock_supabase_client):
        """Test retrieving codes by user ID."""
        # Mock database response
        mock_table = Mock()
        mock_supabase_client.table.return_value = mock_table
        
        now = datetime.now(timezone.utc)
        mock_data = [{
            "id": "test-id-123",
            "code": "hashed_code",
            "user_id": "test-user-123",
            "type": "email_confirmation",
            "created_at": now.isoformat(),
            "expires_at": (now + timedelta(minutes=5)).isoformat(),
            "is_used": False,
            "used_at": None
        }]
        
        mock_table.select.return_value.eq.return_value.execute.return_value.data = mock_data
        
        result = repository.get_codes_by_user_id("test-user-123")
        
        assert len(result) == 1
        assert result[0].user_id == "test-user-123"
    
    def test_cleanup_all_expired_and_used_codes(self, repository):
        """Test comprehensive cleanup operation."""
        with patch.object(repository, 'delete_expired_codes', return_value=3), \
             patch.object(repository, 'delete_used_codes_older_than_hours', return_value=2):
            
            result = repository.cleanup_all_expired_and_used_codes()
            
            assert result["expired_deleted"] == 3
            assert result["old_used_deleted"] == 2
            assert result["total_deleted"] == 5