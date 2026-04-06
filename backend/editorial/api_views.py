from __future__ import annotations

import json
from datetime import datetime, timezone as dt_timezone
from uuid import UUID

from django.http import HttpRequest, HttpResponse, JsonResponse
from django.utils import timezone
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_GET, require_POST

from .models import CalibrationEvent, FeedbackReport


def parse_datetime(value: str | None) -> datetime | None:
    if not value:
        return None

    normalized = value.replace("Z", "+00:00")
    try:
        parsed = datetime.fromisoformat(normalized)
    except ValueError:
        return None

    if timezone.is_naive(parsed):
        return timezone.make_aware(parsed, dt_timezone.utc)
    return parsed


def parse_uuid(value: str | None) -> UUID | None:
    if not value:
        return None
    try:
        return UUID(value)
    except (ValueError, TypeError):
        return None


def json_error(message: str, status: int = 400) -> JsonResponse:
    return JsonResponse({"error": message}, status=status)


def load_json_body(request: HttpRequest) -> dict | list | None:
    try:
        return json.loads(request.body.decode("utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError):
        return None


@require_GET
def healthz(_request: HttpRequest) -> JsonResponse:
    return JsonResponse({"status": "ok"})


@csrf_exempt
@require_POST
def question_feedback_ingest(request: HttpRequest) -> HttpResponse:
    payload = load_json_body(request)
    if not isinstance(payload, dict):
        return json_error("Expected a JSON object.")

    required_fields = [
        "id",
        "submittedAt",
        "reason",
        "note",
        "appVersion",
        "questionID",
        "prompt",
        "category",
        "difficultyTier",
        "validationStyle",
        "sourceURL",
    ]
    missing_fields = [field for field in required_fields if field not in payload]
    if missing_fields:
        return json_error(f"Missing required fields: {', '.join(missing_fields)}")

    report_uuid = parse_uuid(payload.get("id"))
    if report_uuid is None:
        return json_error("Invalid report id.")

    submitted_at = parse_datetime(payload.get("submittedAt"))
    if submitted_at is None:
        return json_error("Invalid submittedAt timestamp.")

    note = str(payload.get("note", "")).strip()
    if len(note) > 2_000:
        return json_error("Note is too long.")

    source_url = str(payload.get("sourceURL", "")).strip()
    if not source_url.startswith(("http://", "https://")):
        return json_error("sourceURL must be an http/https URL.")

    FeedbackReport.objects.update_or_create(
        report_id=report_uuid,
        defaults={
            "submitted_at": submitted_at,
            "reason": str(payload["reason"]).strip(),
            "note": note,
            "app_version": str(payload["appVersion"]).strip(),
            "pack_id": payload.get("packID") or None,
            "pack_title": payload.get("packTitle") or None,
            "pack_version": payload.get("packVersion") or None,
            "question_id": str(payload["questionID"]).strip(),
            "prompt": str(payload["prompt"]).strip(),
            "category": str(payload["category"]).strip(),
            "difficulty_tier": str(payload["difficultyTier"]).strip(),
            "validation_style": str(payload["validationStyle"]).strip(),
            "source_url": source_url,
        },
    )

    return HttpResponse(status=204)


@csrf_exempt
@require_POST
def question_calibration_batch_ingest(request: HttpRequest) -> HttpResponse:
    payload = load_json_body(request)
    if isinstance(payload, list):
        events_payload = payload
    elif isinstance(payload, dict) and isinstance(payload.get("events"), list):
        events_payload = payload["events"]
    else:
        return json_error("Expected a JSON array or an object with an events array.")

    if not events_payload:
        return json_error("At least one event is required.")

    if len(events_payload) > 500:
        return json_error("Too many events in one batch.")

    events_to_create: list[CalibrationEvent] = []
    for event_payload in events_payload:
        if not isinstance(event_payload, dict):
            return json_error("Every event must be a JSON object.")

        required_fields = [
            "id",
            "timestamp",
            "questionID",
            "prompt",
            "category",
            "difficultyTier",
            "roundDurationSeconds",
            "revealedAnswerIndices",
            "totalAnswers",
            "pointsAwarded",
            "remainingTimeAtFinish",
        ]
        missing_fields = [field for field in required_fields if field not in event_payload]
        if missing_fields:
            return json_error(
                f"Calibration event missing required fields: {', '.join(missing_fields)}"
            )

        event_uuid = parse_uuid(event_payload.get("id"))
        client_timestamp = parse_datetime(event_payload.get("timestamp"))
        if event_uuid is None or client_timestamp is None:
            return json_error("Calibration event has invalid id or timestamp.")

        source_indices = event_payload.get("revealedAnswerIndices")
        if not isinstance(source_indices, list) or not all(
            isinstance(index, int) for index in source_indices
        ):
            return json_error("revealedAnswerIndices must be an array of integers.")

        events_to_create.append(
            CalibrationEvent(
                event_id=event_uuid,
                client_timestamp=client_timestamp,
                pack_id=event_payload.get("packID") or None,
                pack_title=event_payload.get("packTitle") or None,
                pack_version=event_payload.get("packVersion") or None,
                question_id=str(event_payload["questionID"]).strip(),
                prompt=str(event_payload["prompt"]).strip(),
                category=str(event_payload["category"]).strip(),
                difficulty_tier=str(event_payload["difficultyTier"]).strip(),
                finish_reason=event_payload.get("finishReason") or None,
                round_duration_seconds=max(int(event_payload["roundDurationSeconds"]), 1),
                revealed_answer_indices=source_indices,
                total_answers=max(int(event_payload["totalAnswers"]), 0),
                points_awarded=max(int(event_payload["pointsAwarded"]), 0),
                remaining_time_at_finish=float(event_payload["remainingTimeAtFinish"]),
                time_to_first_reveal=(
                    float(event_payload["timeToFirstReveal"])
                    if event_payload.get("timeToFirstReveal") is not None
                    else None
                ),
            )
        )

    CalibrationEvent.objects.bulk_create(events_to_create, ignore_conflicts=True)
    return HttpResponse(status=204)
