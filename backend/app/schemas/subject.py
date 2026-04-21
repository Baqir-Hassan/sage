from pydantic import BaseModel, ConfigDict


class SubjectResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    name: str
    slug: str
    description: str | None = None
    cover_image_url: str | None = None
    lecture_count: int = 0
