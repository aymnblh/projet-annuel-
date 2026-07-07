from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.db.session import engine
from app.models import product, review, user
from app.api import products, reviews, users, auth

# Create all tables
product.Base.metadata.create_all(bind=engine)
review.Base.metadata.create_all(bind=engine)
user.Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="OneClick Cars API",
    description="Hybrid API for OneClick Cars - Algerian Car Marketplace",
    version="1.0.0"
)

# CORS - allow Flutter app to connect
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Restrict in production to your app's domain
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Routers
app.include_router(auth.router, prefix="/auth", tags=["Authentication"])
app.include_router(products.router, prefix="/products", tags=["Products"])
app.include_router(reviews.router, prefix="/reviews", tags=["Reviews"])
app.include_router(users.router, prefix="/users", tags=["Users"])

@app.get("/", tags=["Health"])
def root():
    return {"status": "ok", "message": "OneClick Cars API is running 🚗"}
