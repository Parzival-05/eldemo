FROM python:3.13-alpine AS poetry-installer
WORKDIR /app

# Copy dependency manifests
COPY pyproject.toml poetry.lock ./

# Install Poetry in the builder and export requirements (handle empty deps)
RUN pip install --no-cache-dir --upgrade pip poetry \
    && poetry export -f requirements.txt --output requirements.txt --without-hashes || true \
    && if [ ! -f requirements.txt ]; then touch requirements.txt; fi

FROM python:3.13-alpine AS builder
WORKDIR /app

# Install runtime dependencies via pip (no Poetry needed in final image)
COPY --from=poetry-installer /app/requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir --upgrade pip \
    && if [ -s /tmp/requirements.txt ]; then pip install --no-cache-dir -r /tmp/requirements.txt; fi \
    && rm -f /tmp/requirements.txt

FROM python:3.13-alpine AS prod
WORKDIR /app
# Copy application source code
COPY . .

EXPOSE ${PORT}

# Run the app directly with Python
CMD ["python", "main.py"]