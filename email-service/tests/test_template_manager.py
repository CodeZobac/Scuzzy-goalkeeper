"""Tests for TemplateManager."""

import pytest
from pathlib import Path
from unittest.mock import Mock, patch
import tempfile
import os

from app.services.template_manager import (
    TemplateManager, 
    TemplateManagerError, 
    TemplateNotFoundError, 
    TemplateRenderError
)
from app.models.auth_code import AuthCodeType


class TestTemplateManager:
    """Test cases for TemplateManager."""
    
    @pytest.fixture
    def temp_templates_dir(self):
        """Create a temporary directory with test templates."""
        with tempfile.TemporaryDirectory() as temp_dir:
            templates_dir = Path(temp_dir)
            
            # Create test templates
            confirmation_template = templates_dir / "confirm_signup_template.html"
            confirmation_template.write_text("""
<!DOCTYPE html>
<html>
<head><title>Confirm Email</title></head>
<body>
    <h1>Welcome!</h1>
    <p>Click here to confirm: <a href="{{ confirmation_url }}">Confirm</a></p>
</body>
</html>
            """.strip())
            
            reset_template = templates_dir / "reset_password_template.html"
            reset_template.write_text("""
<!DOCTYPE html>
<html>
<head><title>Reset Password</title></head>
<body>
    <h1>Reset Password</h1>
    <p>Click here to reset: <a href="{{ reset_url }}">Reset</a></p>
</body>
</html>
            """.strip())
            
            yield templates_dir
    
    @pytest.fixture
    def template_manager(self, temp_templates_dir):
        """Create a TemplateManager instance with test templates."""
        return TemplateManager(templates_dir=temp_templates_dir)
    
    def test_init_with_valid_directory(self, temp_templates_dir):
        """Test initialization with valid templates directory."""
        manager = TemplateManager(templates_dir=temp_templates_dir)
        assert manager.templates_dir == temp_templates_dir
        assert manager.env is not None
    
    def test_init_with_nonexistent_directory(self):
        """Test initialization with nonexistent directory raises error."""
        nonexistent_dir = Path("/nonexistent/directory")
        with pytest.raises(TemplateManagerError, match="Templates directory not found"):
            TemplateManager(templates_dir=nonexistent_dir)
    
    def test_init_with_missing_templates(self):
        """Test initialization with missing template files raises error."""
        with tempfile.TemporaryDirectory() as temp_dir:
            templates_dir = Path(temp_dir)
            # Only create one template, missing the other
            (templates_dir / "confirm_signup_template.html").write_text("<html></html>")
            
            with pytest.raises(TemplateNotFoundError, match="Missing template files"):
                TemplateManager(templates_dir=templates_dir)
    
    def test_load_template_success(self, template_manager):
        """Test successfully loading a template."""
        template = template_manager.load_template("confirm_signup_template.html")
        assert template is not None
        assert hasattr(template, 'render')
    
    def test_load_template_not_found(self, template_manager):
        """Test loading nonexistent template raises error."""
        with pytest.raises(TemplateNotFoundError, match="Template not found"):
            template_manager.load_template("nonexistent_template.html")
    
    def test_render_template_success(self, template_manager):
        """Test successfully rendering a template."""
        template = template_manager.load_template("confirm_signup_template.html")
        variables = {"confirmation_url": "https://example.com/confirm?code=ABC123"}
        
        rendered = template_manager.render_template(template, variables)
        
        assert "https://example.com/confirm?code=ABC123" in rendered
        assert "Welcome!" in rendered
    
    def test_render_template_with_missing_variable(self, template_manager):
        """Test rendering template with missing required variable."""
        template = template_manager.load_template("confirm_signup_template.html")
        variables = {}  # Missing confirmation_url
        
        # Jinja2 will render undefined variables as empty strings by default
        rendered = template_manager.render_template(template, variables)
        assert rendered is not None
    
    @patch('app.services.template_manager.settings')
    def test_generate_confirmation_url(self, mock_settings, template_manager):
        """Test generating confirmation URL."""
        mock_settings.confirmation_url_base = "https://example.com/auth/confirm"
        
        url = template_manager.generate_confirmation_url("ABC123DEF456")
        
        assert url == "https://example.com/auth/confirm?code=ABC123DEF456"
    
    @patch('app.services.template_manager.settings')
    def test_generate_reset_url(self, mock_settings, template_manager):
        """Test generating password reset URL."""
        mock_settings.reset_url_base = "https://example.com/auth/reset"
        
        url = template_manager.generate_reset_url("XYZ789GHI012")
        
        assert url == "https://example.com/auth/reset?code=XYZ789GHI012"
    
    @patch('app.services.template_manager.settings')
    def test_render_confirmation_email(self, mock_settings, template_manager):
        """Test rendering confirmation email."""
        mock_settings.confirmation_url_base = "https://example.com/auth/confirm"
        
        rendered = template_manager.render_confirmation_email("ABC123DEF456")
        
        assert "https://example.com/auth/confirm?code=ABC123DEF456" in rendered
        assert "Welcome!" in rendered
    
    @patch('app.services.template_manager.settings')
    def test_render_password_reset_email(self, mock_settings, template_manager):
        """Test rendering password reset email."""
        mock_settings.reset_url_base = "https://example.com/auth/reset"
        
        rendered = template_manager.render_password_reset_email("XYZ789GHI012")
        
        assert "https://example.com/auth/reset?code=XYZ789GHI012" in rendered
        assert "Reset Password" in rendered
    
    @patch('app.services.template_manager.settings')
    def test_render_email_by_type_confirmation(self, mock_settings, template_manager):
        """Test rendering email by type for confirmation."""
        mock_settings.confirmation_url_base = "https://example.com/auth/confirm"
        
        rendered = template_manager.render_email_by_type(
            AuthCodeType.EMAIL_CONFIRMATION, 
            "ABC123DEF456"
        )
        
        assert "https://example.com/auth/confirm?code=ABC123DEF456" in rendered
        assert "Welcome!" in rendered
    
    @patch('app.services.template_manager.settings')
    def test_render_email_by_type_reset(self, mock_settings, template_manager):
        """Test rendering email by type for password reset."""
        mock_settings.reset_url_base = "https://example.com/auth/reset"
        
        rendered = template_manager.render_email_by_type(
            AuthCodeType.PASSWORD_RESET, 
            "XYZ789GHI012"
        )
        
        assert "https://example.com/auth/reset?code=XYZ789GHI012" in rendered
        assert "Reset Password" in rendered
    
    def test_render_email_by_type_invalid_type(self, template_manager):
        """Test rendering email with invalid code type raises error."""
        with pytest.raises(ValueError, match="Unsupported authentication code type"):
            template_manager.render_email_by_type("invalid_type", "ABC123")
    
    def test_get_available_templates(self, template_manager):
        """Test getting available templates mapping."""
        templates = template_manager.get_available_templates()
        
        assert AuthCodeType.EMAIL_CONFIRMATION in templates
        assert AuthCodeType.PASSWORD_RESET in templates
        assert templates[AuthCodeType.EMAIL_CONFIRMATION] == "confirm_signup_template.html"
        assert templates[AuthCodeType.PASSWORD_RESET] == "reset_password_template.html"
    
    def test_validate_template_syntax_valid(self, template_manager):
        """Test validating template with correct syntax."""
        result = template_manager.validate_template_syntax("confirm_signup_template.html")
        assert result is True
    
    def test_validate_template_syntax_not_found(self, template_manager):
        """Test validating nonexistent template raises error."""
        with pytest.raises(TemplateNotFoundError):
            template_manager.validate_template_syntax("nonexistent_template.html")
    
    def test_render_with_extra_variables(self, template_manager):
        """Test rendering templates with extra variables."""
        # Create a template that uses extra variables
        with tempfile.TemporaryDirectory() as temp_dir:
            templates_dir = Path(temp_dir)
            
            # Create templates with extra variables
            confirmation_template = templates_dir / "confirm_signup_template.html"
            confirmation_template.write_text("""
<html>
<body>
    <h1>Hello {{ user_name }}!</h1>
    <p>Your email: {{ user_email }}</p>
    <a href="{{ confirmation_url }}">Confirm</a>
</body>
</html>
            """.strip())
            
            reset_template = templates_dir / "reset_password_template.html"
            reset_template.write_text("""
<html>
<body>
    <h1>Reset for {{ user_name }}</h1>
    <a href="{{ reset_url }}">Reset</a>
</body>
</html>
            """.strip())
            
            manager = TemplateManager(templates_dir=templates_dir)
            
            with patch('app.services.template_manager.settings') as mock_settings:
                mock_settings.confirmation_url_base = "https://example.com/confirm"
                mock_settings.reset_url_base = "https://example.com/reset"
                
                # Test confirmation email with extra variables
                rendered = manager.render_confirmation_email(
                    "ABC123", 
                    user_name="John Doe", 
                    user_email="john@example.com"
                )
                
                assert "Hello John Doe!" in rendered
                assert "john@example.com" in rendered
                assert "https://example.com/confirm?code=ABC123" in rendered
                
                # Test reset email with extra variables
                rendered = manager.render_password_reset_email(
                    "XYZ789", 
                    user_name="Jane Smith"
                )
                
                assert "Reset for Jane Smith" in rendered
                assert "https://example.com/reset?code=XYZ789" in rendered