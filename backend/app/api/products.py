from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from sqlalchemy import or_
from typing import List, Optional
import uuid
from app.db.session import get_db
from app.models.product import Product
from app.schemas.product import ProductCreate, ProductResponse, ProductUpdate

router = APIRouter()

@router.get("/", response_model=List[ProductResponse])
def list_products(
    skip: int = 0,
    limit: int = 20,
    wilaya: Optional[str] = None,
    brand: Optional[str] = None,
    fuel: Optional[str] = None,
    min_price: Optional[float] = None,
    max_price: Optional[float] = None,
    category: Optional[str] = None,
    approved_only: bool = True,
    db: Session = Depends(get_db)
):
    query = db.query(Product).filter(Product.is_sold == False)
    if approved_only:
        query = query.filter(Product.is_approved == True)
    if wilaya:
        query = query.filter(Product.wilaya == wilaya)
    if brand:
        query = query.filter(Product.brand == brand)
    if fuel:
        query = query.filter(Product.fuel == fuel)
    if category:
        query = query.filter(Product.category == category)
    if min_price is not None:
        query = query.filter(Product.price >= min_price)
    if max_price is not None:
        query = query.filter(Product.price <= max_price)
    return query.order_by(Product.created_at.desc()).offset(skip).limit(limit).all()

@router.get("/search", response_model=List[ProductResponse])
def search_products(q: str = Query(..., min_length=1), db: Session = Depends(get_db)):
    results = db.query(Product).filter(
        Product.is_approved == True,
        Product.is_sold == False,
        or_(
            Product.title.ilike(f"%{q}%"),
            Product.brand.ilike(f"%{q}%"),
            Product.model.ilike(f"%{q}%"),
            Product.description.ilike(f"%{q}%"),
        )
    ).limit(30).all()
    return results

@router.get("/{product_id}", response_model=ProductResponse)
def get_product(product_id: str, db: Session = Depends(get_db)):
    product = db.query(Product).filter(Product.id == product_id).first()
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")
    # Increment view count
    product.view_count += 1
    db.commit()
    return product

@router.post("/", response_model=ProductResponse)
def create_product(data: ProductCreate, db: Session = Depends(get_db)):
    product = Product(id=str(uuid.uuid4()), **data.model_dump())
    db.add(product)
    db.commit()
    db.refresh(product)
    return product

@router.put("/{product_id}", response_model=ProductResponse)
def update_product(product_id: str, data: ProductUpdate, db: Session = Depends(get_db)):
    product = db.query(Product).filter(Product.id == product_id).first()
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")
    for key, value in data.model_dump(exclude_none=True).items():
        setattr(product, key, value)
    db.commit()
    db.refresh(product)
    return product

@router.delete("/{product_id}")
def delete_product(product_id: str, db: Session = Depends(get_db)):
    product = db.query(Product).filter(Product.id == product_id).first()
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")
    db.delete(product)
    db.commit()
    return {"ok": True}

@router.get("/seller/{seller_id}", response_model=List[ProductResponse])
def get_seller_products(seller_id: str, db: Session = Depends(get_db)):
    return db.query(Product).filter(
        Product.seller_id == seller_id,
        Product.is_sold == False,
        Product.is_approved == True,
    ).order_by(Product.created_at.desc()).all()
