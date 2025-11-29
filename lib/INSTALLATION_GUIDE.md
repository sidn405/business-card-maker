# 🎯 ProStack Rebranding - Installation Guide

## What's Changing

**Old Name:** Business Card Maker  
**New Name:** ProStack  
**New Tagline:** Stack Your Professional Life  

## What's Included

### New Features Shown:
✅ Business Cards (live)  
✅ AI Resume Builder (Pro tier, coming soon)  
✅ Credentials (certificates/degrees, coming soon)  
✅ Portfolio (coming soon)  

### Updated Files:
1. **home_screen.dart** - New ProStack branded home
2. **main.dart** - Updated app name and colors
3. **Subscription tiers** - Renamed to "Stacks"
4. **Marketing materials** - App store descriptions

---

## ⚡ QUICK INSTALLATION (3 Files)

### Step 1: Update Home Screen
Replace `lib/screens/home_screen.dart`  
Source: `home_screen_prostack.dart`

**What changed:**
- App name: "ProStack"
- Tagline: "Stack Your Professional Life"
- Icon: Stacked cards
- Feature buttons for all stacks
- "PRO" and "SOON" badges

### Step 2: Update Main App
Replace `lib/main.dart`  
Source: `main.dart`

**What changed:**
- App title: "ProStack"
- Primary color: Professional blue (#1976D2)
- Theme updates for brand consistency

### Step 3: Update Subscription Screen (Optional)
Update subscription tier names in `subscription_screen.dart`:

```dart
// Change tier names:
'Free' → 'Free Stack'
'Premium' → 'Pro Stack'
'Pro' → 'Business Stack'
```

---

## 🎨 Brand Colors

```dart
Primary: Color(0xFF1976D2)  // Professional Blue
Gradient Start: Color(0xFF1976D2)
Gradient Mid: Color(0xFF1565C0)
Gradient End: Color(0xFF0D47A1)

Accent Colors:
- Business Cards: Blue (#2196F3)
- AI Resume: Purple (#9C27B0)
- Credentials: Green (#4CAF50)
- Portfolio: Orange (#FF9800)
```

---

## 📱 New Home Screen Preview

```
┌─────────────────────────────┐
│  ☰  ProStack             ❓ │
│                             │
│    [Stacked Cards Icon]     │
│                             │
│        ProStack             │
│  Stack Your Professional    │
│          Life               │
│                             │
│  📇 Business Cards          │
│  Scan & manage contacts     │
│                             │
│  📄 AI Resume Builder  PRO  │
│  Create professional resumes│
│                             │
│  🎓 Credentials       SOON  │
│  Certificates & degrees     │
│                             │
│  🎨 Portfolio         SOON  │
│  Showcase your work         │
│                             │
│  [Unlock All Features]      │
└─────────────────────────────┘
```

---

## 📝 pubspec.yaml Updates

Update app name:
```yaml
name: prostack
description: Stack Your Professional Life - Business Cards, AI Resumes, Credentials & More

# Update version
version: 1.0.0+1
```

---

## 🤖 Android Updates

### AndroidManifest.xml
```xml
<application
    android:label="ProStack"
    android:icon="@mipmap/ic_launcher">
```

### strings.xml (android/app/src/main/res/values/strings.xml)
```xml
<resources>
    <string name="app_name">ProStack</string>
</resources>
```

---

## 🍎 iOS Updates

### Info.plist
```xml
<key>CFBundleName</key>
<string>ProStack</string>
<key>CFBundleDisplayName</key>
<string>ProStack</string>
```

---

## 🎯 Feature Badges Explained

### Blue Badge (No Badge)
- Feature is **live and available**
- Example: Business Cards

### Purple "PRO" Badge
- Feature requires **Pro or Business tier**
- Example: AI Resume Builder
- Shows paywall when clicked (free users)

### Gray "SOON" Badge
- Feature **coming soon**
- Example: Credentials, Portfolio
- Shows "Coming Soon" snackbar when clicked

---

## 🔄 Migration Path

### From Current App:
```
1. User has "Business Card Maker"
2. Update to "ProStack" via app store
3. Sees new home screen
4. Existing cards still work ✓
5. New features visible (with badges)
6. Can upgrade to unlock AI Resume
```

### Data Migration:
- ✅ All existing cards preserved
- ✅ Subscription status maintained
- ✅ No data loss
- ✅ Seamless transition

---

## 🎨 Logo Recommendations

### App Icon:
```
Design: Three stacked cards in perspective
Colors: Blue gradient
Style: Modern, clean, professional

Card 1 (top): #2196F3
Card 2 (middle): #1976D2
Card 3 (bottom): #1565C0

Background: White or gradient
Shape: Rounded square (iOS), adaptive (Android)
```

### Splash Screen:
```
Center: ProStack logo
Below: "Stack Your Professional Life"
Background: Blue gradient
Duration: 1-2 seconds
```

---

## 📊 Subscription Tier Updates

### Update Tier Names:

**Old → New**
```
Free → Free Stack
Premium → Pro Stack
Pro → Business Stack
```

### Update Features List:

**Free Stack:**
- 3 business cards
- 1 basic resume
- 3 credentials

**Pro Stack ($4.99/mo):**
- Unlimited cards
- 10+ resume templates
- Unlimited credentials
- Custom designs

**Business Stack ($9.99/mo):**
- Everything in Pro
- Full AI Resume Builder
- Team features
- Priority support

---

## 🚀 Testing Checklist

After installation:

### Visual Tests:
- [ ] App name shows "ProStack"
- [ ] Home screen has stacked cards icon
- [ ] Tagline displays correctly
- [ ] All 4 feature buttons appear
- [ ] Badges show correctly (PRO, SOON)
- [ ] Colors match brand (blue gradient)

### Functional Tests:
- [ ] Business Cards button works
- [ ] AI Resume shows paywall (free users)
- [ ] Credentials shows "Coming Soon"
- [ ] Portfolio shows "Coming Soon"
- [ ] Menu opens correctly
- [ ] Help dialog works
- [ ] About shows ProStack info

### Navigation Tests:
- [ ] Can navigate to cards list
- [ ] Can navigate to subscription screen
- [ ] Back button works
- [ ] All screens use new branding

---

## 📱 App Store Submission

### Update Metadata:

**App Name:**
- Primary: "ProStack"
- Full: "ProStack - Professional Suite"

**Subtitle:**
- "Business Cards, AI Resumes & Credentials"

**Keywords:**
```
business card scanner, resume builder, ai resume, 
credential manager, professional tools, networking app,
contact manager, certificate storage, career tools,
portfolio builder
```

**Category:**
- Primary: Business
- Secondary: Productivity

**Screenshots Order:**
1. Home screen (ProStack branding)
2. Business card scanning
3. Card list view
4. AI Resume Builder (mockup)
5. Subscription tiers

---

## 🎯 Marketing Launch

### Social Media:
```
Introducing ProStack! 🎯

Stack Your Professional Life with:
📇 Business Card Scanner
📄 AI Resume Builder
🎓 Credential Manager
🎨 Portfolio Builder

Everything you need for career success in one app.

Download now: [link]
#ProStack #CareerTools #Productivity
```

### Email to Existing Users:
```
Subject: We're Now ProStack! 🎯

Hi [Name],

Big news! Business Card Maker is now ProStack.

What's new?
✅ Same great business card scanning
✅ NEW: AI Resume Builder (Pro)
✅ Coming Soon: Credentials & Portfolio
✅ Fresh new design

Your cards and settings are safe - nothing lost!

Update now to see what's new.

- The ProStack Team
```

---

## 🔧 Troubleshooting

### App name not updating?
```bash
flutter clean
flutter pub get
flutter run
```

### Icon not changing?
```bash
# Regenerate icons
flutter pub run flutter_launcher_icons:main
```

### Colors not updating?
- Check main.dart theme
- Verify primaryColor: Color(0xFF1976D2)
- Hot restart (not just hot reload)

---

## ✅ Post-Launch Checklist

- [ ] App renamed to ProStack
- [ ] All screens show new branding
- [ ] Feature badges work correctly
- [ ] Existing data intact
- [ ] Subscription tiers updated
- [ ] App store listing updated
- [ ] Marketing materials ready
- [ ] Social media announced
- [ ] Users notified of rebrand

---

## 🎉 You're Ready!

ProStack is now ready to:
1. ✅ Differentiate from competitors
2. ✅ Scale to multiple features
3. ✅ Appeal to professionals
4. ✅ Support future growth
5. ✅ Build a lasting brand

**Welcome to ProStack! 🚀**
