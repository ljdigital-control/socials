# Socials (LightPost fork) for Fly.io: one always-on Python process + SQLite on a volume at /data.
FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    HOST=0.0.0.0 \
    PORT=8080 \
    COOKIE_SECURE=true \
    DATABASE_PATH=/data/socials.sqlite \
    WEB_ROOT=/app/web

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY lightpost ./lightpost
COPY web ./web

# Database, uploaded images (/data/media) and the fallback credentials.key all live on the volume.
EXPOSE 8080
CMD ["python", "-m", "lightpost"]
