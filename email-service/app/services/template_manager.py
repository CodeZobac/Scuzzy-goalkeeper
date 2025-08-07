"""Email template management service using Jinja2."""

import logging
from pathlib import Path
from typing import Dict, Any, Optional

from jinja2 import Environment, FileSystemLoader, Template, TemplateNotFound, TemplateSyntaxError

from app.config import settings
from app.models.auth_code import AuthCodeType


logger = logging.getLogger(__name__)


class TemplateManagerError(Exception):
    """Base exception for template manager errors."""
    pass


class TemplateNotFoundError(TemplateManagerError):
    """Raised when a template file is not found."""
    pass


class TemplateRenderError(TemplateManagerError):
    """Raised when template rendering fails."""
    pass


class TemplateManager:
    """Manages HTML email templates using Jinja2 for rendering."""
    
    # Template file mappings
    TEMPLATE_FILES = {
        AuthCodeType.EMAIL_CONFIRMATION: "confirm_signup_template.html",
        AuthCodeType.PASSWORD_RESET: "reset_password_template.html",
    }
    
    def __init__(self, templates_dir: Optional[Path] = None):
        """
        Initialize the template manager.
        
        Args:
            templates_dir: Path to templates directory. If None, uses default.
        """
        if templates_dir is None:
            # Default to templates directory relative to the project root
            project_root = Path(__file__).parent.parent.parent
            templates_dir = project_root / "templates"
        
        self.templates_dir = Path(templates_dir)
        
        # Validate templates directory exists
        if not self.templates_dir.exists():
            raise TemplateManagerError(f"Templates directory not found: {self.templates_dir}")
        
        # Initialize Jinja2 environment
        self.env = Environment(
            loader=FileSystemLoader(str(self.templates_dir)),
            autoescape=True,  # Enable auto-escaping for security
            trim_blocks=True,
            lstrip_blocks=True,
        )
        
        logger.info(f"TemplateManager initialized with templates directory: {self.templates_dir}")
        
        # Validate all required templates exist
        self._validate_templates()
    
    def _validate_templates(self) -> None:
        """Validate that all required template files exist."""
        missing_templates = []
        
        for code_type, template_file in self.TEMPLATE_FILES.items():
            template_path = self.templates_dir / template_file
            if not template_path.exists():
                missing_templates.append(f"{code_type.value}: {template_file}")
        
        if missing_templates:
            raise TemplateNotFoundError(
                f"Missing template files: {', '.join(missing_templates)}"
            )
        
        logger.info("All required templates validated successfully")
    
    def load_template(self, template_name: str) -> Template:
        """
        Load a Jinja2 template by name.
        
        Args:
            template_name: Name of the template file
            
        Returns:
            Jinja2 Template object
            
        Raises:
            TemplateNotFoundError: If template file is not found
            TemplateRenderError: If template has syntax errors
        """
        try:
            template = self.env.get_template(template_name)
            logger.debug(f"Successfully loaded template: {template_name}")
            return template
        except TemplateNotFound as e:
            logger.error(f"Template not found: {template_name}")
            raise TemplateNotFoundError(f"Template not found: {template_name}") from e
        except TemplateSyntaxError as e:
            logger.error(f"Template syntax error in {template_name}: {e}")
            raise TemplateRenderError(f"Template syntax error in {template_name}: {e}") from e
    
    def render_template(self, template: Template, variables: Dict[str, Any]) -> str:
        """
        Render a template with the provided variables.
        
        Args:
            template: Jinja2 Template object
            variables: Dictionary of variables to pass to the template
            
        Returns:
            Rendered HTML string
            
        Raises:
            TemplateRenderError: If template rendering fails
        """
        try:
            rendered = template.render(**variables)
            logger.debug(f"Successfully rendered template with variables: {list(variables.keys())}")
            return rendered
        except Exception as e:
            logger.error(f"Template rendering failed: {e}")
            raise TemplateRenderError(f"Template rendering failed: {e}") from e
    
    def generate_confirmation_url(self, auth_code: str) -> str:
        """
        Generate a confirmation URL with the authentication code.
        
        Args:
            auth_code: The authentication code to include in the URL
            
        Returns:
            Complete confirmation URL
        """
        url = f"{settings.confirmation_url_base}?code={auth_code}"
        logger.debug(f"Generated confirmation URL for code: {auth_code[:8]}...")
        return url
    
    def generate_reset_url(self, auth_code: str) -> str:
        """
        Generate a password reset URL with the authentication code.
        
        Args:
            auth_code: The authentication code to include in the URL
            
        Returns:
            Complete password reset URL
        """
        url = f"{settings.reset_url_base}?code={auth_code}"
        logger.debug(f"Generated reset URL for code: {auth_code[:8]}...")
        return url
    
    def render_confirmation_email(self, auth_code: str, **extra_variables) -> str:
        """
        Render the email confirmation template.
        
        Args:
            auth_code: Authentication code for the confirmation URL
            **extra_variables: Additional variables to pass to the template
            
        Returns:
            Rendered HTML email content
            
        Raises:
            TemplateNotFoundError: If confirmation template is not found
            TemplateRenderError: If template rendering fails
        """
        template_file = self.TEMPLATE_FILES[AuthCodeType.EMAIL_CONFIRMATION]
        template = self.load_template(template_file)
        
        variables = {
            'confirmation_url': self.generate_confirmation_url(auth_code),
            **extra_variables
        }
        
        rendered_content = self.render_template(template, variables)
        logger.info(f"Rendered confirmation email template for code: {auth_code[:8]}...")
        return rendered_content
    
    def render_password_reset_email(self, auth_code: str, **extra_variables) -> str:
        """
        Render the password reset email template.
        
        Args:
            auth_code: Authentication code for the reset URL
            **extra_variables: Additional variables to pass to the template
            
        Returns:
            Rendered HTML email content
            
        Raises:
            TemplateNotFoundError: If reset template is not found
            TemplateRenderError: If template rendering fails
        """
        template_file = self.TEMPLATE_FILES[AuthCodeType.PASSWORD_RESET]
        template = self.load_template(template_file)
        
        variables = {
            'reset_url': self.generate_reset_url(auth_code),
            **extra_variables
        }
        
        rendered_content = self.render_template(template, variables)
        logger.info(f"Rendered password reset email template for code: {auth_code[:8]}...")
        return rendered_content
    
    def render_email_by_type(self, code_type: AuthCodeType, auth_code: str, **extra_variables) -> str:
        """
        Render an email template based on the authentication code type.
        
        Args:
            code_type: Type of authentication code (EMAIL_CONFIRMATION or PASSWORD_RESET)
            auth_code: Authentication code for URL generation
            **extra_variables: Additional variables to pass to the template
            
        Returns:
            Rendered HTML email content
            
        Raises:
            TemplateNotFoundError: If template is not found
            TemplateRenderError: If template rendering fails
            ValueError: If code_type is not supported
        """
        if code_type == AuthCodeType.EMAIL_CONFIRMATION:
            return self.render_confirmation_email(auth_code, **extra_variables)
        elif code_type == AuthCodeType.PASSWORD_RESET:
            return self.render_password_reset_email(auth_code, **extra_variables)
        else:
            raise ValueError(f"Unsupported authentication code type: {code_type}")
    
    def get_available_templates(self) -> Dict[AuthCodeType, str]:
        """
        Get a mapping of available templates.
        
        Returns:
            Dictionary mapping AuthCodeType to template file names
        """
        return self.TEMPLATE_FILES.copy()
    
    def validate_template_syntax(self, template_name: str) -> bool:
        """
        Validate that a template has correct syntax.
        
        Args:
            template_name: Name of the template file to validate
            
        Returns:
            True if template syntax is valid
            
        Raises:
            TemplateNotFoundError: If template is not found
            TemplateRenderError: If template has syntax errors
        """
        try:
            self.load_template(template_name)
            logger.info(f"Template syntax validation passed: {template_name}")
            return True
        except (TemplateNotFoundError, TemplateRenderError):
            raise