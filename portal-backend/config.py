"""
Application Configuration
Loads from environment variables
"""

from pydantic_settings import BaseSettings
from functools import lru_cache
from typing import Optional

class Settings(BaseSettings):
    # Application
    APP_NAME: str = "Azure CAF-LZ SaaS Platform"
    APP_VERSION: str = "1.0.0"
    DEBUG: bool = False
    
    # API
    API_V1_PREFIX: str = "/api/v1"
    HOST: str = "0.0.0.0"
    PORT: int = 8000
    
    # Database
    DATABASE_URL: str = "postgresql://user:password@localhost:5432/caflz"
    
    # Security
    SECRET_KEY: str = "CHANGE_ME_IN_PRODUCTION"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    
    # Azure Configuration
    AZURE_TENANT_ID: str
    AZURE_SUBSCRIPTION_ID: str
    AZURE_CLIENT_ID: Optional[str] = None
    AZURE_CLIENT_SECRET: Optional[str] = None
    
    # Terraform State Storage
    TF_STATE_RESOURCE_GROUP: str = "rg-terraform-state"
    TF_STATE_STORAGE_ACCOUNT: str = "sttfstate"
    TF_STATE_CONTAINER: str = "tfstate"
    
    # Terraform Paths
    TF_MODULES_PATH: str = "./terraform/modules"
    TF_ENVIRONMENTS_PATH: str = "./terraform/environments"
    
    # Cost Management
    COST_ANALYSIS_ENABLED: bool = True
    COST_ALERT_THRESHOLD: float = 0.8  # Alert at 80% of budget
    
    # Background Tasks
    CELERY_BROKER_URL: str = "redis://localhost:6379/0"
    CELERY_RESULT_BACKEND: str = "redis://localhost:6379/0"
    
    # Logging
    LOG_LEVEL: str = "INFO"
    SENTRY_DSN: Optional[str] = None
    
    # Email Notifications
    SMTP_HOST: Optional[str] = None
    SMTP_PORT: int = 587
    SMTP_USER: Optional[str] = None
    SMTP_PASSWORD: Optional[str] = None
    FROM_EMAIL: str = "noreply@yourcompany.com"
    
    class Config:
        env_file = ".env"
        case_sensitive = True

@lru_cache()
def get_settings() -> Settings:
    """Cached settings instance"""
    return Settings()

settings = get_settings()