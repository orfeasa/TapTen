import multiprocessing
import os
from pathlib import Path


backend_dir = Path(__file__).resolve().parent
chdir = os.environ.get("TAPTEN_GUNICORN_CHDIR", str(backend_dir))
bind = os.environ.get("TAPTEN_GUNICORN_BIND", "127.0.0.1:8100")
workers = int(
    os.environ.get(
        "TAPTEN_GUNICORN_WORKERS",
        max(2, min(multiprocessing.cpu_count() * 2 + 1, 8)),
    )
)
threads = int(os.environ.get("TAPTEN_GUNICORN_THREADS", "2"))
timeout = int(os.environ.get("TAPTEN_GUNICORN_TIMEOUT", "60"))
graceful_timeout = int(os.environ.get("TAPTEN_GUNICORN_GRACEFUL_TIMEOUT", "30"))
keepalive = int(os.environ.get("TAPTEN_GUNICORN_KEEPALIVE", "5"))
accesslog = os.environ.get("TAPTEN_GUNICORN_ACCESSLOG", "-")
errorlog = os.environ.get("TAPTEN_GUNICORN_ERRORLOG", "-")
capture_output = True
