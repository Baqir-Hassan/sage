from fastapi import APIRouter

from app.api.v1.routes import admin_users, auth, lectures, library, playlists, subjects, uploads


api_router = APIRouter()
api_router.include_router(auth.router, prefix="/auth", tags=["auth"])
api_router.include_router(subjects.router, prefix="/subjects", tags=["subjects"])
api_router.include_router(playlists.router, prefix="/playlists", tags=["playlists"])
api_router.include_router(lectures.router, prefix="/lectures", tags=["lectures"])
api_router.include_router(uploads.router, prefix="/uploads", tags=["uploads"])
api_router.include_router(library.router, prefix="/library", tags=["library"])
api_router.include_router(admin_users.router, prefix="/admin", tags=["admin"])
