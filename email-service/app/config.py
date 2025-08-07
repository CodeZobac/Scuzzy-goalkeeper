"""Configuration management for the email service."""

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Application settings loaded from environment variables."""
    
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore"
    )
    
    # Server Configuration
    host: str = Field(default="0.0.0.0", description="Server host")
    port: int = Field(default=8000, description="Server port")
    environment: str = Field(default="development", description="Environment (development/production)")
    
    # Supabase Configuration
    supabase_url: str = Field(..., description="Supabase project URL")
    supabase_anon_key: str = Field(..., description="Supabase anonymous key")
    supabase_service_role_key: str = Field(..., description="Supabase service role key")
    
    # Azure Communication Services Configuration
    email_service: str = Field(..., description="Azure Communication Services endpoint")
    azure_key: str = Field(..., description="Azure Communication Services key")
    azure_connection_string: str = Field(..., description="Azure connection string")
    email_from_address: str = Field(..., description="From email address")
    email_from_name: str = Field(..., description="From email name")
    azure_mock_mode: bool = Field(default=False, description="Enable mock mode for Azure client (testing only)")
    
    # Application URLs
    app_base_url: str = Field(..., description="Base URL for the application")
    confirmation_redirect_path: str = Field(
        default="/auth/confirm", 
        description="Path for email confirmation redirects"
    )
    reset_redirect_path: str = Field(
        default="/auth/reset", 
        description="Path for password reset redirects"
    )
    
    # Logging Configuration
    log_level: str = Field(default="INFO", description="Logging level")
    log_format: str = Field(default="json", description="Logging format")
    
    @property
    def confirmation_url_base(self) -> str:
        """Get the base URL for confirmation links."""
        return f"{self.app_base_url.rstrip('/')}{self.confirmation_redirect_path}"
    
    @property
    def reset_url_base(self) -> str:
        """Get the base URL for password reset links."""
        return f"{self.app_base_url.rstrip('/')}{self.reset_redirect_path}"
    
    @property
    def is_production(self) -> bool:
        """Check if running in production environment."""
        return self.environment.lower() == "production"


# Global settings instance
settings = Settings()