from __future__ import annotations

import json
import tempfile
from datetime import datetime, timezone as dt_timezone
from io import StringIO
from pathlib import Path
from uuid import uuid4

from django.contrib.auth import get_user_model
from django.core.management import call_command
from django.core.management.base import CommandError
from django.test import Client, TestCase
from django.test.utils import override_settings
from django.urls import reverse

from .models import CalibrationEvent, FeedbackReport, QuestionCatalog, QuestionReviewState

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

    @override_settings(
        TAPTEN_REVIEW_HOST="review.playtapten.com",
        ALLOWED_HOSTS=["testserver", "review.playtapten.com"],
    )
    def test_root_entrypoint_redirects_to_internal_on_review_host(self) -> None:
        response = self.client.get("/", HTTP_HOST="review.playtapten.com")

        self.assertEqual(response.status_code, 302)
        self.assertEqual(response["Location"], "/internal/")

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

    def test_admin_login_uses_tapten_branding(self) -> None:
        response = self.client.get("/admin/login/")

        self.assertEqual(response.status_code, 200)
        self.assertContains(response, "Tap Ten Editorial Admin")

    @override_settings(
        TAPTEN_REVIEW_HOST="review.playtapten.com",
        ALLOWED_HOSTS=["testserver", "review.playtapten.com"],
    )
    def test_login_page_links_to_absolute_review_favicon(self) -> None:
        response = self.client.get(
            reverse("editorial:login"),
            HTTP_HOST="review.playtapten.com",
        )

        self.assertEqual(response.status_code, 200)
        self.assertContains(response, 'href="/static/editorial/favicon.svg"')

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

    def test_question_queue_supports_prompt_search(self) -> None:
        matching_question = QuestionCatalog.objects.create(
            pack_id="history",
            pack_title="History Pack",
            pack_version="1.0",
            question_id="hist-events-that-can-start-a-revolution",
            prompt="Events that can start a revolution",
            category="History",
            difficulty_tier="medium",
            difficulty_score=23,
            validation_style="editorial",
            source_url="https://example.com/source",
            quality="draft",
            answers_json=[{"text": f"Answer {index}", "points": 1} for index in range(10)],
            content_hash="hash-search-match",
            is_current=True,
        )
        QuestionReviewState.objects.create(question_catalog=matching_question)

        other_question = QuestionCatalog.objects.create(
            pack_id="history",
            pack_title="History Pack",
            pack_version="1.0",
            question_id="hist-famous-treaties",
            prompt="Famous treaties people remember from school",
            category="History",
            difficulty_tier="medium",
            difficulty_score=19,
            validation_style="editorial",
            source_url="https://example.com/other-source",
            quality="draft",
            answers_json=[{"text": f"Other {index}", "points": 1} for index in range(10)],
            content_hash="hash-search-other",
            is_current=True,
        )
        QuestionReviewState.objects.create(question_catalog=other_question)

        self.client.force_login(self.user)
        response = self.client.get(
            reverse("editorial:question-list"),
            {"search": "revolution"},
        )

        self.assertEqual(response.status_code, 200)
        self.assertContains(response, "Events that can start a revolution")
        self.assertNotContains(response, "Famous treaties people remember from school")

    def test_question_detail_shows_recent_telemetry_events(self) -> None:
        question = QuestionCatalog.objects.create(
            pack_id="everyday-life",
            pack_title="Everyday Life Pack",
            pack_version="1.0",
            question_id="life-3",
            prompt="Name places people sing along loudly",
            category="Everyday Life",
            difficulty_tier="medium",
            difficulty_score=20,
            validation_style="editorial",
            source_url="https://example.com/source",
            quality="draft",
            answers_json=[{"text": f"Answer {index}", "points": 1} for index in range(10)],
            content_hash="hash-3",
            is_current=True,
        )
        QuestionReviewState.objects.create(question_catalog=question)
        CalibrationEvent.objects.create(
            event_id=uuid4(),
            client_timestamp=datetime.now(tz=dt_timezone.utc),
            pack_id="everyday-life",
            pack_title="Everyday Life Pack",
            pack_version="1.0",
            question_id="life-3",
            prompt="Name places people sing along loudly",
            category="Everyday Life",
            difficulty_tier="medium",
            finish_reason="skipped",
            round_duration_seconds=60,
            revealed_answer_indices=[0, 2, 5],
            total_answers=10,
            points_awarded=6,
            remaining_time_at_finish=18.4,
            time_to_first_reveal=2.1,
        )

        self.client.force_login(self.user)
        response = self.client.get(
            reverse("editorial:question-detail", kwargs={"question_id": question.id})
        )

        self.assertEqual(response.status_code, 200)
        self.assertContains(response, "Recent telemetry events")
        self.assertContains(response, "skipped")
        self.assertContains(response, "1, 3, 6")

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

    def test_import_packs_rejects_changed_question_without_pack_version_bump(self) -> None:
        payload = {
            "id": "sample-pack",
            "title": "Sample Pack",
            "packVersion": "1.0",
            "questions": [
                {
                    "id": "sample-question",
                    "category": "Everyday Life",
                    "prompt": "Things people misplace",
                    "difficulty": "medium",
                    "difficultyTier": "medium",
                    "difficultyScore": 18,
                    "validationStyle": "editorial",
                    "contentType": "list",
                    "quality": "draft",
                    "tags": [],
                    "difficultyNotes": "",
                    "editorialNotes": "",
                    "sourceURL": "https://example.com/source",
                    "answers": [{"text": f"Answer {index}", "points": 1} for index in range(10)],
                }
            ],
        }

        with tempfile.TemporaryDirectory() as temp_dir:
            pack_path = Path(temp_dir) / "SamplePack.json"
            pack_path.write_text(json.dumps(payload), encoding="utf-8")

            call_command("import_packs", source_path=temp_dir, stdout=StringIO())
            self.assertEqual(QuestionCatalog.objects.count(), 1)

            payload["questions"][0]["prompt"] = "Things people lose in the house"
            pack_path.write_text(json.dumps(payload), encoding="utf-8")

            with self.assertRaisesMessage(CommandError, "Bump packVersion for revised questions"):
                call_command("import_packs", source_path=temp_dir, stdout=StringIO())

        self.assertEqual(QuestionCatalog.objects.count(), 1)
        stored_question = QuestionCatalog.objects.get()
        self.assertEqual(stored_question.prompt, "Things people misplace")
        self.assertTrue(stored_question.is_current)

    def test_import_packs_allows_changed_question_after_pack_version_bump(self) -> None:
        payload = {
            "id": "sample-pack",
            "title": "Sample Pack",
            "packVersion": "1.0",
            "questions": [
                {
                    "id": "sample-question",
                    "category": "Everyday Life",
                    "prompt": "Things people misplace",
                    "difficulty": "medium",
                    "difficultyTier": "medium",
                    "difficultyScore": 18,
                    "validationStyle": "editorial",
                    "contentType": "list",
                    "quality": "draft",
                    "tags": [],
                    "difficultyNotes": "",
                    "editorialNotes": "",
                    "sourceURL": "https://example.com/source",
                    "answers": [{"text": f"Answer {index}", "points": 1} for index in range(10)],
                }
            ],
        }

        with tempfile.TemporaryDirectory() as temp_dir:
            pack_path = Path(temp_dir) / "SamplePack.json"
            pack_path.write_text(json.dumps(payload), encoding="utf-8")
            call_command("import_packs", source_path=temp_dir, stdout=StringIO())

            payload["packVersion"] = "1.1"
            payload["questions"][0]["prompt"] = "Things people lose in the house"
            pack_path.write_text(json.dumps(payload), encoding="utf-8")
            call_command("import_packs", source_path=temp_dir, stdout=StringIO())

        self.assertEqual(QuestionCatalog.objects.count(), 2)
        current_question = QuestionCatalog.objects.get(is_current=True)
        historical_question = QuestionCatalog.objects.get(is_current=False)
        self.assertEqual(current_question.pack_version, "1.1")
        self.assertEqual(current_question.prompt, "Things people lose in the house")
        self.assertEqual(historical_question.pack_version, "1.0")
