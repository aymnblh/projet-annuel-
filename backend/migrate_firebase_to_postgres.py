"""
Firestore to PostgreSQL Migration Script
=========================================
This script reads all data from Firebase Firestore and inserts it into 
your local PostgreSQL database.

Prerequisites:
  1. pip install firebase-admin psycopg2-binary python-dotenv
  2. Set FIREBASE_SERVICE_ACCOUNT env var to your service account JSON path
  3. Set DATABASE_URL env var to your PostgreSQL connection string

Usage:
  python migrate_firebase_to_postgres.py
"""

import os
import uuid
from datetime import datetime
from dotenv import load_dotenv

load_dotenv()

# --- Firebase ---
import firebase_admin
from firebase_admin import credentials, firestore

sa_path = os.getenv("FIREBASE_SERVICE_ACCOUNT", "firebase_service_account.json")
if not firebase_admin._apps:
    cred = credentials.Certificate(sa_path)
    firebase_admin.initialize_app(cred)
db_firebase = firestore.client()

# --- PostgreSQL ---
import psycopg2
from psycopg2.extras import Json

DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://oneclick_user:oneclick_pass@localhost:5432/oneclick_cars_db")
conn = psycopg2.connect(DATABASE_URL)
cur = conn.cursor()

def migrate_users():
    print("Migrating users...")
    users = db_firebase.collection("users").get()
    count = 0
    for doc in users:
        d = doc.to_dict()
        try:
            cur.execute("""
                INSERT INTO users (uid, name, email, phone, photo_url, cover_image_url, whatsapp,
                    is_admin, is_banned, is_pro, is_verified, rating, created_at)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                ON CONFLICT (uid) DO NOTHING
            """, (
                doc.id,
                d.get("name", ""),
                d.get("email", ""),
                d.get("phone"),
                d.get("photoUrl") or d.get("photo_url"),
                d.get("coverImageUrl"),
                d.get("whatsapp"),
                d.get("isAdmin", False),
                d.get("isBanned", False),
                d.get("isPro", False),
                d.get("isVerified", False),
                Json({"average": d.get("rating", 0.0), "count": d.get("reviewCount", 0)}),
                d.get("createdAt") if isinstance(d.get("createdAt"), datetime) else datetime.utcnow(),
            ))
            count += 1
        except Exception as e:
            print(f"  Error migrating user {doc.id}: {e}")
    conn.commit()
    print(f"  Migrated {count} users.")

def migrate_products():
    print("Migrating products...")
    products = db_firebase.collection("products").get()
    count = 0
    for doc in products:
        d = doc.to_dict()
        created_at = d.get("createdAt")
        if hasattr(created_at, "ToDatetime"):
            created_at = created_at.ToDatetime()
        elif not isinstance(created_at, datetime):
            created_at = datetime.utcnow()
        try:
            cur.execute("""
                INSERT INTO products (
                    id, seller_id, title, description, price, category, wilaya, commune, phone,
                    image_urls, video_urls, sub_category, brand, model, year, km, fuel, gearbox,
                    engine, color, papers, exchange, is_sold, is_approved, is_boosted, is_urgent,
                    view_count, average_rating, review_count, rating_distribution, specs, created_at
                ) VALUES (
                    %s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s
                ) ON CONFLICT (id) DO NOTHING
            """, (
                doc.id,
                d.get("sellerId", ""),
                d.get("title", ""),
                d.get("description", ""),
                float(d.get("price", 0)),
                d.get("category", "Voitures Occasion"),
                d.get("wilaya", ""),
                d.get("commune"),
                d.get("phone"),
                Json(d.get("imageUrls", [])),
                Json(d.get("videoUrls", [])),
                d.get("subCategory"),
                d.get("brand"),
                d.get("model"),
                d.get("year"),
                d.get("km"),
                d.get("fuel"),
                d.get("gearbox"),
                d.get("engine"),
                d.get("color"),
                d.get("papers"),
                d.get("exchange", False),
                d.get("isSold", False),
                d.get("isApproved", False),
                d.get("isBoosted", False),
                d.get("isUrgent", False),
                d.get("viewCount", 0),
                float(d.get("averageRating", 0.0)),
                d.get("reviewCount", 0),
                Json(d.get("ratingDistribution", {"1": 0, "2": 0, "3": 0, "4": 0, "5": 0})),
                Json(d.get("specs", {})),
                created_at,
            ))
            count += 1
        except Exception as e:
            print(f"  Error migrating product {doc.id}: {e}")
    conn.commit()
    print(f"  Migrated {count} products.")

def migrate_reviews():
    print("Migrating reviews...")
    reviews = db_firebase.collection("reviews").get()
    count = 0
    for doc in reviews:
        d = doc.to_dict()
        created_at = d.get("createdAt")
        if hasattr(created_at, "ToDatetime"):
            created_at = created_at.ToDatetime()
        elif not isinstance(created_at, datetime):
            created_at = datetime.utcnow()
        try:
            cur.execute("""
                INSERT INTO reviews (
                    id, product_id, seller_id, user_id, user_name, user_photo,
                    rating, comment, photos, is_approved, is_flagged, flag_reason,
                    helpful_count, report_count, seller_response, is_verified_purchase, created_at
                ) VALUES (
                    %s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s
                ) ON CONFLICT (id) DO NOTHING
            """, (
                doc.id,
                d.get("productId", ""),
                d.get("sellerId", ""),
                d.get("userId", ""),
                d.get("userName", "Anonymous"),
                d.get("userPhoto"),
                int(d.get("rating", 5)),
                d.get("comment", ""),
                Json(d.get("photos", [])),
                d.get("isApproved", False),
                d.get("isFlagged", False),
                d.get("flagReason"),
                d.get("helpfulCount", 0),
                d.get("reportCount", 0),
                d.get("sellerResponse"),
                d.get("isVerifiedPurchase", False),
                created_at,
            ))
            count += 1
        except Exception as e:
            print(f"  Error migrating review {doc.id}: {e}")
    conn.commit()
    print(f"  Migrated {count} reviews.")

if __name__ == "__main__":
    print("Starting Firestore → PostgreSQL migration...")
    migrate_users()
    migrate_products()
    migrate_reviews()
    cur.close()
    conn.close()
    print("Migration complete! ✅")
