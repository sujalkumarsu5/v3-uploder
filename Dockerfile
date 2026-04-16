# ═══════════════════════════════════════════════════════════════
#  🦚Rᴀᴅʜᴀ♡︎Kʀɪsʜɴᴀ༗🌹 UPLOADER — Production Dockerfile
#  Compatible: Heroku, Render, Koyeb
# ═══════════════════════════════════════════════════════════════

FROM python:3.11-slim-bookworm

# ─── Working Dir ──────────────────────────────────────────────
WORKDIR /app

# ─── System Packages (ffmpeg, aria2, build tools) ─────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc g++ cmake make \
    libffi-dev \
    ffmpeg \
    aria2 \
    wget curl unzip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ─── Bento4 mp4decrypt (DRM support) ─────────────────────────
RUN wget -q https://github.com/axiomatic-systems/Bento4/archive/refs/tags/v1.6.0-639.zip \
    && unzip -q v1.6.0-639.zip \
    && cd Bento4-1.6.0-639 \
    && mkdir cmakebuild && cd cmakebuild \
    && cmake -DCMAKE_BUILD_TYPE=Release .. -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
    && make -j$(nproc) mp4decrypt \
    && cp mp4decrypt /usr/local/bin/ \
    && cd /app && rm -rf Bento4-1.6.0-639 v1.6.0-639.zip

# ─── Python Dependencies ──────────────────────────────────────
COPY itsgolubots.txt .
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir -r itsgolubots.txt

# ─── App Source ───────────────────────────────────────────────
COPY . .

# ─── Aria2 Config ─────────────────────────────────────────────
RUN mkdir -p /etc/aria2 && printf \
"disable-ipv6=true\nfile-allocation=falloc\noptimize-concurrent-downloads=true\nmax-concurrent-downloads=10\nmax-connection-per-server=16\nsplit=16\nmin-split-size=1M\ncontinue=true\ncheck-integrity=true\n" \
> /etc/aria2/aria2.conf

# ─── Port (Render/Koyeb need a bound port for health check) ───
ENV PORT=8000

# ─── Startup ──────────────────────────────────────────────────
# aria2 daemon + Flask keep-alive web server + Telegram bot
CMD aria2c --enable-rpc --rpc-listen-all --daemon=true \
    && gunicorn --bind 0.0.0.0:${PORT} \
       --workers 1 --threads 2 --timeout 120 app:app \
       --daemon \
    && python3 main.py
