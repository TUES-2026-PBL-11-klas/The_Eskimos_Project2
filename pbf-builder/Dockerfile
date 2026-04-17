FROM python:3.12-slim

# osmium-tool for merging PBF files; wget for downloading Geofabrik PBF
RUN apt-get update && apt-get install -y --no-install-recommends \
        osmium-tool \
        wget \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY geojson_to_osm.py .
COPY valhalla.json .
COPY build_pbf.sh .
RUN sed -i 's/\r$//' /app/build_pbf.sh && chmod +x /app/build_pbf.sh

ENTRYPOINT ["/app/build_pbf.sh"]
