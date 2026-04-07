from __future__ import annotations

import hashlib
import json
from pathlib import Path

from django.core.management.base import BaseCommand, CommandError
from django.db import transaction

from editorial.models import QuestionCatalog, QuestionReviewState


def compute_content_hash(question_payload: dict) -> str:
    normalized = json.dumps(question_payload, sort_keys=True, separators=(",", ":"))
    return hashlib.sha256(normalized.encode("utf-8")).hexdigest()


def map_quality_to_workflow_state(quality: str) -> str:
    if quality == QuestionCatalog.Quality.REVIEWED:
        return QuestionReviewState.WorkflowState.APPROVED
    if quality == QuestionCatalog.Quality.PLAYTESTED:
        return QuestionReviewState.WorkflowState.PLAYTESTED
    if quality == QuestionCatalog.Quality.NEEDS_REFRESH:
        return QuestionReviewState.WorkflowState.REFRESH_NEEDED
    return QuestionReviewState.WorkflowState.PROPOSED


def assert_revision_bump_if_needed(
    *,
    pack_id: str,
    question_id: str,
    pack_version: str,
    content_hash: str,
) -> None:
    conflicting_revision_exists = QuestionCatalog.objects.filter(
        pack_id=pack_id,
        question_id=question_id,
        pack_version=pack_version,
    ).exclude(content_hash=content_hash).exists()

    if conflicting_revision_exists:
        version_label = pack_version or "<empty>"
        raise CommandError(
            "Refusing to import changed content for "
            f"{pack_id}:{question_id} at packVersion {version_label}. "
            "Bump packVersion for revised questions, or assign a new questionID for replacements."
        )


class Command(BaseCommand):
    help = "Import Tap Ten question packs from bundled JSON files."

    def add_arguments(self, parser) -> None:
        parser.add_argument(
            "--from",
            dest="source_path",
            required=True,
            help="Path to the question-pack JSON directory.",
        )

    def handle(self, *args, **options) -> None:
        source_path = Path(options["source_path"]).expanduser().resolve()
        if not source_path.exists() or not source_path.is_dir():
            raise CommandError(f"Invalid source path: {source_path}")

        file_paths = sorted(source_path.glob("*.json"))
        if not file_paths:
            raise CommandError(f"No JSON files found in {source_path}")

        imported_question_count = 0
        with transaction.atomic():
            for file_path in file_paths:
                with file_path.open("r", encoding="utf-8") as file_handle:
                    payload = json.load(file_handle)

                pack_id = payload.get("id")
                pack_title = payload.get("title")
                pack_version = payload.get("packVersion") or ""
                questions = payload.get("questions") or []
                current_record_ids: list[int] = []

                for question_payload in questions:
                    answers = question_payload.get("answers") or []
                    difficulty_score = question_payload.get("difficultyScore")
                    if difficulty_score is None:
                        difficulty_score = sum(
                            int(answer.get("points", 0))
                            for answer in answers
                        )

                    difficulty_tier = (
                        question_payload.get("difficultyTier")
                        or question_payload.get("difficulty")
                        or QuestionCatalog.DifficultyTier.MEDIUM
                    )
                    quality = question_payload.get("quality") or QuestionCatalog.Quality.DRAFT
                    question_id = question_payload["id"]
                    content_hash = compute_content_hash(question_payload)

                    assert_revision_bump_if_needed(
                        pack_id=pack_id,
                        question_id=question_id,
                        pack_version=pack_version,
                        content_hash=content_hash,
                    )

                    catalog_record, _created = QuestionCatalog.objects.update_or_create(
                        pack_id=pack_id,
                        question_id=question_id,
                        pack_version=pack_version,
                        content_hash=content_hash,
                        defaults={
                            "pack_title": pack_title,
                            "prompt": question_payload["prompt"],
                            "category": question_payload["category"],
                            "difficulty_tier": difficulty_tier,
                            "difficulty_score": difficulty_score,
                            "validation_style": question_payload["validationStyle"],
                            "source_url": question_payload["sourceURL"],
                            "content_type": question_payload.get("contentType") or "",
                            "quality": quality,
                            "difficulty_notes": question_payload.get("difficultyNotes") or "",
                            "editorial_notes": question_payload.get("editorialNotes") or "",
                            "answers_json": answers,
                            "is_current": True,
                        },
                    )
                    current_record_ids.append(catalog_record.id)
                    imported_question_count += 1

                    QuestionCatalog.objects.filter(
                        pack_id=pack_id,
                        question_id=question_id,
                    ).exclude(pk=catalog_record.pk).update(is_current=False)

                    QuestionReviewState.objects.get_or_create(
                        question_catalog=catalog_record,
                        defaults={
                            "workflow_state": map_quality_to_workflow_state(quality),
                        },
                    )

                QuestionCatalog.objects.filter(pack_id=pack_id).exclude(
                    pk__in=current_record_ids
                ).update(is_current=False)

                self.stdout.write(
                    self.style.SUCCESS(
                        f"Imported {len(questions)} questions from {file_path.name}"
                    )
                )

        self.stdout.write(
            self.style.SUCCESS(
                f"Import complete. Processed {len(file_paths)} pack files and {imported_question_count} questions."
            )
        )
