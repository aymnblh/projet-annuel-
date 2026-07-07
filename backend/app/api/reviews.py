from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
import uuid
from datetime import datetime
from app.db.session import get_db
from app.models.review import Review
from app.models.product import Product
from app.schemas.review import ReviewCreate, ReviewResponse, ReviewUpdate

router = APIRouter()

@router.post("/", response_model=ReviewResponse)
def submit_review(data: ReviewCreate, db: Session = Depends(get_db)):
    review = Review(id=str(uuid.uuid4()), **data.model_dump())
    db.add(review)
    db.commit()
    db.refresh(review)
    return review

@router.get("/product/{product_id}", response_model=List[ReviewResponse])
def get_product_reviews(product_id: str, approved_only: bool = True, db: Session = Depends(get_db)):
    query = db.query(Review).filter(Review.product_id == product_id)
    if approved_only:
        query = query.filter(Review.is_approved == True)
    return query.order_by(Review.created_at.desc()).all()

@router.get("/pending", response_model=List[ReviewResponse])
def get_pending_reviews(db: Session = Depends(get_db)):
    return db.query(Review).filter(Review.is_approved == False, Review.is_flagged == False).all()

@router.get("/flagged", response_model=List[ReviewResponse])
def get_flagged_reviews(db: Session = Depends(get_db)):
    return db.query(Review).filter(Review.is_flagged == True).all()

@router.put("/{review_id}", response_model=ReviewResponse)
def update_review(review_id: str, data: ReviewUpdate, db: Session = Depends(get_db)):
    review = db.query(Review).filter(Review.id == review_id).first()
    if not review:
        raise HTTPException(status_code=404, detail="Review not found")
    updates = data.model_dump(exclude_none=True)
    for key, value in updates.items():
        setattr(review, key, value)
    if "seller_response" in updates:
        review.seller_response_date = datetime.utcnow()
    db.commit()
    db.refresh(review)
    # Update product rating if approved
    _update_product_rating(review.product_id, db)
    return review

@router.put("/{review_id}/helpful")
def mark_helpful(review_id: str, db: Session = Depends(get_db)):
    review = db.query(Review).filter(Review.id == review_id).first()
    if not review:
        raise HTTPException(status_code=404, detail="Review not found")
    review.helpful_count += 1
    db.commit()
    return {"helpful_count": review.helpful_count}

@router.delete("/{review_id}")
def delete_review(review_id: str, db: Session = Depends(get_db)):
    review = db.query(Review).filter(Review.id == review_id).first()
    if not review:
        raise HTTPException(status_code=404, detail="Review not found")
    product_id = review.product_id
    db.delete(review)
    db.commit()
    _update_product_rating(product_id, db)
    return {"ok": True}

def _update_product_rating(product_id: str, db: Session):
    """Recalculates and updates the average rating for a product."""
    reviews = db.query(Review).filter(
        Review.product_id == product_id,
        Review.is_approved == True
    ).all()
    product = db.query(Product).filter(Product.id == product_id).first()
    if not product:
        return
    if not reviews:
        product.average_rating = 0.0
        product.review_count = 0
        product.rating_distribution = {"1": 0, "2": 0, "3": 0, "4": 0, "5": 0}
    else:
        dist = {"1": 0, "2": 0, "3": 0, "4": 0, "5": 0}
        total = 0
        for r in reviews:
            total += r.rating
            dist[str(r.rating)] += 1
        product.average_rating = round(total / len(reviews), 2)
        product.review_count = len(reviews)
        product.rating_distribution = dist
    db.commit()
