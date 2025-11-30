# app/routers/iap.py - ProStack IAP Verification

import os
import json
import secrets
from datetime import datetime
from fastapi import APIRouter, HTTPException, Depends, Header
from pydantic import BaseModel
from sqlmodel import Session, select
from typing import Optional
from google.oauth2 import service_account
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError

from ..db import get_session
from ..models import License

router = APIRouter(prefix="/api/v1/subscriptions", tags=["subscriptions"])

# ProStack API Key from environment
PROSTACK_API_KEY = os.getenv("PROSTACK_API_KEY", "change-me-in-production")


class PurchaseVerificationRequest(BaseModel):
    product_id: str
    purchase_token: str
    platform: str  # 'android' or 'ios'


class PurchaseVerificationResponse(BaseModel):
    success: bool
    is_valid: bool
    subscription_tier: Optional[str] = None
    expiry_date: Optional[str] = None
    message: str


def verify_google_play_purchase(product_id: str, purchase_token: str) -> dict:
    """
    Verify Google Play purchase receipt with Google's servers
    """
    try:
        # Load service account credentials from environment variable
        service_account_json = os.getenv('GOOGLE_SERVICE_ACCOUNT_JSON')
        
        if not service_account_json:
            raise Exception("GOOGLE_SERVICE_ACCOUNT_JSON environment variable not set")
        
        print("📱 Loading Google service account from environment")
        
        # Parse JSON and create credentials
        credentials_dict = json.loads(service_account_json)
        credentials = service_account.Credentials.from_service_account_info(
            credentials_dict,
            scopes=['https://www.googleapis.com/auth/androidpublisher']
        )
        
        # Build the API client
        service = build('androidpublisher', 'v3', credentials=credentials)
        print("✅ Google Play API client initialized")
        
        # ProStack package name from Google Play Console
        package_name = "com.fourdgamimg.prostack"
        
        print(f"🔍 Verifying subscription: {product_id}")
        print(f"📝 Token: {purchase_token[:20]}...")
        
        # Verify subscription with Google
        result = service.purchases().subscriptions().get(
            packageName=package_name,
            subscriptionId=product_id,
            token=purchase_token
        ).execute()
        
        print(f"✅ Google Play verification successful!")
        print(f"   Order ID: {result.get('orderId')}")
        print(f"   Payment State: {result.get('paymentState')}")
        print(f"   Auto-Renewing: {result.get('autoRenewing')}")
        
        # Check expiry
        expiry_ms = int(result.get('expiryTimeMillis', 0))
        expiry_date = datetime.fromtimestamp(expiry_ms / 1000) if expiry_ms else None
        
        if expiry_date:
            is_active = expiry_date > datetime.utcnow()
            print(f"   Expires: {expiry_date}")
            print(f"   Active: {is_active}")
        else:
            is_active = False
        
        # Acknowledge the purchase (required by Google within 3 days)
        try:
            service.purchases().subscriptions().acknowledge(
                packageName=package_name,
                subscriptionId=product_id,
                token=purchase_token,
                body={}
            ).execute()
            print("✅ Subscription acknowledged")
        except HttpError as e:
            if e.resp.status == 400:
                print("ℹ️ Subscription already acknowledged")
            else:
                print(f"⚠️ Acknowledgment warning: {e}")
        
        return {
            "valid": True,
            "is_active": is_active,
            "expiry_date": expiry_date.isoformat() if expiry_date else None,
            "order_id": result.get('orderId'),
            "payment_state": result.get('paymentState'),
            "auto_renewing": result.get('autoRenewing', False)
        }
        
    except HttpError as e:
        error_content = json.loads(e.content.decode('utf-8'))
        error_msg = error_content.get('error', {}).get('message', str(e))
        print(f"❌ Google Play API error: {error_msg}")
        
        if e.resp.status == 410:
            return {"valid": False, "error": "Subscription has been canceled or refunded"}
        elif e.resp.status == 404:
            return {"valid": False, "error": "Purchase not found"}
        else:
            return {"valid": False, "error": f"Verification failed: {error_msg}"}
    
    except Exception as e:
        print(f"❌ Verification error: {e}")
        return {"valid": False, "error": str(e)}


@router.post("/verify", response_model=PurchaseVerificationResponse)
async def verify_purchase(
    request: PurchaseVerificationRequest,
    db: Session = Depends(get_session),
    api_key: str = Header(..., alias="X-API-Key")
):
    """
    Verify in-app purchase and update license in database
    """
    print(f"\n{'='*60}")
    print(f"🔍 IAP VERIFICATION REQUEST")
    print(f"{'='*60}")
    print(f"Platform: {request.platform}")
    print(f"Product ID: {request.product_id}")
    print(f"Token length: {len(request.purchase_token)} bytes")
    
    # Verify API key
    if api_key != PROSTACK_API_KEY:
        raise HTTPException(status_code=401, detail="Invalid API key")
    
    # Map product IDs to tiers
    tier_mapping = {
        'prostack_premium': 'premium',
        'prostack_premium_yearly': 'premium',
        'prostack_business': 'business',
        'prostack_business_yearly': 'business',
    }
    
    tier = tier_mapping.get(request.product_id)
    
    if not tier:
        return PurchaseVerificationResponse(
            success=False,
            is_valid=False,
            message="Invalid product ID"
        )
    
    # Verify with Google Play
    if request.platform == "android":
        print(f"\n📱 Verifying with Google Play...")
        
        verification = verify_google_play_purchase(
            product_id=request.product_id,
            purchase_token=request.purchase_token
        )
        
        if not verification.get("valid"):
            return PurchaseVerificationResponse(
                success=True,
                is_valid=False,
                message=verification.get("error", "Purchase verification failed")
            )
        
        is_active = verification.get("is_active", False)
        expiry_date_str = verification.get("expiry_date")
        expiry_date = datetime.fromisoformat(expiry_date_str.replace('Z', '+00:00')) if expiry_date_str else None
        
        print(f"✅ Verified! Active: {is_active}")
        
        # Find or create license by purchase token
        existing_license = db.exec(
            select(License).where(License.iap_purchase_token == request.purchase_token)
        ).first()
        
        if existing_license:
            print(f"📝 Updating existing license")
            existing_license.tier = tier
            existing_license.is_active = is_active
            existing_license.expires_at = expiry_date
            existing_license.iap_product_id = request.product_id
            existing_license.updated_at = datetime.utcnow()
            license_key = existing_license.license_key
        else:
            print(f"🆕 Creating new license")
            license_key = f"lic_{secrets.token_urlsafe(32)}"
            
            new_license = License(
                license_key=license_key,
                tier=tier,
                is_active=is_active,
                iap_purchase_token=request.purchase_token,
                iap_store="google_play",
                iap_product_id=request.product_id,
                activated_at=datetime.utcnow(),
                expires_at=expiry_date
            )
            db.add(new_license)
        
        db.commit()
        
        print(f"\n{'='*60}")
        print(f"✅ IAP VERIFICATION COMPLETE")
        print(f"{'='*60}")
        print(f"License Key: {license_key[:20]}...")
        print(f"Tier: {tier}")
        print(f"Active: {is_active}")
        print(f"Expires: {expiry_date}")
        print(f"{'='*60}\n")
        
        return PurchaseVerificationResponse(
            success=True,
            is_valid=is_active,
            subscription_tier=tier,
            expiry_date=expiry_date_str,
            message="Purchase verified successfully"
        )
    
    elif request.platform == "ios":
        return PurchaseVerificationResponse(
            success=False,
            is_valid=False,
            message="iOS verification not yet implemented"
        )
    
    else:
        return PurchaseVerificationResponse(
            success=False,
            is_valid=False,
            message="Invalid platform"
        )


@router.get("/check/{license_key}")
async def check_license(
    license_key: str,
    db: Session = Depends(get_session)
):
    """
    Check license status (for app to verify subscription)
    """
    license = db.exec(
        select(License).where(License.license_key == license_key)
    ).first()
    
    if not license:
        return {
            "valid": False,
            "tier": "free",
            "message": "License not found"
        }
    
    # Check if expired
    if license.expires_at and license.expires_at < datetime.utcnow():
        return {
            "valid": False,
            "tier": "free",
            "expired": True,
            "message": "Subscription expired"
        }
    
    return {
        "valid": license.is_active,
        "tier": license.tier,
        "expires_at": license.expires_at.isoformat() if license.expires_at else None,
        "message": "License active"
    }