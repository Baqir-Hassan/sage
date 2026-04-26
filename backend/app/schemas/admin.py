from pydantic import BaseModel, Field


class UserLimitResponse(BaseModel):
    user_id: str
    daily_new_lecture_limit: int
    daily_regeneration_limit: int
    override_daily_new_lecture_limit: int | None = None
    override_daily_regeneration_limit: int | None = None


class UserLimitUpdateRequest(BaseModel):
    daily_new_lecture_limit: int | None = Field(default=None, ge=0)
    daily_regeneration_limit: int | None = Field(default=None, ge=0)
