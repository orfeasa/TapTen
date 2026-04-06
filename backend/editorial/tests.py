from __future__ import annotations

import json
from datetime import datetime, timezone as dt_timezone
from uuid import uuid4

from django.contrib.auth import get_user_model
from django.test import Client, TestCase
from django.test.utils import override_settings
from django.urls import reverse

from .models import FeedbackReport, QuestionCatalog, QuestionReviewState

User = get_user_model()


class EditorialBackendTests(TestCase):
    def setUp(self) -> None:
        self.client = Client()
        self.user = User.objects.create_user(
            username="reviewer",
            password="tapten-reviewer-pass-123",
        )

    def test_healthz_endpoint_returns_ok(self) -> None:
        response = self.client.get(reverse("healthz"))

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json(), {"status": "ok"})

    def test_feedback_ingest_persists_report(self) -> None:
        payload = {
            "id": str(uuid4()),
            "submittedAt": datetime.now(tz=dt_timezone.utc).isoformat(),
            "reason": "tooEasy",
            "note": "Feels obvious.",
            "appVersion": "1.0 (1)",
            "packID": "everyday-life",
            "packTitle": "Everyday Life Pack",
            "packVersion": "1.0",
            "questionID": "q-1",
            "prompt": "Name a fruit",
            "category": "Food & Drink",
            "difficultyTier": "easy",
            "validationStyle": "editorial",
            "sourceURL": "https://example.com/source",
        }

        response = self.client.post(
            reverse("question-feedback-ingest"),
            data=json.dumps(payload),
            content_type="application/json",
        )

        self.assertEqual(response.status_code, 204)
        self.assertEqual(FeedbackReport.objects.count(), 1)
        self.assertEqual(FeedbackReport.objects.first().question_id, "q-1")

    def test_question_queue_requires_login(self) -> None:
        response = self.client.get(reverse("editorial:question-list"))

        self.assertEqual(response.status_code, 302)
        self.assertIn(reverse("editorial:login"), response.url)

    def test_logged_in_reviewer_can_open_question_detail(self) -> None:
        question = QuestionCatalog.objects.create(
            pack_id="everyday-life",
            pack_title="Everyday Life Pack",
            pack_version="1.0",
            question_id="life-1",
            prompt="Name things people lose",
            category="Everyday Life",
            difficulty_tier="medium",
            difficulty_score=22,
            validation_style="editorial",
            source_url="https://example.com/source",
            quality="draft",
            answers_json=[{"text": f"Answer {index}", "points": 1} for index in range(10)],
            content_hash="hash-1",
            is_current=True,
        )
        QuestionReviewState.objects.create(question_catalog=question)

        self.client.force_login(self.user)
        response = self.client.get(
            reverse("editorial:question-detail", kwargs={"question_id": question.id})
        )

        self.assertEqual(response.status_code, 200)
        self.assertContains(response, "Name things people lose")

    def test_staff_user_can_export_reviews_csv(self) -> None:
        self.user.is_staff = True
        self.user.save(update_fields=["is_staff"])
        question = QuestionCatalog.objects.create(
            pack_id="everyday-life",
            pack_title="Everyday Life Pack",
            pack_version="1.0",
            question_id="life-2",
            prompt="Name things on a desk",
            category="Everyday Life",
            difficulty_tier="easy",
            difficulty_score=14,
            validation_style="editorial",
            source_url="https://example.com/source",
            quality="draft",
            answers_json=[{"text": f"Answer {index}", "points": 1} for index in range(10)],
            content_hash="hash-2",
            is_current=True,
        )
        QuestionReviewState.objects.create(question_catalog=question)

        self.client.force_login(self.user)
        response = self.client.get(reverse("editorial:export-reviews"))

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response["Content-Type"], "text/csv")
        self.assertIn("life-2", response.content.decode("utf-8"))

    @override_settings(
        TAPTEN_REVIEW_HOST="review.playtapten.com",
        ALLOWED_HOSTS=["testserver", "api.playtapten.com", "review.playtapten.com"],
    )
    def test_internal_route_is_rejected_on_wrong_host(self) -> None:
        self.client.force_login(self.user)
        response = self.client.get(
            reverse("editorial:dashboard"),
            HTTP_HOST="api.playtapten.com",
        )

        self.assertEqual(response.status_code, 404)
