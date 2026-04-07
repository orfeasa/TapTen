from django.contrib import admin
from django.urls import include, path

from editorial import api_views

urlpatterns = [
    path("", api_views.root_entrypoint, name="root-entrypoint"),
    path("admin/", admin.site.urls),
    path("tapten/healthz", api_views.healthz, name="healthz"),
    path(
        "tapten/v1/question-feedback",
        api_views.question_feedback_ingest,
        name="question-feedback-ingest",
    ),
    path(
        "tapten/v1/question-calibration/batch",
        api_views.question_calibration_batch_ingest,
        name="question-calibration-batch-ingest",
    ),
    path("internal/", include(("editorial.urls", "editorial"), namespace="editorial")),
]
