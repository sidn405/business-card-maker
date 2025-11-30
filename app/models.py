from sqlmodel import SQLModel, Field
from datetime import datetime
from typing import Optional

class License(SQLModel, table=True):
    __tablename__ = "licenses"
    
    id: Optional[int] = Field(default=None, primary_key=True)
    license_key: str = Field(unique=True, index=True)
    tier: str = Field(default="free")  # free, premium, business
    device_id: Optional[str] = Field(default=None, index=True)
    email: Optional[str] = Field(default=None)
    is_active: bool = Field(default=True)
    
    # IAP fields
    iap_purchase_token: Optional[str] = Field(default=None)
    iap_store: Optional[str] = Field(default=None)  # google_play, app_store
    iap_product_id: Optional[str] = Field(default=None)
    
    # Timestamps
    activated_at: Optional[datetime] = Field(default=None)
    expires_at: Optional[datetime] = Field(default=None)
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)