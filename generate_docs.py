#!/usr/bin/env python3
"""
HeroDots / PlaceSecrets — Project Documentation Generator
Generates project-documentation.pdf with:
  Section 1: Database Schema UML Diagram
  Section 2: Use Case Inventory
"""

import datetime
import os
from reportlab.lib.pagesizes import A4
from reportlab.lib.colors import HexColor, white, black, Color
from reportlab.lib.units import mm, cm
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.enums import TA_CENTER, TA_LEFT, TA_RIGHT
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle,
    PageBreak, KeepTogether, Flowable
)
from reportlab.graphics.shapes import Drawing, Rect, String, Line, Polygon
from reportlab.graphics import renderPDF

# ──────────────────────────────────────────────
# COLORS
# ──────────────────────────────────────────────
PRIMARY = HexColor('#2D6A4F')
DARK = HexColor('#1A1A2E')
GOLD = HexColor('#B8960C')
HEADER_BG = HexColor('#1B3A4B')
ROW_EVEN = HexColor('#F0F4F8')
ROW_ODD = HexColor('#FFFFFF')
FK_COLOR = HexColor('#E07A5F')
LIGHT_BORDER = HexColor('#CBD5E1')
SECTION_BG = HexColor('#E8F5E9')

PAGE_W, PAGE_H = A4
MARGIN = 18 * mm

# ──────────────────────────────────────────────
# DATABASE SCHEMA DATA
# ──────────────────────────────────────────────
TABLES = [
    {
        "name": "countries",
        "group": "Geography",
        "columns": [
            ("code", "TEXT", "PK"),
            ("name", "TEXT", "NN"),
            ("aliases", "TEXT[]", "NN, DEF '{}'"),
            ("created_at", "TIMESTAMPTZ", "NN, DEF NOW()"),
            ("updated_at", "TIMESTAMPTZ", "NN, DEF NOW()"),
        ],
        "fks": [],
    },
    {
        "name": "cities",
        "group": "Geography",
        "columns": [
            ("id", "UUID", "PK"),
            ("name", "TEXT", "NN"),
            ("country_code", "TEXT", "NN, FK, DEF 'CZ'"),
            ("latitude", "DOUBLE PRECISION", "NN"),
            ("longitude", "DOUBLE PRECISION", "NN"),
            ("bounding_box_radius_km", "DOUBLE PRECISION", "NN, DEF 10"),
            ("price_eur", "DECIMAL(10,2)", "NN, DEF 1.00"),
            ("is_active", "BOOLEAN", "NN, DEF TRUE"),
            ("slug", "TEXT", "UQ"),
            ("registered_sample_poi_id", "UUID", "FK"),
            ("premium_bundle_price", "NUMERIC(10,2)", ""),
            ("aliases", "TEXT[]", "NN, DEF '{}'"),
            ("created_at", "TIMESTAMPTZ", "NN, DEF NOW()"),
            ("updated_at", "TIMESTAMPTZ", "NN, DEF NOW()"),
        ],
        "fks": [
            ("country_code", "countries", "code"),
            ("registered_sample_poi_id", "pois", "id"),
        ],
    },
    {
        "name": "poi_types",
        "group": "POI",
        "columns": [
            ("id", "UUID", "PK"),
            ("name", "JSONB", "NN"),
            ("slug", "TEXT", "NN, UQ"),
            ("icon_name", "TEXT", "NN, DEF 'place'"),
            ("color_hex", "TEXT", "NN, DEF '#2D6A4F'"),
            ("sort_order", "INTEGER", "NN, DEF 0"),
            ("is_active", "BOOLEAN", "NN, DEF TRUE"),
            ("created_at", "TIMESTAMPTZ", "NN"),
            ("updated_at", "TIMESTAMPTZ", "NN"),
        ],
        "fks": [],
    },
    {
        "name": "pois",
        "group": "POI",
        "columns": [
            ("id", "UUID", "PK"),
            ("city_id", "UUID", "NN, FK"),
            ("name", "JSONB", "NN"),
            ("description", "JSONB", "NN"),
            ("latitude", "DOUBLE PRECISION", "NN"),
            ("longitude", "DOUBLE PRECISION", "NN"),
            ("geofence_radius", "DOUBLE PRECISION", "NN, DEF 100"),
            ("photo_urls", "JSONB", "NN, DEF '[]'"),
            ("audio_urls", "JSONB", "NN, DEF '{}'"),
            ("is_premium", "BOOLEAN", "NN, DEF TRUE"),
            ("sort_order", "INTEGER", "NN, DEF 0"),
            ("is_active", "BOOLEAN", "NN, DEF TRUE"),
            ("slug", "TEXT", "UQ(city)"),
            ("access_level", "TEXT", "NN, CHK"),
            ("perex", "JSONB", ""),
            ("premium_price", "NUMERIC(10,2)", ""),
            ("contributor_id", "UUID", "FK"),
            ("contributor_note", "TEXT", ""),
            ("avg_rating", "DECIMAL(3,2)", ""),
            ("total_ratings", "INTEGER", "NN, DEF 0"),
            ("type_id", "UUID", "FK"),
            ("aliases", "TEXT[]", "NN, DEF '{}'"),
            ("created_at", "TIMESTAMPTZ", "NN"),
            ("updated_at", "TIMESTAMPTZ", "NN"),
        ],
        "fks": [
            ("city_id", "cities", "id"),
            ("contributor_id", "auth.users", "id"),
            ("type_id", "poi_types", "id"),
        ],
    },
    {
        "name": "poi_audio_guides",
        "group": "POI",
        "columns": [
            ("id", "UUID", "PK"),
            ("poi_id", "UUID", "NN, FK"),
            ("lang_code", "TEXT", "NN, CHK"),
            ("title", "TEXT", "NN, DEF ''"),
            ("url", "TEXT", "NN"),
            ("duration_sec", "INTEGER", ""),
            ("sort_order", "INTEGER", "NN, DEF 0"),
            ("uploaded_by", "UUID", "FK"),
            ("avg_rating", "DECIMAL(3,2)", "DEF 0"),
            ("total_ratings", "INTEGER", "DEF 0"),
            ("created_at", "TIMESTAMPTZ", "NN"),
            ("updated_at", "TIMESTAMPTZ", "NN"),
        ],
        "fks": [
            ("poi_id", "pois", "id"),
            ("uploaded_by", "auth.users", "id"),
        ],
    },
    {
        "name": "poi_audio_guide_ratings",
        "group": "POI",
        "columns": [
            ("id", "UUID", "PK"),
            ("audio_guide_id", "UUID", "NN, FK"),
            ("user_id", "UUID", "NN, FK"),
            ("rating", "SMALLINT", "NN, CHK 1-5"),
            ("created_at", "TIMESTAMPTZ", "NN"),
        ],
        "fks": [
            ("audio_guide_id", "poi_audio_guides", "id"),
            ("user_id", "auth.users", "id"),
        ],
    },
    {
        "name": "poi_ratings",
        "group": "POI",
        "columns": [
            ("id", "UUID", "PK"),
            ("poi_id", "UUID", "NN, FK"),
            ("user_id", "UUID", "FK"),
            ("device_id", "TEXT", "CHK"),
            ("rating", "SMALLINT", "NN, CHK 1-5"),
            ("reason", "TEXT", "CHK"),
            ("lang_code", "TEXT", "NN, DEF 'cs'"),
            ("comment", "TEXT", "CHK <=1000"),
            ("is_hidden", "BOOLEAN", "NN, DEF FALSE"),
            ("created_at", "TIMESTAMPTZ", "NN"),
        ],
        "fks": [
            ("poi_id", "pois", "id"),
            ("user_id", "auth.users", "id"),
        ],
    },
    {
        "name": "poi_premium_content",
        "group": "POI",
        "columns": [
            ("id", "UUID", "PK"),
            ("poi_id", "UUID", "NN, FK, UQ"),
            ("audio_url", "TEXT", ""),
            ("text_content", "TEXT", ""),
            ("extra_photos", "JSONB", "DEF '[]'"),
            ("related_poi_ids", "UUID[]", "DEF '{}'"),
            ("created_at", "TIMESTAMPTZ", "DEF NOW()"),
            ("updated_at", "TIMESTAMPTZ", "DEF NOW()"),
        ],
        "fks": [
            ("poi_id", "pois", "id"),
        ],
    },
    {
        "name": "user_profiles",
        "group": "Auth & Users",
        "columns": [
            ("id", "UUID", "PK"),
            ("user_id", "UUID", "UQ, NN, FK"),
            ("language", "TEXT", "NN, DEF 'en'"),
            ("status", "TEXT", "NN, CHK, DEF 'active'"),
            ("user_number", "BIGINT", "UQ, NN, SEQ"),
            ("backup_email", "TEXT", ""),
            ("display_name", "TEXT", "UQ, CHK"),
            ("created_at", "TIMESTAMPTZ", "NN"),
            ("updated_at", "TIMESTAMPTZ", "NN"),
        ],
        "fks": [
            ("user_id", "auth.users", "id"),
        ],
    },
    {
        "name": "admin_users",
        "group": "Auth & Users",
        "columns": [
            ("id", "UUID", "PK"),
            ("user_id", "UUID", "NN, UQ, FK"),
            ("role", "TEXT", "NN, CHK, DEF 'editor'"),
            ("pin_hash", "TEXT", ""),
            ("pin_set_at", "TIMESTAMPTZ", ""),
            ("pin_attempts", "INT", "DEF 0"),
            ("pin_locked_until", "TIMESTAMPTZ", ""),
            ("must_change_pin", "BOOLEAN", "NN, DEF TRUE"),
            ("created_at", "TIMESTAMPTZ", "NN"),
        ],
        "fks": [
            ("user_id", "auth.users", "id"),
        ],
    },
    {
        "name": "contributor_profiles",
        "group": "Auth & Users",
        "columns": [
            ("id", "UUID", "PK"),
            ("user_id", "UUID", "NN, UQ, FK"),
            ("display_name", "TEXT", "NN, CHK"),
            ("bio", "TEXT", "CHK <=2000"),
            ("avatar_url", "TEXT", "CHK"),
            ("website_url", "TEXT", "CHK"),
            ("specializations", "TEXT[]", "DEF '{}'"),
            ("total_pois", "INTEGER", "NN, DEF 0"),
            ("avg_rating", "DECIMAL(3,2)", ""),
            ("total_ratings", "INTEGER", "NN, DEF 0"),
            ("is_verified", "BOOLEAN", "NN, DEF FALSE"),
            ("is_active", "BOOLEAN", "NN, DEF TRUE"),
            ("created_at", "TIMESTAMPTZ", "NN"),
            ("updated_at", "TIMESTAMPTZ", "NN"),
        ],
        "fks": [
            ("user_id", "auth.users", "id"),
        ],
    },
    {
        "name": "acl_permissions",
        "group": "Auth & Users",
        "columns": [
            ("id", "UUID", "PK"),
            ("role", "TEXT", "NN, CHK"),
            ("resource", "TEXT", "NN, CHK"),
            ("can_read", "BOOLEAN", "NN, DEF FALSE"),
            ("can_write", "BOOLEAN", "NN, DEF FALSE"),
            ("can_delete", "BOOLEAN", "NN, DEF FALSE"),
            ("created_at", "TIMESTAMPTZ", "DEF NOW()"),
            ("updated_at", "TIMESTAMPTZ", "DEF NOW()"),
        ],
        "fks": [],
    },
    {
        "name": "user_access",
        "group": "Payments",
        "columns": [
            ("id", "UUID", "PK"),
            ("user_id", "UUID", "NN, FK"),
            ("city_id", "UUID", "NN, FK"),
            ("purchased_at", "TIMESTAMPTZ", "NN, DEF NOW()"),
            ("valid_until", "TIMESTAMPTZ", ""),
            ("payment_method", "TEXT", "NN, CHK"),
            ("transaction_id", "TEXT", ""),
            ("amount_eur", "DECIMAL(10,2)", ""),
        ],
        "fks": [
            ("user_id", "auth.users", "id"),
            ("city_id", "cities", "id"),
        ],
    },
    {
        "name": "payment_receipts",
        "group": "Payments",
        "columns": [
            ("id", "UUID", "PK"),
            ("user_id", "UUID", "NN, FK"),
            ("city_id", "UUID", "NN, FK"),
            ("purchased_at", "TIMESTAMPTZ", "NN, DEF NOW()"),
            ("payment_method", "TEXT", "NN, CHK"),
            ("transaction_id", "TEXT", ""),
            ("amount_eur", "DECIMAL(10,2)", "NN"),
            ("currency", "TEXT", "NN, DEF 'EUR'"),
            ("status", "TEXT", "NN, CHK, DEF 'completed'"),
            ("revolut_note", "TEXT", ""),
            ("confirmed_by", "UUID", "FK"),
            ("confirmed_at", "TIMESTAMPTZ", ""),
            ("receipt_number", "TEXT", "UQ, SEQ"),
            ("receipt_pdf_url", "TEXT", ""),
            ("receipt_sent_at", "TIMESTAMPTZ", ""),
            ("created_at", "TIMESTAMPTZ", "NN"),
        ],
        "fks": [
            ("user_id", "auth.users", "id"),
            ("city_id", "cities", "id"),
            ("confirmed_by", "auth.users", "id"),
        ],
    },
    {
        "name": "payment_config",
        "group": "Payments",
        "columns": [
            ("id", "UUID", "PK"),
            ("operator_name", "TEXT", "NN, DEF 'PlaceSecrets'"),
            ("revolut_username", "TEXT", ""),
            ("revolut_iban", "TEXT", ""),
            ("stripe_publishable_key", "TEXT", ""),
            ("stripe_secret_key", "TEXT", ""),
            ("google_pay_merchant_id", "TEXT", ""),
            ("apple_pay_merchant_id", "TEXT", ""),
            ("free_pois_per_month", "INTEGER", "NN, DEF 1"),
            ("max_geofences", "INTEGER", "NN, DEF 100"),
            ("max_photo_size_mb", "INTEGER", "NN, DEF 10"),
            ("max_audio_size_mb", "INTEGER", "NN, DEF 50"),
            ("admin_pin_attempts", "INTEGER", "NN, DEF 5"),
            ("admin_pin_lockout_minutes", "INTEGER", "NN, DEF 15"),
            ("receipt_prefix", "TEXT", "NN, DEF 'PS-'"),
            ("updated_at", "TIMESTAMPTZ", "NN"),
        ],
        "fks": [],
    },
    {
        "name": "user_poi_purchases",
        "group": "Payments",
        "columns": [
            ("id", "UUID", "PK"),
            ("user_id", "UUID", "NN, FK"),
            ("poi_id", "UUID", "NN, FK"),
            ("purchased_at", "TIMESTAMPTZ", "DEF NOW()"),
            ("price_paid", "NUMERIC(10,2)", ""),
            ("payment_id", "TEXT", ""),
            ("stripe_session_id", "TEXT", ""),
        ],
        "fks": [
            ("user_id", "auth.users", "id"),
            ("poi_id", "pois", "id"),
        ],
    },
    {
        "name": "user_city_premium_purchases",
        "group": "Payments",
        "columns": [
            ("id", "UUID", "PK"),
            ("user_id", "UUID", "NN, FK"),
            ("city_id", "UUID", "NN, FK"),
            ("purchased_at", "TIMESTAMPTZ", "DEF NOW()"),
            ("price_paid", "NUMERIC(10,2)", ""),
            ("payment_id", "TEXT", ""),
            ("stripe_session_id", "TEXT", ""),
        ],
        "fks": [
            ("user_id", "auth.users", "id"),
            ("city_id", "cities", "id"),
        ],
    },
    {
        "name": "free_visit_log",
        "group": "Activity",
        "columns": [
            ("id", "UUID", "PK"),
            ("user_id", "UUID", "FK"),
            ("device_id", "TEXT", ""),
            ("poi_id", "UUID", "NN, FK"),
            ("city_id", "UUID", "NN, FK"),
            ("visited_at", "TIMESTAMPTZ", "NN, DEF NOW()"),
            ("year_month", "TEXT", "NN"),
        ],
        "fks": [
            ("user_id", "auth.users", "id"),
            ("poi_id", "pois", "id"),
            ("city_id", "cities", "id"),
        ],
    },
    {
        "name": "audit_logs",
        "group": "Activity",
        "columns": [
            ("id", "UUID", "PK"),
            ("actor_id", "UUID", "FK"),
            ("action", "TEXT", "NN"),
            ("target_type", "TEXT", ""),
            ("target_id", "TEXT", ""),
            ("metadata", "JSONB", "DEF '{}'"),
            ("ip_address", "INET", ""),
            ("created_at", "TIMESTAMPTZ", "NN"),
        ],
        "fks": [
            ("actor_id", "auth.users", "id"),
        ],
    },
]

# ──────────────────────────────────────────────
# USE CASES DATA
# ──────────────────────────────────────────────
# (category, name, actor, app, entry_point, access_tier, status)
USE_CASES = [
    # ── 1. Authentication & Onboarding ──
    ("Authentication & Onboarding", "First App Launch Onboarding", "Anonymous user", "Flutter", "OnboardingScreen (/onboarding)", "Public", "Implemented"),
    ("Authentication & Onboarding", "Anonymous Session Initialization", "Anonymous user", "Flutter", "main.dart", "Public", "Implemented"),
    ("Authentication & Onboarding", "Email Registration (with handle)", "Anonymous/new user", "Flutter", "AuthScreen (/auth)", "Public", "Implemented"),
    ("Authentication & Onboarding", "Email Sign-In", "Registered user", "Flutter", "AuthScreen (/auth)", "Registered", "Implemented"),
    ("Authentication & Onboarding", "Password Reset", "Registered user", "Flutter", "AuthScreen (/auth)", "Public", "Implemented"),
    ("Authentication & Onboarding", "Sign Out (return to anonymous)", "Registered user", "Flutter", "SettingsScreen (/settings)", "Registered", "Implemented"),
    ("Authentication & Onboarding", "User Registration (Email)", "Anonymous user", "React", "RegisterPage (/register)", "Public", "Implemented"),
    ("Authentication & Onboarding", "Contributor Registration", "Anonymous user", "React", "ContributorRegisterPage (/register/contributor)", "Public", "Implemented"),
    ("Authentication & Onboarding", "User Sign-In (Email/Password)", "Any user", "React", "LoginPage (/login)", "Public", "Implemented"),
    ("Authentication & Onboarding", "OAuth Social Authentication", "Anonymous user", "React", "LoginPage, RegisterPage", "Public", "Implemented"),
    ("Authentication & Onboarding", "Admin PIN Verification", "Admin/Editor/Viewer", "React", "AdminPinPage (/admin-pin)", "Admin-only", "Implemented"),
    ("Authentication & Onboarding", "Force Change Admin PIN", "Admin/Editor/Viewer", "React", "ForceChangePinPage (/admin/force-change-pin)", "Admin-only", "Implemented"),
    ("Authentication & Onboarding", "Sign Out (web)", "Any authenticated", "React", "Account dropdown", "Registered", "Implemented"),

    # ── 2. POI Discovery & Browsing ──
    ("POI Discovery & Browsing", "View Interactive Map with POIs", "Any user", "Flutter", "MapScreen (/)", "Public", "Implemented"),
    ("POI Discovery & Browsing", "Detect Nearest City", "Any user", "Flutter", "MapScreen (auto)", "Public", "Implemented"),
    ("POI Discovery & Browsing", "Fetch & Cache POIs for City", "Any user", "Flutter", "MapScreen providers", "Public", "Implemented"),
    ("POI Discovery & Browsing", "Filter POIs by Access Level", "Any user", "Flutter", "MapScreen filter chips", "Public", "Implemented"),
    ("POI Discovery & Browsing", "Color-Coded POI Markers", "Any user", "Flutter", "MapScreen", "Public", "Implemented"),
    ("POI Discovery & Browsing", "Select POI (bottom sheet)", "Any user", "Flutter", "MapScreen marker tap", "Public", "Implemented"),
    ("POI Discovery & Browsing", "View Hall of Fame for City", "Any user", "Flutter", "HallOfFameScreen (/hall-of-fame/:cityId)", "Public", "Implemented"),
    ("POI Discovery & Browsing", "View Landing Page", "Anonymous user", "React", "LandingPage (/)", "Public", "Implemented"),
    ("POI Discovery & Browsing", "Explore Map of Places", "Registered user", "React", "AccountExplorePage (/account/explore)", "Registered", "Implemented"),

    # ── 3. POI Detail & Content Access ──
    ("POI Detail & Content Access", "View POI Detail Screen", "Any user", "Flutter", "PoiDetailScreen (/poi/:id)", "Public", "Implemented"),
    ("POI Detail & Content Access", "View POI Photo Gallery", "Any user", "Flutter", "PoiDetailScreen (photo tap)", "Public", "Implemented"),
    ("POI Detail & Content Access", "Access POI by Deep Link (slug)", "Any user", "Flutter", "PoiBySlugScreen (/:cc/:city/:poi)", "Public", "Implemented"),
    ("POI Detail & Content Access", "Check POI Access Level", "Any user", "Flutter", "PoiDetailScreen (get_poi_access RPC)", "Public", "Implemented"),
    ("POI Detail & Content Access", "Play Audio Guide", "Registered+ user", "Flutter", "AudioPlayerWidget", "Registered", "Implemented"),
    ("POI Detail & Content Access", "Select Audio Language", "Registered+ user", "Flutter", "AudioPlayerWidget", "Registered", "Implemented"),
    ("POI Detail & Content Access", "View Premium Content", "Premium user", "Flutter", "PremiumPoiContent widget", "Premium POI", "Implemented"),
    ("POI Detail & Content Access", "Premium Upgrade CTA", "Registered user", "Flutter", "PoiDetailScreen", "Registered", "Implemented"),
    ("POI Detail & Content Access", "Share POI Link", "Any user", "Flutter", "SharePoiButton", "Public", "Implemented"),
    ("POI Detail & Content Access", "Rate POI (1-5 stars + feedback)", "Registered+ user", "Flutter", "RatingWidget", "Registered", "Implemented"),
    ("POI Detail & Content Access", "View Existing Rating", "Registered user", "Flutter", "RatingWidget", "Registered", "Implemented"),
    ("POI Detail & Content Access", "View Place Detail (public web)", "Any user", "React", "PlaceDetailPage (/:cc/:city/:poi)", "Public", "Implemented"),
    ("POI Detail & Content Access", "Listen to Audio Guide (web)", "Registered user", "React", "PlaceDetailPage", "Registered", "Implemented"),
    ("POI Detail & Content Access", "Rate and Review POI (web)", "Registered user", "React", "PlaceDetailPage", "Registered", "Implemented"),

    # ── 4. Premium / Payment Flow ──
    ("Premium / Payment Flow", "View City Paywall", "Any user", "Flutter", "PaywallScreen (/paywall/:cityId)", "Public", "Implemented"),
    ("Premium / Payment Flow", "Pay with Google Pay", "Android user", "Flutter", "PaywallScreen", "Public", "Implemented"),
    ("Premium / Payment Flow", "Pay with Apple Pay", "iOS user", "Flutter", "PaywallScreen", "Public", "Implemented"),
    ("Premium / Payment Flow", "Purchase Individual POI", "Registered user", "Flutter", "PurchasePoiScreen (/purchase/poi/:id)", "Registered", "Implemented"),
    ("Premium / Payment Flow", "Purchase City Premium Bundle", "Registered user", "Flutter", "PurchasePoiScreen", "Registered", "Implemented"),
    ("Premium / Payment Flow", "Handle Purchase Success Redirect", "User (post-payment)", "Flutter", "DeepLinkHandler", "Registered", "Implemented"),
    ("Premium / Payment Flow", "View Purchase History (mobile)", "Registered user", "Flutter", "MyPurchasesScreen", "Registered", "Partial"),
    ("Premium / Payment Flow", "Use Free Monthly POI Visit", "Registered user", "Flutter", "AccessRepository", "Registered", "Implemented"),
    ("Premium / Payment Flow", "Purchase City Pass (web)", "Registered user", "React", "CityPricingPage", "Registered", "Implemented"),
    ("Premium / Payment Flow", "Purchase Individual POI (web)", "Registered user", "React", "PlaceDetailPage", "Registered", "Implemented"),
    ("Premium / Payment Flow", "View Purchase History (web)", "Registered user", "React", "AccountProfilePage (/account/profile)", "Registered", "Implemented"),
    ("Premium / Payment Flow", "Admin: View Payment Analytics", "Admin/Superadmin", "React", "PaymentsPage (/admin/payments)", "Admin-only", "Implemented"),
    ("Premium / Payment Flow", "Admin: View Payment Detail", "Admin/Superadmin", "React", "PaymentDetailPage (/admin/payments/:id)", "Admin-only", "Implemented"),
    ("Premium / Payment Flow", "Admin: Grant Free Access", "Admin/Superadmin", "React", "UserDetailPage + AccessGrantModal", "Admin-only", "Implemented"),

    # ── 5. User Profile & Settings ──
    ("User Profile & Settings", "View Settings Screen", "Any user", "Flutter", "SettingsScreen (/settings)", "Public", "Implemented"),
    ("User Profile & Settings", "Select Audio Language", "Any user", "Flutter", "SettingsScreen (dialog)", "Public", "Implemented"),
    ("User Profile & Settings", "Adjust Geofence Radius", "Any user", "Flutter", "SettingsScreen (slider)", "Public", "Implemented"),
    ("User Profile & Settings", "Toggle Notifications", "Any user", "Flutter", "SettingsScreen (switch)", "Public", "Implemented"),
    ("User Profile & Settings", "Set Backup Email", "Registered user", "Flutter", "SettingsScreen", "Registered", "Implemented"),
    ("User Profile & Settings", "Set/Update Handle", "Registered user", "Flutter", "SettingsScreen", "Registered", "Implemented"),
    ("User Profile & Settings", "View Account Status", "Any user", "Flutter", "SettingsScreen", "Public", "Implemented"),
    ("User Profile & Settings", "View About Information", "Any user", "Flutter", "SettingsScreen (dialog)", "Public", "Implemented"),
    ("User Profile & Settings", "View/Edit Profile (web)", "Registered user", "React", "AccountProfilePage (/account/profile)", "Registered", "Implemented"),
    ("User Profile & Settings", "Set/Change Handle (web)", "Registered user", "React", "AccountProfilePage", "Registered", "Implemented"),
    ("User Profile & Settings", "Change Password (web)", "Registered user", "React", "AccountProfilePage", "Registered", "Implemented"),
    ("User Profile & Settings", "Select Language (web)", "Registered user", "React", "AccountProfilePage", "Registered", "Implemented"),
    ("User Profile & Settings", "Set Backup Email (web)", "Registered user", "React", "AccountProfilePage", "Registered", "Implemented"),
    ("User Profile & Settings", "Delete User Account (web)", "Registered user", "React", "AccountProfilePage", "Registered", "Implemented"),
    ("User Profile & Settings", "View Visit History (web)", "Registered user", "React", "AccountHistoryPage (/account/history)", "Registered", "Implemented"),
    ("User Profile & Settings", "Contributor Profile Management", "Contributor", "React", "AdminProfilePage (/admin/profile)", "Contributor", "Implemented"),

    # ── 6. Admin - POI Management ──
    ("Admin - POI Management", "View All Cities", "Admin/Editor/Viewer", "React", "CitiesPage (/admin/cities)", "Admin-only", "Implemented"),
    ("Admin - POI Management", "Create New City", "Admin/Editor", "React", "CityNewPage (/admin/cities/new)", "Admin-only", "Implemented"),
    ("Admin - POI Management", "Edit City", "Admin/Editor", "React", "CityEditPage (/admin/cities/:id)", "Admin-only", "Implemented"),
    ("Admin - POI Management", "Create New Country", "Admin/Superadmin", "React", "CitiesPage (inline form)", "Admin-only", "Implemented"),
    ("Admin - POI Management", "View POIs in City", "Admin/Editor/Viewer", "React", "PoisPage (/admin/cities/:id/pois)", "Admin-only", "Implemented"),
    ("Admin - POI Management", "Create New POI", "Admin/Editor/Contributor", "React", "PoiNewPage (/admin/cities/:id/pois/new)", "Admin-only", "Implemented"),
    ("Admin - POI Management", "Edit POI", "Admin/Editor/Contributor", "React", "PoiEditPage (/admin/cities/:id/pois/:id)", "Admin-only", "Implemented"),
    ("Admin - POI Management", "Manage POI Ratings", "Admin/Editor", "React", "PoiEditPage (ratings tab)", "Admin-only", "Implemented"),
    ("Admin - POI Management", "Contributor: Manage My POIs", "Contributor", "React", "MyPoisPage (/admin/my-pois)", "Contributor", "Implemented"),
    ("Admin - POI Management", "Contributor: Create New POI", "Contributor", "React", "MyPoiEditorPage (/admin/my-pois/new)", "Contributor", "Implemented"),
    ("Admin - POI Management", "Manage POI Types", "Admin/Superadmin", "React", "PoiTypesPage (/admin/poi-types)", "Admin-only", "Implemented"),
    ("Admin - POI Management", "Configure City Pricing", "Admin/Superadmin", "React", "CityPricingPage (/admin/cities/:id/pricing)", "Admin-only", "Implemented"),

    # ── 7. Admin - User & Access Management ──
    ("Admin - User & Access Management", "View Dashboard", "Admin/Editor/Viewer", "React", "DashboardPage (/admin/dashboard)", "Admin-only", "Implemented"),
    ("Admin - User & Access Management", "View All Users", "Admin/Superadmin", "React", "UsersPage (/admin/users)", "Admin-only", "Implemented"),
    ("Admin - User & Access Management", "Create User Manually", "Admin/Superadmin", "React", "UsersPage (dialog)", "Admin-only", "Implemented"),
    ("Admin - User & Access Management", "View User Detail", "Admin/Superadmin", "React", "UserDetailPage (/admin/users/:id)", "Admin-only", "Implemented"),
    ("Admin - User & Access Management", "Grant City Access", "Admin/Superadmin", "React", "UserDetailPage + AccessGrantModal", "Admin-only", "Implemented"),
    ("Admin - User & Access Management", "Deactivate/Reactivate User", "Admin/Superadmin", "React", "UserDetailPage", "Admin-only", "Implemented"),
    ("Admin - User & Access Management", "Export User Data (GDPR)", "Admin/Superadmin", "React", "UserDetailPage", "Admin-only", "Implemented"),
    ("Admin - User & Access Management", "View All Contributors", "Admin/Editor", "React", "ContributorsPage (/admin/contributors)", "Admin-only", "Implemented"),
    ("Admin - User & Access Management", "View Contributor Detail", "Admin/Editor", "React", "ContributorDetailPage (/admin/contributors/:id)", "Admin-only", "Implemented"),
    ("Admin - User & Access Management", "Manage ACL Permissions", "Superadmin", "React", "AclManagementPage (/admin/acl)", "Admin-only", "Implemented"),
    ("Admin - User & Access Management", "Change Admin PIN", "Admin/Editor/Viewer", "React", "SettingsPage + ChangePinForm", "Admin-only", "Implemented"),
    ("Admin - User & Access Management", "Manage System Settings", "Superadmin", "React", "SettingsPage (/admin/settings)", "Admin-only", "Implemented"),
    ("Admin - User & Access Management", "Manage Admin Users", "Superadmin", "React", "SettingsPage + InviteAdminForm", "Admin-only", "Implemented"),
    ("Admin - User & Access Management", "Configure Payment Methods", "Superadmin", "React", "SettingsPage", "Admin-only", "Implemented"),
    ("Admin - User & Access Management", "View Hall of Fame (admin)", "Admin/Editor", "React", "HallOfFamePage (/admin/hall-of-fame)", "Admin-only", "Implemented"),

    # ── 8. Activity & Travel Log ──
    ("Activity & Travel Log", "Track POI Visit (geofence)", "Any user", "Flutter", "GeofenceService + VisitRepository", "Public", "Implemented"),
    ("Activity & Travel Log", "View Visit History", "Any user", "Flutter", "HistoryScreen (/history)", "Public", "Implemented"),
    ("Activity & Travel Log", "View Travel Statistics", "Any user", "Flutter", "HistoryScreen (badges)", "Public", "Implemented"),
    ("Activity & Travel Log", "Add Note to Visit", "Any user", "Flutter", "VisitRepository", "Public", "Partial"),
    ("Activity & Travel Log", "Add Photo to Visit", "Any user", "Flutter", "VisitRepository", "Public", "Partial"),
    ("Activity & Travel Log", "Export Travel Log to PDF", "Any user", "Flutter", "ExportScreen (/export)", "Public", "Implemented"),

    # ── 9. Other / System ──
    ("Other / System", "Sync Offline Data When Online", "System", "Flutter", "SyncService + ConnectivityService", "Public", "Implemented"),
    ("Other / System", "Device ID Tracking (anon ratings)", "System", "Flutter", "DeviceService", "Public", "Implemented"),
    ("Other / System", "Offline-First Local Database", "System", "Flutter", "Drift AppDatabase (7 tables)", "Public", "Implemented"),
    ("Other / System", "Fetch & Cache City List", "System", "Flutter", "MapProviders + CityRepository", "Public", "Implemented"),
    ("Other / System", "View Public Footer/Legal", "Anonymous user", "React", "PublicFooter", "Public", "Implemented"),
    ("Other / System", "Unauthorized Access Page", "Any authenticated", "React", "UnauthorizedPage (/unauthorized)", "Public", "Implemented"),
]

# ──────────────────────────────────────────────
# FK RELATIONSHIPS (for drawing lines)
# ──────────────────────────────────────────────
FK_RELS = []
for t in TABLES:
    for col, ref_table, ref_col in t["fks"]:
        if ref_table != "auth.users":
            FK_RELS.append((t["name"], col, ref_table, ref_col))


# ──────────────────────────────────────────────
# STYLES
# ──────────────────────────────────────────────
styles = getSampleStyleSheet()
styles.add(ParagraphStyle(name='TitlePage', fontSize=28, leading=34, alignment=TA_CENTER,
                          textColor=DARK, fontName='Helvetica-Bold', spaceAfter=8))
styles.add(ParagraphStyle(name='SubTitle', fontSize=14, leading=18, alignment=TA_CENTER,
                          textColor=PRIMARY, fontName='Helvetica', spaceAfter=20))
styles.add(ParagraphStyle(name='SectionHeader', fontSize=18, leading=22, textColor=DARK,
                          fontName='Helvetica-Bold', spaceBefore=16, spaceAfter=10))
styles.add(ParagraphStyle(name='SubSectionHeader', fontSize=13, leading=16, textColor=PRIMARY,
                          fontName='Helvetica-Bold', spaceBefore=10, spaceAfter=6))
styles.add(ParagraphStyle(name='Body', fontSize=9, leading=12, textColor=black,
                          fontName='Helvetica'))
styles.add(ParagraphStyle(name='Small', fontSize=7.5, leading=9, textColor=black,
                          fontName='Helvetica'))
styles.add(ParagraphStyle(name='SmallBold', fontSize=7.5, leading=9, textColor=black,
                          fontName='Helvetica-Bold'))
styles.add(ParagraphStyle(name='TableCell', fontSize=7, leading=9, textColor=black,
                          fontName='Helvetica'))
styles.add(ParagraphStyle(name='TableCellBold', fontSize=7, leading=9, textColor=black,
                          fontName='Helvetica-Bold'))
styles.add(ParagraphStyle(name='Footer', fontSize=7, leading=9, alignment=TA_CENTER,
                          textColor=HexColor('#94A3B8')))


def header_footer(canvas, doc):
    canvas.saveState()
    canvas.setFont('Helvetica', 7)
    canvas.setFillColor(HexColor('#94A3B8'))
    canvas.drawString(MARGIN, 12 * mm, "place-secrets — Project Documentation")
    canvas.drawRightString(PAGE_W - MARGIN, 12 * mm, f"Page {doc.page}")
    canvas.restoreState()


# ──────────────────────────────────────────────
# SCHEMA TABLE DRAWING (as Flowable)
# ──────────────────────────────────────────────
class SchemaTableFlowable(Flowable):
    """Draws a single database table as a UML-style box."""
    ROW_H = 11
    HEADER_H = 16
    COL_W = 100 * mm
    PAD = 3

    def __init__(self, table_data):
        super().__init__()
        self.table_data = table_data
        self.width = self.COL_W
        self.height = self.HEADER_H + len(table_data["columns"]) * self.ROW_H + 2

    def wrap(self, availWidth, availHeight):
        return (self.width, self.height)

    def draw(self):
        c = self.canv
        t = self.table_data
        w = self.width
        h = self.height

        # Shadow
        c.setFillColor(HexColor('#E2E8F0'))
        c.roundRect(2, -2, w, h, 3, stroke=0, fill=1)

        # Background
        c.setFillColor(white)
        c.setStrokeColor(LIGHT_BORDER)
        c.setLineWidth(0.5)
        c.roundRect(0, 0, w, h, 3, stroke=1, fill=1)

        # Header
        c.setFillColor(HEADER_BG)
        c.roundRect(0, h - self.HEADER_H, w, self.HEADER_H, 3, stroke=0, fill=1)
        # Cover bottom corners of header
        c.rect(0, h - self.HEADER_H, w, 4, stroke=0, fill=1)

        c.setFillColor(white)
        c.setFont('Helvetica-Bold', 9)
        c.drawString(self.PAD + 2, h - self.HEADER_H + 4, t["name"])

        # Group badge
        c.setFont('Helvetica', 6)
        c.setFillColor(HexColor('#94A3B8'))
        gw = c.stringWidth(t["group"], 'Helvetica', 6)
        c.drawString(w - gw - 6, h - self.HEADER_H + 5, t["group"])

        # Columns
        y = h - self.HEADER_H - self.ROW_H
        for i, (col_name, col_type, constraints) in enumerate(t["columns"]):
            # Alternate row bg
            if i % 2 == 0:
                c.setFillColor(ROW_EVEN)
                c.rect(1, y, w - 2, self.ROW_H, stroke=0, fill=1)

            # PK/FK indicator
            is_pk = "PK" in constraints
            is_fk = "FK" in constraints

            c.setFont('Helvetica-Bold' if is_pk else 'Helvetica', 7)
            c.setFillColor(FK_COLOR if is_fk else (PRIMARY if is_pk else black))
            prefix = ""
            if is_pk:
                prefix = "PK "
            elif is_fk:
                prefix = "FK "
            c.drawString(self.PAD + 2, y + 3, prefix + col_name)

            c.setFont('Helvetica', 6.5)
            c.setFillColor(HexColor('#64748B'))
            c.drawString(self.PAD + 50 * mm, y + 3, col_type)

            # Constraints (compact)
            short_c = constraints.replace("NN", "NOT NULL").replace("UQ", "UNIQUE").replace("DEF ", "= ")
            c.setFont('Helvetica', 5.5)
            c.setFillColor(HexColor('#94A3B8'))
            c.drawString(self.PAD + 78 * mm, y + 3, short_c[:30])

            y -= self.ROW_H


# ──────────────────────────────────────────────
# BUILD PDF
# ──────────────────────────────────────────────
def build_pdf():
    doc = SimpleDocTemplate(
        os.path.join(os.path.dirname(os.path.abspath(__file__)), "project-documentation.pdf"),
        pagesize=A4,
        leftMargin=MARGIN, rightMargin=MARGIN,
        topMargin=MARGIN, bottomMargin=MARGIN + 6 * mm,
    )

    story = []

    # ── TITLE PAGE ──
    story.append(Spacer(1, 60 * mm))
    story.append(Paragraph("place-secrets", styles['TitlePage']))
    story.append(Paragraph("Project Documentation", styles['SubTitle']))
    story.append(Spacer(1, 10 * mm))
    story.append(Paragraph(
        f"Generated: {datetime.date.today().isoformat()} | Version: 1.0",
        styles['SubTitle']
    ))
    story.append(Spacer(1, 15 * mm))

    # Stats summary on title page
    total_tables = len(TABLES)
    total_columns = sum(len(t["columns"]) for t in TABLES)
    total_fks = sum(len(t["fks"]) for t in TABLES)
    total_uc = len(USE_CASES)
    flutter_uc = sum(1 for uc in USE_CASES if uc[3] == "Flutter")
    react_uc = sum(1 for uc in USE_CASES if uc[3] == "React")

    summary_data = [
        ["Metric", "Value"],
        ["Database Tables", str(total_tables)],
        ["Total Columns", str(total_columns)],
        ["Foreign Key Relationships", str(total_fks)],
        ["Total Use Cases", str(total_uc)],
        ["Flutter (Mobile) Use Cases", str(flutter_uc)],
        ["React (Web Admin) Use Cases", str(react_uc)],
        ["Implemented", str(sum(1 for uc in USE_CASES if uc[6] == "Implemented"))],
        ["Partial", str(sum(1 for uc in USE_CASES if uc[6] == "Partial"))],
    ]
    summary_table = Table(summary_data, colWidths=[55 * mm, 25 * mm])
    summary_table.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), PRIMARY),
        ('TEXTCOLOR', (0, 0), (-1, 0), white),
        ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
        ('FONTSIZE', (0, 0), (-1, -1), 9),
        ('ALIGN', (1, 0), (1, -1), 'CENTER'),
        ('BACKGROUND', (0, 1), (-1, 1), ROW_EVEN),
        ('BACKGROUND', (0, 3), (-1, 3), ROW_EVEN),
        ('BACKGROUND', (0, 5), (-1, 5), ROW_EVEN),
        ('BACKGROUND', (0, 7), (-1, 7), ROW_EVEN),
        ('GRID', (0, 0), (-1, -1), 0.3, LIGHT_BORDER),
        ('TOPPADDING', (0, 0), (-1, -1), 4),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 4),
    ]))
    story.append(summary_table)

    story.append(PageBreak())

    # ── TABLE OF CONTENTS ──
    story.append(Paragraph("Table of Contents", styles['SectionHeader']))
    story.append(Spacer(1, 4 * mm))
    story.append(Paragraph("Section 1: Database Schema (UML Entity-Relationship Diagrams)", styles['Body']))
    story.append(Spacer(1, 2 * mm))

    groups_order = ["Geography", "POI", "Auth & Users", "Payments", "Activity"]
    for g in groups_order:
        tables_in = [t for t in TABLES if t["group"] == g]
        names = ", ".join(t["name"] for t in tables_in)
        story.append(Paragraph(f"  {g}: {names}", styles['Small']))

    story.append(Spacer(1, 6 * mm))
    story.append(Paragraph("Section 2: Use Case Inventory", styles['Body']))
    story.append(Spacer(1, 2 * mm))

    categories = []
    seen = set()
    for uc in USE_CASES:
        if uc[0] not in seen:
            seen.add(uc[0])
            categories.append(uc[0])
    for i, cat in enumerate(categories, 1):
        count = sum(1 for uc in USE_CASES if uc[0] == cat)
        story.append(Paragraph(f"  {i}. {cat} ({count} use cases)", styles['Small']))

    story.append(PageBreak())

    # ══════════════════════════════════════════
    # SECTION 1: DATABASE SCHEMA
    # ══════════════════════════════════════════
    story.append(Paragraph("Section 1: Database Schema", styles['SectionHeader']))
    story.append(Paragraph(
        f"{total_tables} tables | {total_columns} columns | {total_fks} foreign key relationships | "
        "All tables have Row-Level Security enabled",
        styles['Body']
    ))
    story.append(Spacer(1, 4 * mm))

    for group in groups_order:
        tables_in_group = [t for t in TABLES if t["group"] == group]
        story.append(Paragraph(f"{group} Tables", styles['SubSectionHeader']))

        for tbl in tables_in_group:
            flowable = SchemaTableFlowable(tbl)
            story.append(KeepTogether([flowable, Spacer(1, 4 * mm)]))

        # FK relationships for this group
        group_fks = []
        for tbl in tables_in_group:
            for col, ref_table, ref_col in tbl["fks"]:
                group_fks.append(f"{tbl['name']}.{col} -> {ref_table}.{ref_col}")
        if group_fks:
            story.append(Paragraph("Foreign Key Relationships:", styles['SmallBold']))
            for fk in group_fks:
                story.append(Paragraph(f"  {fk}", styles['Small']))
            story.append(Spacer(1, 3 * mm))

    # Views section
    story.append(Paragraph("Database Views", styles['SubSectionHeader']))
    views = [
        ("contributor_rankings", "Aggregated contributor stats per city with Hall of Fame score"),
        ("web_user_roles", "Effective role mapping (admin_users or contributor status)"),
        ("admin_stats", "High-level system statistics (cities, POIs, users, revenue)"),
        ("admin_users_view", "Aggregated user data with access counts and spending"),
        ("user_all_purchases", "Union view of all purchase types (POI, city premium, city access)"),
    ]
    view_data = [["View Name", "Description"]]
    for vn, vd in views:
        view_data.append([vn, vd])
    vt = Table(view_data, colWidths=[45 * mm, 120 * mm])
    vt.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), PRIMARY),
        ('TEXTCOLOR', (0, 0), (-1, 0), white),
        ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
        ('FONTSIZE', (0, 0), (-1, -1), 8),
        ('GRID', (0, 0), (-1, -1), 0.3, LIGHT_BORDER),
        ('TOPPADDING', (0, 0), (-1, -1), 3),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 3),
        ('BACKGROUND', (0, 1), (-1, 1), ROW_EVEN),
        ('BACKGROUND', (0, 3), (-1, 3), ROW_EVEN),
        ('BACKGROUND', (0, 5), (-1, 5), ROW_EVEN),
    ]))
    story.append(vt)
    story.append(Spacer(1, 4 * mm))

    # Sequences
    story.append(Paragraph("Sequences", styles['SubSectionHeader']))
    story.append(Paragraph("receipt_number_seq: START 1 (generates PS-XXXXXX receipt numbers)", styles['Small']))
    story.append(Paragraph("user_number_seq: START 100000 (generates 6-digit user IDs)", styles['Small']))

    story.append(PageBreak())

    # ══════════════════════════════════════════
    # SECTION 2: USE CASES
    # ══════════════════════════════════════════
    story.append(Paragraph("Section 2: Use Case Inventory", styles['SectionHeader']))
    story.append(Paragraph(
        f"{total_uc} total use cases across {len(categories)} categories | "
        f"{flutter_uc} Flutter (mobile) | {react_uc} React (web admin)",
        styles['Body']
    ))
    story.append(Spacer(1, 4 * mm))

    # Summary by category
    cat_summary = [["Category", "Count", "Flutter", "React"]]
    for cat in categories:
        cat_ucs = [uc for uc in USE_CASES if uc[0] == cat]
        cat_flutter = sum(1 for uc in cat_ucs if uc[3] == "Flutter")
        cat_react = sum(1 for uc in cat_ucs if uc[3] == "React")
        cat_summary.append([cat, str(len(cat_ucs)), str(cat_flutter), str(cat_react)])
    cat_summary.append(["TOTAL", str(total_uc), str(flutter_uc), str(react_uc)])

    cs_table = Table(cat_summary, colWidths=[65 * mm, 18 * mm, 18 * mm, 18 * mm])
    cs_table.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), PRIMARY),
        ('TEXTCOLOR', (0, 0), (-1, 0), white),
        ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
        ('FONTSIZE', (0, 0), (-1, -1), 8),
        ('ALIGN', (1, 0), (-1, -1), 'CENTER'),
        ('GRID', (0, 0), (-1, -1), 0.3, LIGHT_BORDER),
        ('TOPPADDING', (0, 0), (-1, -1), 3),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 3),
        ('FONTNAME', (0, -1), (-1, -1), 'Helvetica-Bold'),
        ('BACKGROUND', (0, -1), (-1, -1), HexColor('#E8F5E9')),
    ]))
    for i in range(1, len(cat_summary) - 1):
        if i % 2 == 0:
            cs_table.setStyle(TableStyle([
                ('BACKGROUND', (0, i), (-1, i), ROW_EVEN),
            ]))
    story.append(cs_table)
    story.append(Spacer(1, 6 * mm))

    # Actor breakdown
    story.append(Paragraph("Breakdown by Actor", styles['SubSectionHeader']))
    actors = {}
    for uc in USE_CASES:
        a = uc[2]
        actors[a] = actors.get(a, 0) + 1
    actor_data = [["Actor", "Count"]]
    for a, c in sorted(actors.items(), key=lambda x: -x[1]):
        actor_data.append([a, str(c)])
    at = Table(actor_data, colWidths=[55 * mm, 18 * mm])
    at.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), HEADER_BG),
        ('TEXTCOLOR', (0, 0), (-1, 0), white),
        ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
        ('FONTSIZE', (0, 0), (-1, -1), 8),
        ('ALIGN', (1, 0), (1, -1), 'CENTER'),
        ('GRID', (0, 0), (-1, -1), 0.3, LIGHT_BORDER),
        ('TOPPADDING', (0, 0), (-1, -1), 3),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 3),
    ]))
    for i in range(1, len(actor_data)):
        if i % 2 == 0:
            at.setStyle(TableStyle([('BACKGROUND', (0, i), (-1, i), ROW_EVEN)]))
    story.append(at)
    story.append(Spacer(1, 6 * mm))

    # Access tier breakdown
    story.append(Paragraph("Breakdown by Access Tier", styles['SubSectionHeader']))
    tiers = {}
    for uc in USE_CASES:
        t = uc[5]
        tiers[t] = tiers.get(t, 0) + 1
    tier_data = [["Access Tier", "Count"]]
    for t, c in sorted(tiers.items(), key=lambda x: -x[1]):
        tier_data.append([t, str(c)])
    tt = Table(tier_data, colWidths=[55 * mm, 18 * mm])
    tt.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), HEADER_BG),
        ('TEXTCOLOR', (0, 0), (-1, 0), white),
        ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
        ('FONTSIZE', (0, 0), (-1, -1), 8),
        ('ALIGN', (1, 0), (1, -1), 'CENTER'),
        ('GRID', (0, 0), (-1, -1), 0.3, LIGHT_BORDER),
        ('TOPPADDING', (0, 0), (-1, -1), 3),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 3),
    ]))
    for i in range(1, len(tier_data)):
        if i % 2 == 0:
            tt.setStyle(TableStyle([('BACKGROUND', (0, i), (-1, i), ROW_EVEN)]))
    story.append(tt)

    story.append(PageBreak())

    # ── Detailed use case tables per category ──
    for cat in categories:
        story.append(Paragraph(cat, styles['SubSectionHeader']))

        cat_ucs = [uc for uc in USE_CASES if uc[0] == cat]
        header = [
            Paragraph("<b>#</b>", styles['TableCell']),
            Paragraph("<b>Use Case</b>", styles['TableCellBold']),
            Paragraph("<b>Actor</b>", styles['TableCell']),
            Paragraph("<b>App</b>", styles['TableCell']),
            Paragraph("<b>Entry Point</b>", styles['TableCell']),
            Paragraph("<b>Tier</b>", styles['TableCell']),
            Paragraph("<b>Status</b>", styles['TableCell']),
        ]
        rows = [header]
        for i, uc in enumerate(cat_ucs, 1):
            rows.append([
                Paragraph(str(i), styles['TableCell']),
                Paragraph(uc[1], styles['TableCell']),
                Paragraph(uc[2], styles['TableCell']),
                Paragraph(uc[3], styles['TableCell']),
                Paragraph(uc[4], styles['TableCell']),
                Paragraph(uc[5], styles['TableCell']),
                Paragraph(uc[6], styles['TableCell']),
            ])

        col_widths = [8 * mm, 38 * mm, 26 * mm, 14 * mm, 42 * mm, 20 * mm, 18 * mm]
        uc_table = Table(rows, colWidths=col_widths, repeatRows=1)

        style_cmds = [
            ('BACKGROUND', (0, 0), (-1, 0), HEADER_BG),
            ('TEXTCOLOR', (0, 0), (-1, 0), white),
            ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
            ('FONTSIZE', (0, 0), (-1, -1), 7),
            ('GRID', (0, 0), (-1, -1), 0.3, LIGHT_BORDER),
            ('TOPPADDING', (0, 0), (-1, -1), 2),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 2),
            ('LEFTPADDING', (0, 0), (-1, -1), 2),
            ('RIGHTPADDING', (0, 0), (-1, -1), 2),
            ('VALIGN', (0, 0), (-1, -1), 'TOP'),
        ]
        for i in range(1, len(rows)):
            if i % 2 == 0:
                style_cmds.append(('BACKGROUND', (0, i), (-1, i), ROW_EVEN))
            # Highlight partial status
            if cat_ucs[i - 1][6] == "Partial":
                style_cmds.append(('TEXTCOLOR', (6, i), (6, i), GOLD))
                style_cmds.append(('FONTNAME', (6, i), (6, i), 'Helvetica-Bold'))

        uc_table.setStyle(TableStyle(style_cmds))
        story.append(uc_table)
        story.append(Spacer(1, 6 * mm))

    # ── BUILD ──
    doc.build(story, onFirstPage=header_footer, onLaterPages=header_footer)
    return total_tables, total_columns, total_fks, total_uc, flutter_uc, react_uc


if __name__ == "__main__":
    tables, cols, fks, uc_total, uc_flutter, uc_react = build_pdf()

    print("=" * 60)
    print("  PROJECT DOCUMENTATION GENERATED SUCCESSFULLY")
    print("=" * 60)
    print(f"  Output: project-documentation.pdf")
    print(f"  Date:   {datetime.date.today().isoformat()}")
    print()
    print("  DATABASE SCHEMA:")
    print(f"    Tables:              {tables}")
    print(f"    Total Columns:       {cols}")
    print(f"    FK Relationships:    {fks}")
    print()
    print("  USE CASES:")
    print(f"    Total:               {uc_total}")
    print(f"    Flutter (mobile):    {uc_flutter}")
    print(f"    React (web admin):   {uc_react}")
    print(f"    Implemented:         {sum(1 for uc in USE_CASES if uc[6] == 'Implemented')}")
    print(f"    Partial:             {sum(1 for uc in USE_CASES if uc[6] == 'Partial')}")
    print()

    # Breakdown by actor
    actors = {}
    for uc in USE_CASES:
        actors[uc[2]] = actors.get(uc[2], 0) + 1
    print("  BY ACTOR:")
    for a, c in sorted(actors.items(), key=lambda x: -x[1]):
        print(f"    {a:30s} {c}")

    # Breakdown by access tier
    tiers = {}
    for uc in USE_CASES:
        tiers[uc[5]] = tiers.get(uc[5], 0) + 1
    print()
    print("  BY ACCESS TIER:")
    for t, c in sorted(tiers.items(), key=lambda x: -x[1]):
        print(f"    {t:30s} {c}")

    # Breakdown by app
    print()
    print("  BY APP:")
    print(f"    Flutter (HeroDots mobile):    {uc_flutter}")
    print(f"    React (PlaceSecrets admin):   {uc_react}")
    print("=" * 60)
