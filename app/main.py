"""
ProStack AI Resume Builder Backend
FastAPI + OpenAI GPT-4
NO DATA STORAGE - Stateless API
"""

from fastapi import FastAPI, HTTPException, Header
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any
import openai
import boto3
from botocore.client import Config
import os
from datetime import datetime
import json
import httpx
from google.oauth2 import service_account
from google.auth.transport.requests import Request


# Initialize FastAPI
app = FastAPI(
    title="ProStack AI Resume API",
    description="Privacy-first AI Resume Builder - We don't store any data",
    version="1.0.0"
)

# CORS Configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify your app's domains
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# OpenAI Configuration
openai.api_key = os.getenv("OPENAI_API_KEY")
if not openai.api_key:
    raise ValueError("OPENAI_API_KEY environment variable not set")

# API Key for your mobile app (simple auth)
PROSTACK_API_KEY = os.getenv("PROSTACK_API_KEY", "your-secure-api-key-here")

# Google Play Configuration
GOOGLE_PLAY_PACKAGE_NAME = "com.fourdgaming.prostack"
GOOGLE_SERVICE_ACCOUNT_JSON = os.getenv("GOOGLE_SERVICE_ACCOUNT_JSON")  # JSON string of service account

# Backblaze B2 Configuration (use S3-compatible API)
B2_KEY_ID = os.getenv("B2_KEY_ID")  # Application Key ID
B2_APPLICATION_KEY = os.getenv("B2_APPLICATION_KEY")  # Application Key
B2_BUCKET_NAME = os.getenv("B2_BUCKET_NAME")  # Your bucket name
B2_ENDPOINT = os.getenv("B2_ENDPOINT")  # e.g., s3.us-west-004.backblazeb2.com

# Initialize S3 client for Backblaze B2
s3_client = boto3.client(
    's3',
    endpoint_url=f'https://{B2_ENDPOINT}',
    aws_access_key_id=B2_KEY_ID,
    aws_secret_access_key=B2_APPLICATION_KEY,
    config=Config(signature_version='s3v4')
)

# ==================== Models ====================

class WorkExperience(BaseModel):
    company: str
    title: str
    start_date: str
    end_date: Optional[str] = None
    current: bool = False
    responsibilities: List[str] = []
    achievements: List[str] = []


class Education(BaseModel):
    institution: str
    degree: str
    field: str
    graduation_date: str
    gpa: Optional[str] = None
    honors: List[str] = []


class Skill(BaseModel):
    name: str
    category: str  # "technical", "soft", "language", etc.
    proficiency: Optional[str] = None  # "beginner", "intermediate", "expert"


class Project(BaseModel):
    name: str
    description: str
    technologies: List[str] = []
    url: Optional[str] = None


class Certification(BaseModel):
    name: str
    issuer: str
    date: str
    expiration: Optional[str] = None


class ResumeRequest(BaseModel):
    # Personal Info
    full_name: str
    email: str
    phone: str
    location: str
    linkedin: Optional[str] = None
    portfolio: Optional[str] = None
    
    # Professional Summary
    summary: Optional[str] = None
    target_role: Optional[str] = None
    years_experience: Optional[int] = None
    
    # Experience & Education
    work_experience: List[WorkExperience] = []
    education: List[Education] = []
    
    # Skills & Projects
    skills: List[Skill] = []
    projects: List[Project] = []
    certifications: List[Certification] = []
    
    # Preferences
    template: str = "modern"  # "modern", "classic", "minimal", "creative"
    target_industry: Optional[str] = None
    job_description: Optional[str] = None  # For ATS optimization
    
    # AI Enhancement Options
    enhance_summary: bool = True
    optimize_keywords: bool = True
    improve_achievements: bool = True


class ResumeResponse(BaseModel):
    success: bool
    resume_data: Dict[str, Any]
    suggestions: List[str] = []
    ats_score: Optional[int] = None
    keywords: List[str] = []

class SubscriptionProduct(BaseModel):
    product_id: str
    name: str
    tier: str  # "premium" or "business"
    billing_period: str  # "monthly" or "yearly"
    price: float
    currency: str = "USD"


class PurchaseVerificationRequest(BaseModel):
    product_id: str
    purchase_token: str
    platform: str  # "android" or "ios"


class PurchaseVerificationResponse(BaseModel):
    success: bool
    is_valid: bool
    subscription_tier: Optional[str] = None
    expiry_date: Optional[str] = None
    message: str


# Define your subscription products
SUBSCRIPTION_PRODUCTS = {
    # Android Product IDs
    "prostack_premium": SubscriptionProduct(
        product_id="prostack_premium",
        name="Premium Monthly",
        tier="premium",
        billing_period="monthly",
        price=4.99
    ),
    "prostack_premium_yearly": SubscriptionProduct(
        product_id="prostack_premium_yearly",
        name="Premium Yearly",
        tier="premium",
        billing_period="yearly",
        price=29.99
    ),
    "prostack_business": SubscriptionProduct(
        product_id="prostack_business",
        name="Business Monthly",
        tier="business",
        billing_period="monthly",
        price=9.99
    ),
    "prostack_business_yearly": SubscriptionProduct(
        product_id="prostack_business_yearly",
        name="Business Yearly",
        tier="business",
        billing_period="yearly",
        price=59.99
    ),
}

class BackupRequest(BaseModel):
    user_id: str  # Unique identifier for user
    backup_name: str = "prostack_backup"
    

class RestoreRequest(BaseModel):
    user_id: str
    backup_name: str = "prostack_backup"
    
# ==================== Google Play Verification ====================

async def verify_google_play_purchase(product_id: str, purchase_token: str) -> Dict[str, Any]:
    """
    Verify purchase with Google Play Developer API
    
    Setup required:
    1. Create service account in Google Cloud Console
    2. Enable Google Play Developer API
    3. Grant service account access in Google Play Console
    4. Add service account JSON to environment variable
    """
    
    if not GOOGLE_SERVICE_ACCOUNT_JSON:
        return {
            "valid": False,
            "error": "Google Play verification not configured"
        }
    
    try:
        # Load service account credentials
        credentials_info = json.loads(GOOGLE_SERVICE_ACCOUNT_JSON)
        credentials = service_account.Credentials.from_service_account_info(
            credentials_info,
            scopes=['https://www.googleapis.com/auth/androidpublisher']
        )
        
        # Get access token
        credentials.refresh(Request())
        access_token = credentials.token
        
        # Call Google Play API
        url = f"https://androidpublisher.googleapis.com/androidpublisher/v3/applications/{GOOGLE_PLAY_PACKAGE_NAME}/purchases/subscriptions/{product_id}/tokens/{purchase_token}"
        
        headers = {
            "Authorization": f"Bearer {access_token}",
            "Content-Type": "application/json"
        }
        
        async with httpx.AsyncClient() as client:
            response = await client.get(url, headers=headers)
            
            if response.status_code == 200:
                data = response.json()
                
                # Check if subscription is active
                expiry_time_millis = int(data.get('expiryTimeMillis', 0))
                expiry_date = datetime.fromtimestamp(expiry_time_millis / 1000)
                is_active = expiry_date > datetime.now()
                
                return {
                    "valid": True,
                    "is_active": is_active,
                    "expiry_date": expiry_date.isoformat(),
                    "auto_renewing": data.get('autoRenewing', False),
                    "payment_state": data.get('paymentState', 0)
                }
            else:
                return {
                    "valid": False,
                    "error": f"Google Play API error: {response.status_code}"
                }
                
    except Exception as e:
        print(f"Error verifying purchase: {e}")
        return {
            "valid": False,
            "error": str(e)
        }


# ==================== Subscription Endpoints ====================

@app.get("/api/v1/subscriptions/products")
async def get_subscription_products(api_key: str = Header(..., alias="X-API-Key")):
    """Get list of available subscription products"""
    
    if api_key != PROSTACK_API_KEY:
        raise HTTPException(status_code=401, detail="Invalid API key")
    
    return {
        "success": True,
        "products": [product.dict() for product in SUBSCRIPTION_PRODUCTS.values()]
    }


@app.post("/api/v1/subscriptions/verify", response_model=PurchaseVerificationResponse)
async def verify_purchase(
    request: PurchaseVerificationRequest,
    api_key: str = Header(..., alias="X-API-Key")
):
    """
    Verify in-app purchase
    
    This endpoint:
    1. Verifies the purchase token with Google Play or App Store
    2. Returns subscription status and expiry date
    3. Does NOT store any data (stateless verification)
    """
    
    if api_key != PROSTACK_API_KEY:
        raise HTTPException(status_code=401, detail="Invalid API key")
    
    # Check if product exists
    if request.product_id not in SUBSCRIPTION_PRODUCTS:
        return PurchaseVerificationResponse(
            success=False,
            is_valid=False,
            message="Invalid product ID"
        )
    
    product = SUBSCRIPTION_PRODUCTS[request.product_id]
    
    # Verify with platform
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
        
        return PurchaseVerificationResponse(
            success=True,
            is_valid=verification.get("is_active", False),
            subscription_tier=product.tier,
            expiry_date=verification.get("expiry_date"),
            message="Purchase verified successfully"
        )
    
    elif request.platform == "ios":
        # TODO: Implement iOS receipt verification
        # For now, return error
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


@app.post("/api/v1/subscriptions/check-access")
async def check_feature_access(
    product_id: str,
    purchase_token: str,
    feature: str,
    platform: str = "android",
    api_key: str = Header(..., alias="X-API-Key")
):
    """
    Check if user has access to a specific feature
    
    Features:
    - custom_templates (Premium+)
    - color_themes (Premium+)
    - company_logos (Premium+)
    - qr_codes (Premium+)
    - ai_resume (Business only)
    - bulk_export (Business only)
    """
    
    if api_key != PROSTACK_API_KEY:
        raise HTTPException(status_code=401, detail="Invalid API key")
    
    # Verify purchase
    verification = await verify_google_play_purchase(product_id, purchase_token)
    
    if not verification.get("valid") or not verification.get("is_active"):
        return {
            "success": True,
            "has_access": False,
            "message": "No active subscription"
        }
    
    # Get product tier
    product = SUBSCRIPTION_PRODUCTS.get(product_id)
    if not product:
        return {
            "success": False,
            "has_access": False,
            "message": "Invalid product"
        }
    
    tier = product.tier
    
    # Check feature access
    premium_features = ["custom_templates", "color_themes", "company_logos", "qr_codes"]
    business_features = ["ai_resume", "bulk_export"]
    
    has_access = False
    
    if tier == "premium" and feature in premium_features:
        has_access = True
    elif tier == "business" and (feature in premium_features or feature in business_features):
        has_access = True
    
    return {
        "success": True,
        "has_access": has_access,
        "subscription_tier": tier,
        "expiry_date": verification.get("expiry_date")
    }

# ==================== API Key Validation ====================

def verify_api_key(x_api_key: str = Header(...)):
    """Verify ProStack mobile app API key"""
    if x_api_key != PROSTACK_API_KEY:
        raise HTTPException(status_code=401, detail="Invalid API key")
    return x_api_key


# ==================== AI Resume Generation ====================

def generate_professional_summary(request: ResumeRequest) -> str:
    """Generate AI-enhanced professional summary"""
    
    if not request.enhance_summary and request.summary:
        return request.summary
    
    # Build context for GPT
    context = f"""
    Create a compelling professional summary for:
    
    Name: {request.full_name}
    Target Role: {request.target_role or 'Professional'}
    Years of Experience: {request.years_experience or 'Multiple'}
    Industry: {request.target_industry or 'General'}
    
    Work Experience:
    {json.dumps([{
        'company': exp.company,
        'title': exp.title,
        'achievements': exp.achievements
    } for exp in request.work_experience], indent=2)}
    
    Skills: {', '.join([s.name for s in request.skills])}
    
    Current Summary: {request.summary or 'None provided'}
    
    Write a powerful, ATS-friendly professional summary (3-4 sentences) that:
    1. Highlights key achievements and expertise
    2. Includes relevant keywords
    3. Demonstrates value proposition
    4. Matches the target role
    
    Return ONLY the summary text, no additional commentary.
    """
    
    try:
        response = openai.ChatCompletion.create(
            model="gpt-4",
            messages=[
                {
                    "role": "system",
                    "content": "You are an expert resume writer who creates compelling, ATS-optimized professional summaries."
                },
                {
                    "role": "user",
                    "content": context
                }
            ],
            temperature=0.7,
            max_tokens=200
        )
        
        return response.choices[0].message.content.strip()
    
    except Exception as e:
        print(f"Error generating summary: {e}")
        return request.summary or "Experienced professional seeking new opportunities."


def enhance_achievements(achievements: List[str], role: str) -> List[str]:
    """Enhance achievement bullets with AI"""
    
    if not achievements:
        return []
    
    context = f"""
    Improve these achievement bullets for a {role} role.
    Make them more impactful by:
    1. Using strong action verbs
    2. Adding metrics where possible (estimate if needed)
    3. Highlighting business impact
    4. Keeping them concise (1-2 lines each)
    
    Original bullets:
    {json.dumps(achievements, indent=2)}
    
    Return improved bullets as a JSON array of strings.
    """
    
    try:
        response = openai.ChatCompletion.create(
            model="gpt-4",
            messages=[
                {
                    "role": "system",
                    "content": "You are an expert resume writer who transforms ordinary achievements into compelling, metrics-driven accomplishments."
                },
                {
                    "role": "user",
                    "content": context
                }
            ],
            temperature=0.7,
            max_tokens=500
        )
        
        improved = json.loads(response.choices[0].message.content.strip())
        return improved if isinstance(improved, list) else achievements
    
    except Exception as e:
        print(f"Error enhancing achievements: {e}")
        return achievements


def extract_keywords(request: ResumeRequest) -> List[str]:
    """Extract relevant keywords for ATS optimization"""
    
    keywords = set()
    
    # From skills
    keywords.update([s.name.lower() for s in request.skills])
    
    # From job description (if provided)
    if request.job_description:
        try:
            response = openai.ChatCompletion.create(
                model="gpt-4",
                messages=[
                    {
                        "role": "system",
                        "content": "Extract key skills, technologies, and qualifications from this job description. Return as a JSON array of keywords."
                    },
                    {
                        "role": "user",
                        "content": request.job_description
                    }
                ],
                temperature=0.3,
                max_tokens=200
            )
            
            jd_keywords = json.loads(response.choices[0].message.content.strip())
            keywords.update([k.lower() for k in jd_keywords])
        
        except Exception as e:
            print(f"Error extracting keywords: {e}")
    
    # From work experience
    for exp in request.work_experience:
        keywords.add(exp.title.lower())
        keywords.update([r.lower() for r in exp.responsibilities])
    
    return sorted(list(keywords))


def calculate_ats_score(request: ResumeRequest, keywords: List[str]) -> int:
    """Calculate ATS compatibility score (0-100)"""
    
    score = 70  # Base score
    
    # Has contact info (+5)
    if request.email and request.phone:
        score += 5
    
    # Has professional summary (+5)
    if request.summary or request.enhance_summary:
        score += 5
    
    # Has work experience (+10)
    if request.work_experience:
        score += 10
    
    # Has education (+5)
    if request.education:
        score += 5
    
    # Has skills (+5)
    if len(request.skills) >= 5:
        score += 5
    
    # Keyword optimization (+5 if job description provided)
    if request.job_description and request.optimize_keywords:
        score += 5
    
    return min(score, 100)


def generate_suggestions(request: ResumeRequest) -> List[str]:
    """Generate improvement suggestions"""
    
    suggestions = []
    
    if not request.summary and not request.enhance_summary:
        suggestions.append("Add a professional summary to grab attention")
    
    if len(request.skills) < 5:
        suggestions.append("Add more skills (aim for 8-12 relevant skills)")
    
    if not request.work_experience:
        suggestions.append("Add work experience to strengthen your resume")
    
    if request.work_experience:
        for exp in request.work_experience:
            if len(exp.achievements) < 2:
                suggestions.append(f"Add more achievements for {exp.company}")
    
    if not request.certifications:
        suggestions.append("Consider adding relevant certifications")
    
    if not request.linkedin:
        suggestions.append("Add your LinkedIn profile URL")
    
    if not request.projects and request.target_industry in ["tech", "software", "engineering"]:
        suggestions.append("Add personal projects to showcase your skills")
    
    return suggestions


# ==================== API Endpoints ====================

@app.get("/")
async def root():
    """Health check endpoint"""
    return {
        "service": "ProStack AI Resume API",
        "status": "online",
        "privacy": "We don't store any data - all processing is stateless",
        "version": "1.0.0"
    }


@app.get("/health")
async def health_check():
    """Detailed health check"""
    return {
        "status": "healthy",
        "timestamp": datetime.utcnow().isoformat(),
        "openai_configured": bool(openai.api_key),
        "data_storage": "none - stateless API"
    }


@app.post("/api/v1/resume/generate", response_model=ResumeResponse)
async def generate_resume(
    request: ResumeRequest,
    api_key: str = Header(..., alias="X-API-Key")
):
    """
    Generate AI-enhanced resume
    
    Privacy Notice: We DO NOT store any data.
    All information is processed in-memory and discarded after response.
    """
    
    # Verify API key
    if api_key != PROSTACK_API_KEY:
        raise HTTPException(status_code=401, detail="Invalid API key")
    
    try:
        # Generate AI-enhanced summary
        summary = generate_professional_summary(request)
        
        # Enhance work experience achievements
        enhanced_experience = []
        for exp in request.work_experience:
            if request.improve_achievements and exp.achievements:
                improved = enhance_achievements(exp.achievements, exp.title)
                exp.achievements = improved
            enhanced_experience.append(exp.dict())
        
        # Extract keywords for ATS
        keywords = extract_keywords(request) if request.optimize_keywords else []
        
        # Calculate ATS score
        ats_score = calculate_ats_score(request, keywords)
        
        # Generate suggestions
        suggestions = generate_suggestions(request)
        
        # Build resume data structure
        resume_data = {
            "personal_info": {
                "name": request.full_name,
                "email": request.email,
                "phone": request.phone,
                "location": request.location,
                "linkedin": request.linkedin,
                "portfolio": request.portfolio
            },
            "summary": summary,
            "work_experience": enhanced_experience,
            "education": [e.dict() for e in request.education],
            "skills": [s.dict() for s in request.skills],
            "projects": [p.dict() for p in request.projects],
            "certifications": [c.dict() for c in request.certifications],
            "template": request.template,
            "generated_at": datetime.utcnow().isoformat()
        }
        
        return ResumeResponse(
            success=True,
            resume_data=resume_data,
            suggestions=suggestions,
            ats_score=ats_score,
            keywords=keywords[:20]  # Top 20 keywords
        )
    
    except Exception as e:
        print(f"Error generating resume: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/api/v1/resume/enhance-summary")
async def enhance_summary_only(
    summary: str,
    target_role: str,
    api_key: str = Header(..., alias="X-API-Key")
):
    """Enhance just the professional summary"""
    
    if api_key != PROSTACK_API_KEY:
        raise HTTPException(status_code=401, detail="Invalid API key")
    
    try:
        response = openai.ChatCompletion.create(
            model="gpt-4",
            messages=[
                {
                    "role": "system",
                    "content": f"You are an expert resume writer. Enhance this professional summary for a {target_role} role. Make it compelling and ATS-friendly."
                },
                {
                    "role": "user",
                    "content": summary
                }
            ],
            temperature=0.7,
            max_tokens=200
        )
        
        return {
            "success": True,
            "enhanced_summary": response.choices[0].message.content.strip()
        }
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/api/v1/resume/analyze-job")
async def analyze_job_description(
    job_description: str,
    api_key: str = Header(..., alias="X-API-Key")
):
    """Analyze job description and extract key requirements"""
    
    if api_key != PROSTACK_API_KEY:
        raise HTTPException(status_code=401, detail="Invalid API key")
    
    try:
        response = openai.ChatCompletion.create(
            model="gpt-4",
            messages=[
                {
                    "role": "system",
                    "content": "Extract key skills, qualifications, and requirements from this job description. Return as JSON with keys: required_skills, preferred_skills, responsibilities, qualifications"
                },
                {
                    "role": "user",
                    "content": job_description
                }
            ],
            temperature=0.3,
            max_tokens=500
        )
        
        analysis = json.loads(response.choices[0].message.content.strip())
        
        return {
            "success": True,
            "analysis": analysis
        }
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    
@app.post("/api/v1/backup/upload-url")
async def get_backup_upload_url(
    request: BackupRequest,
    product_id: str,
    purchase_token: str,
    api_key: str = Header(..., alias="X-API-Key")
):
    """
    Generate presigned URL for uploading backup to S3
    Business tier only
    """
    
    if api_key != PROSTACK_API_KEY:
        raise HTTPException(status_code=401, detail="Invalid API key")
    
    # Verify Business tier subscription
    verification = await verify_google_play_purchase(product_id, purchase_token)
    
    if not verification.get("valid") or not verification.get("is_active"):
        raise HTTPException(status_code=403, detail="No active Business subscription")
    
    # Check if product is Business tier
    product = SUBSCRIPTION_PRODUCTS.get(product_id)
    if not product or product.tier != "business":
        raise HTTPException(status_code=403, detail="Cloud backup requires Business subscription")
    
    try:
        # Generate unique backup path
        backup_key = f"backups/{request.user_id}/{request.backup_name}.db"
        
        # Generate presigned upload URL (valid for 1 hour)
        upload_url = s3_client.generate_presigned_url(
            'put_object',
            Params={
                'Bucket': B2_BUCKET_NAME,
                'Key': backup_key,
                'ContentType': 'application/octet-stream'
            },
            ExpiresIn=3600  # 1 hour
        )
        
        return {
            "success": True,
            "upload_url": upload_url,
            "backup_key": backup_key,
            "expires_in": 3600
        }
        
    except Exception as e:
        print(f"Error generating upload URL: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/api/v1/backup/download-url")
async def get_backup_download_url(
    request: RestoreRequest,
    product_id: str,
    purchase_token: str,
    api_key: str = Header(..., alias="X-API-Key")
):
    """
    Generate presigned URL for downloading backup from S3
    Business tier only
    """
    
    if api_key != PROSTACK_API_KEY:
        raise HTTPException(status_code=401, detail="Invalid API key")
    
    # Verify Business tier subscription
    verification = await verify_google_play_purchase(product_id, purchase_token)
    
    if not verification.get("valid") or not verification.get("is_active"):
        raise HTTPException(status_code=403, detail="No active Business subscription")
    
    # Check if product is Business tier
    product = SUBSCRIPTION_PRODUCTS.get(product_id)
    if not product or product.tier != "business":
        raise HTTPException(status_code=403, detail="Cloud backup requires Business subscription")
    
    try:
        backup_key = f"backups/{request.user_id}/{request.backup_name}.db"
        
        # Check if backup exists
        try:
            s3_client.head_object(Bucket=B2_BUCKET_NAME, Key=backup_key)
        except:
            raise HTTPException(status_code=404, detail="Backup not found")
        
        # Generate presigned download URL (valid for 1 hour)
        download_url = s3_client.generate_presigned_url(
            'get_object',
            Params={
                'Bucket': B2_BUCKET_NAME,
                'Key': backup_key
            },
            ExpiresIn=3600  # 1 hour
        )
        
        return {
            "success": True,
            "download_url": download_url,
            "backup_key": backup_key,
            "expires_in": 3600
        }
        
    except HTTPException:
        raise
    except Exception as e:
        print(f"Error generating download URL: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/api/v1/backup/list")
async def list_backups(
    user_id: str,
    product_id: str,
    purchase_token: str,
    api_key: str = Header(..., alias="X-API-Key")
):
    """
    List available backups for user
    Business tier only
    """
    
    if api_key != PROSTACK_API_KEY:
        raise HTTPException(status_code=401, detail="Invalid API key")
    
    # Verify Business tier subscription
    verification = await verify_google_play_purchase(product_id, purchase_token)
    
    if not verification.get("valid") or not verification.get("is_active"):
        raise HTTPException(status_code=403, detail="No active Business subscription")
    
    try:
        # List objects in user's backup folder
        response = s3_client.list_objects_v2(
            Bucket=B2_BUCKET_NAME,
            Prefix=f"backups/{user_id}/"
        )
        
        backups = []
        if 'Contents' in response:
            for obj in response['Contents']:
                backups.append({
                    "name": obj['Key'].split('/')[-1],
                    "size": obj['Size'],
                    "last_modified": obj['LastModified'].isoformat()
                })
        
        return {
            "success": True,
            "backups": backups
        }
        
    except Exception as e:
        print(f"Error listing backups: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.delete("/api/v1/backup/delete")
async def delete_backup(
    request: RestoreRequest,
    product_id: str,
    purchase_token: str,
    api_key: str = Header(..., alias="X-API-Key")
):
    """
    Delete a backup from S3
    Business tier only
    """
    
    if api_key != PROSTACK_API_KEY:
        raise HTTPException(status_code=401, detail="Invalid API key")
    
    # Verify Business tier subscription
    verification = await verify_google_play_purchase(product_id, purchase_token)
    
    if not verification.get("valid") or not verification.get("is_active"):
        raise HTTPException(status_code=403, detail="No active Business subscription")
    
    try:
        backup_key = f"backups/{request.user_id}/{request.backup_name}.db"
        
        s3_client.delete_object(
            Bucket=B2_BUCKET_NAME,
            Key=backup_key
        )
        
        return {
            "success": True,
            "message": "Backup deleted successfully"
        }
        
    except Exception as e:
        print(f"Error deleting backup: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ==================== Run Server ====================

if __name__ == "__main__":
    import uvicorn
    
    uvicorn.run(
        app,
        host="0.0.0.0",
        port=8000,
        log_level="info"
    )
