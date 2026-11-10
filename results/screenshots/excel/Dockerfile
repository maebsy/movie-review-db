FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends libreoffice-calc-nogui python3-openpyxl poppler-utils fonts-nanum \
 && rm -rf /var/lib/apt/lists/*
WORKDIR /w
