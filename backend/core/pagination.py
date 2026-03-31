from fastapi import Query
from typing import TypeVar, Generic, List, Optional
from pydantic import BaseModel
from sqlalchemy.orm import Query as SQLAQuery

T = TypeVar("T")


class PaginationParams:
    """
    Reusable dependency for pagination.
    Inject this into any route that needs pagination.
    """
    def __init__(
        self,
        page: int = Query(default=1, ge=1, description="Page number (starts at 1)"),
        page_size: int = Query(default=10, ge=1, le=100, description="Items per page (max 100)")
    ):
        self.page = page
        self.page_size = page_size
        self.offset = (page - 1) * page_size  # DB offset


class PagedResponse(BaseModel, Generic[T]):
    """
    Standard paginated response wrapper.
    Every paginated endpoint returns this shape.
    """
    items: List[T]
    total: int
    page: int
    page_size: int
    total_pages: int
    has_next: bool
    has_previous: bool

    @classmethod
    def create(cls, items: List[T], total: int, params: PaginationParams):
        total_pages = (total + params.page_size - 1) // params.page_size  # ceiling division
        return cls(
            items=items,
            total=total,
            page=params.page,
            page_size=params.page_size,
            total_pages=total_pages,
            has_next=params.page < total_pages,
            has_previous=params.page > 1
        )
    