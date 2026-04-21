import boto3

from app.core.config import get_settings


class S3Service:
    def __init__(self) -> None:
        settings = get_settings()
        self.settings = settings
        self.client = boto3.client("s3", region_name=settings.aws_region)

    def upload_placeholder(self, bucket: str, key: str, body: bytes) -> None:
        self.client.put_object(Bucket=bucket, Key=key, Body=body)
