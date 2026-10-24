"""S3-compatible storage service using boto3."""

from __future__ import annotations

import uuid
from io import BytesIO
from typing import BinaryIO

import boto3
from botocore.config import Config as BotoConfig

from app.config import settings


def _get_s3_client():
    """Create and return a boto3 S3 client configured from settings."""
    return boto3.client(
        "s3",
        endpoint_url=settings.s3_endpoint_url,
        aws_access_key_id=settings.s3_access_key_id,
        aws_secret_access_key=settings.s3_secret_access_key,
        region_name=settings.s3_region,
        config=BotoConfig(signature_version="s3v4"),
    )


def upload_file(
    file_data: BinaryIO | bytes,
    folder: str = "uploads",
    filename: str | None = None,
    content_type: str = "application/octet-stream",
) -> str:
    """Upload a file to S3 and return its public URL.

    Parameters
    ----------
    file_data:
        File-like object or raw bytes.
    folder:
        Virtual folder / prefix in the bucket.
    filename:
        Custom filename.  A UUID-based name is generated if omitted.
    content_type:
        MIME type of the uploaded file.

    Returns
    -------
    str
        The full URL of the uploaded object.
    """
    client = _get_s3_client()

    if filename is None:
        ext = _guess_extension(content_type)
        filename = f"{uuid.uuid4().hex}{ext}"

    key = f"{folder}/{filename}"

    if isinstance(file_data, bytes):
        file_data = BytesIO(file_data)

    client.upload_fileobj(
        file_data,
        settings.s3_bucket_name,
        key,
        ExtraArgs={"ContentType": content_type},
    )

    # Build URL
    if "amazonaws.com" in settings.s3_endpoint_url:
        url = f"https://{settings.s3_bucket_name}.s3.{settings.s3_region}.amazonaws.com/{key}"
    else:
        url = f"{settings.s3_endpoint_url}/{settings.s3_bucket_name}/{key}"

    return url


def generate_presigned_url(key: str, expires_in: int = 3600) -> str:
    """Generate a pre-signed GET URL for a private object."""
    client = _get_s3_client()
    return client.generate_presigned_url(
        "get_object",
        Params={"Bucket": settings.s3_bucket_name, "Key": key},
        ExpiresIn=expires_in,
    )


def _guess_extension(content_type: str) -> str:
    """Map common MIME types to file extensions."""
    mapping = {
        "image/jpeg": ".jpg",
        "image/png": ".png",
        "image/webp": ".webp",
        "application/pdf": ".pdf",
        "video/mp4": ".mp4",
    }
    return mapping.get(content_type, "")
