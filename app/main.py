"""
ProStack Backend with Database License Management
"""

from fastapi import FastAPI, HTTPException, Header
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional
import os
from datetime import datetime
import psycopg2
from psycopg2.extras import RealDictCursor
import json
import httpx
from google.oauth2 import service_account
from google.auth.transport.requests import Request

# Initialize FastAPI
app = FastAPI(title="ProStack API")

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Configuration
PROSTACK_API_KEY = os.getenv("PROSTACK_API_KEY")
DATABASE_URL = os.getenv("DATABASE_URL")  # Railway provides this automatically
GOOGLE_PLAY_PACKAGE_NAME = "com.fourdgamimg.prostack"
GOOGLE_SERVICE_ACCOUNT_JSON = os.getenv("GOOGLE_SERVICE_ACCOUNT_JSON")

# Database connection
def get_db():
    """Get database connection"""
    conn = psycopg2.connect(DATABASE_URL)
    return conn

# ==================== Models ====================

class PurchaseVerificationRequest(BaseModel):
    product_id: str
    purchase_token: str
    platform: str  # "android" or "ios"
    device_id: Optional[str] = None
    email: Optional[str] = None


class PurchaseVerificationResponse(BaseModel):
    success: bool
    is_valid: bool
    subscription_tier: Optional[str] = None
    expiry_date: Optional[str] = None
    message: str


# ==================== Google Play Verification ====================

async def verify_google_play_purchase(product_id: str, purchase_token: str) -> dict:
    """Verify purchase with Google Play Developer API"""
    
    if not GOOGLE_SERVICE_ACCOUNT_JSON:
        return {"valid": False, "error": "Google Play verification not configured"}
    
    try:
        credentials_info = json.loads(GOOGLE_SERVICE_ACCOUNT_JSON)
        credentials = service_account.Credentials.from_service_account_info(
            credentials_info,
            scopes=['https://www.googleapis.com/auth/androidpublisher']
        )
        
        credentials.refresh(Request())
        access_token = credentials.token
        
        url = f"https://androidpublisher.googleapis.com/androidpublisher/v3/applications/{GOOGLE_PLAY_PACKAGE_NAME}/purchases/subscriptions/{product_id}/tokens/{purchase_token}"
        
        headers = {
            "Authorization": f"Bearer {access_token}",
            "Content-Type": "application/json"
        }
        
        async with httpx.AsyncClient() as client:
            response = await client.get(url, headers=headers)
            
            if response.status_code == 200:
                data = response.json()
                expiry_time_millis = int(data.get('expiryTimeMillis', 0))
                expiry_date = datetime.fromtimestamp(expiry_time_millis / 1000)
                is_active = expiry_date > datetime.now()
                
                return {
                    "valid": True,
                    "is_active": is_active,
                    "expiry_date": expiry_date.isoformat(),
                    "auto_renewing": data.get('autoRenewing', False)
                }
            else:
                return {"valid": False, "error": f"Google Play API error: {response.status_code}"}
                
    except Exception as e:
        print(f"Error verifying purchase: {e}")
        return {"valid": False, "error": str(e)}


# ==================== Database Functions ====================

def get_or_create_license(device_id: str, email: Optional[str] = None):
    """Get existing license or create new free tier"""
    conn = get_db()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    
    try:
        # Try to find existing license
        cur.execute(
            "SELECT * FROM license WHERE device_id = %s",
            (device_id,)
        )
        license_row = cur.fetchone()
        
        if license_row:
            return dict(license_row)
        
        # Create new free tier license
        cur.execute(
            """
            INSERT INTO license (device_id, email, tier, is_active)
            VALUES (%s, %s, 'free', true)
            RETURNING *
            """,
            (device_id, email)
        )
        license_row = cur.fetchone()
        conn.commit()
        
        return dict(license_row)
        
    finally:
        cur.close()
        conn.close()


def update_license_from_purchase(
    device_id: str,
    product_id: str,
    purchase_token: str,
    tier: str,
    expiry_date: str,
    email: Optional[str] = None
):
    """Update license with verified purchase"""
    conn = get_db()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    
    try:
        cur.execute(
            """
            INSERT INTO license (device_id, email, tier, iap_purchase_token, expiry_date, is_active, last_verified)
            VALUES (%s, %s, %s, %s, %s, true, NOW())
            ON CONFLICT (device_id) 
            DO UPDATE SET
                tier = EXCLUDED.tier,
                iap_purchase_token = EXCLUDED.iap_purchase_token,
                expiry_date = EXCLUDED.expiry_date,
                is_active = true,
                last_verified = NOW(),
                email = COALESCE(EXCLUDED.email, license.email)
            RETURNING *
            """,
            (device_id, email, tier, purchase_token, expiry_date)
        )
        license_row = cur.fetchone()
        conn.commit()
        
        return dict(license_row)
        
    finally:
        cur.close()
        conn.close()


def check_license(device_id: str) -> dict:
    """Check license status"""
    conn = get_db()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    
    try:
        cur.execute(
            "SELECT * FROM license WHERE device_id = %s",
            (device_id,)
        )
        license_row = cur.fetchone()
        
        if not license_row:
            return {
                "valid": False,
                "tier": "free",
                "message": "No license found"
            }
        
        license_dict = dict(license_row)
        
        # Check if expired
        if license_dict.get('expiry_date'):
            expiry = license_dict['expiry_date']
            if isinstance(expiry, str):
                expiry = datetime.fromisoformat(expiry)
            
            if expiry < datetime.now():
                # Mark as expired
                cur.execute(
                    "UPDATE license SET is_active = false, tier = 'free' WHERE device_id = %s",
                    (device_id,)
                )
                conn.commit()
                return {
                    "valid": True,
                    "tier": "free",
                    "is_active": False,
                    "message": "Subscription expired"
                }
        
        return {
            "valid": True,
            "tier": license_dict.get('tier', 'free'),
            "is_active": license_dict.get('is_active', False),
            "expiry_date": license_dict.get('expiry_date'),
            "message": "License valid"
        }
        
    finally:
        cur.close()
        conn.close()


# ==================== API Endpoints ====================

@app.get("/")
async def root():
    return {
        "service": "ProStack API",
        "status": "online",
        "database": "connected" if DATABASE_URL else "not configured"
    }


@app.post("/api/v1/subscriptions/verify")
async def verify_purchase(
    request: PurchaseVerificationRequest,
    api_key: str = Header(..., alias="X-API-Key")
):
    """Verify purchase and update license in database"""
    
    if api_key != PROSTACK_API_KEY:
        raise HTTPException(status_code=401, detail="Invalid API key")
    
    # Determine tier from product_id
    tier_map = {
        "prostack_premium": "premium",
        "prostack_premium_yearly": "premium",
        "prostack_business": "business",
        "prostack_business_yearly": "business"
    }
    
    tier = tier_map.get(request.product_id, "free")
    
    # Verify with Google Play
    if request.platform == "android":
        verification = await verify_google_play_purchase(
            request.product_id,
            request.purchase_token
        )
        
        if not verification.get("valid"):
            return PurchaseVerificationResponse(
                success=True,
                is_valid=False,
                message=verification.get("error", "Purchase verification failed")
            )
        
        if not verification.get("is_active"):
            return PurchaseVerificationResponse(
                success=True,
                is_valid=False,
                message="Subscription expired or inactive"
            )
        
        # Update database with verified purchase
        if request.device_id:
            update_license_from_purchase(
                device_id=request.device_id,
                product_id=request.product_id,
                purchase_token=request.purchase_token,
                tier=tier,
                expiry_date=verification.get("expiry_date"),
                email=request.email
            )
        
        return PurchaseVerificationResponse(
            success=True,
            is_valid=True,
            subscription_tier=tier,
            expiry_date=verification.get("expiry_date"),
            message="Purchase verified and license updated"
        )
    
    else:
        return PurchaseVerificationResponse(
            success=False,
            is_valid=False,
            message="iOS verification not yet implemented"
        )


@app.get("/api/v1/license/check")
async def check_license_status(
    device_id: str,
    api_key: str = Header(..., alias="X-API-Key")
):
    """Check license status for a device"""
    
    if api_key != PROSTACK_API_KEY:
        raise HTTPException(status_code=401, detail="Invalid API key")
    
    license_info = check_license(device_id)
    
    return {
        "success": True,
        **license_info
    }


@app.post("/api/v1/license/activate")
async def activate_license(
    device_id: str,
    license_key: str,
    email: Optional[str] = None,
    api_key: str = Header(..., alias="X-API-Key")
):
    """Activate a license key (for promotional licenses)"""
    
    if api_key != PROSTACK_API_KEY:
        raise HTTPException(status_code=401, detail="Invalid API key")
    
    # TODO: Implement license key validation logic
    # For now, just create/update the license
    
    return {
        "success": True,
        "message": "License activated"
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8080)