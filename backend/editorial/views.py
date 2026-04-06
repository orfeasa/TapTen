from __future__ import annotations

import csv

from django.contrib import messages
from django.contrib.auth import get_user_model
from django.contrib.auth.decorators import login_required
from django.db.models import Avg, Count, Max, Min, Q
from django.http import HttpRequest, HttpResponse
from django.shortcuts import get_object_or_404, redirect, render
from django.utils import timezone
from django.views.decorators.http import require_GET, require_POST

from .forms import (
    AssignmentForm,
    CommentForm,
    ReviewerCreateForm,
    ReviewerPasswordResetForm,
    ReviewStateForm,
)
from .models import (
    CalibrationEvent,
    FeedbackReport,
    QuestionCatalog,
    QuestionReviewDecision,
    QuestionReviewState,
)
from .permissions import staff_required

User = get_user_model()


def build_filters(request: HttpRequest) -> dict[str, str]:
    return {
        "workflow_state": request.GET.get("workflow_state", "").strip(),
        "pack_id": request.GET.get("pack_id", "").strip(),
        "category": request.GET.get("category", "").strip(),
        "difficulty_tier": request.GET.get("difficulty_tier", "").strip(),
        "assigned": request.GET.get("assigned", "").strip(),
    }


def build_report_groups(limit: int = 200) -> list[dict]:
    report_groups = (
        FeedbackReport.objects.values("question_id", "pack_id", "pack_version", "reason")
        .annotate(
            report_count=Count("id"),
            first_seen_at=Min("received_at"),
            last_seen_at=Max("received_at"),
        )
        .order_by("-last_seen_at")
    )
    latest_notes = {
        (
            report.question_id,
            report.pack_id,
            report.pack_version,
            report.reason,
        ): report.note
        for report in FeedbackReport.objects.order_by(
            "question_id",
            "pack_id",
            "pack_version",
            "reason",
            "-received_at",
        )
    }

    grouped_rows = []
    for group in report_groups[:limit]:
        grouped_rows.append(
            {
                **group,
                "latest_note": latest_notes.get(
                    (
                        group["question_id"],
                        group["pack_id"],
                        group["pack_version"],
                        group["reason"],
                    ),
                    "",
                ),
            }
        )

    return grouped_rows


def build_insight_rows(limit: int = 200) -> list[dict]:
    insight_rows = []
    telemetry_groups = (
        CalibrationEvent.objects.values("question_id", "pack_id", "pack_version", "prompt")
        .annotate(
            sample_count=Count("id"),
            average_points_awarded=Avg("points_awarded"),
            skip_count=Count("id", filter=Q(finish_reason="skipped")),
        )
        .order_by("-sample_count")
    )

    report_counts = {
        (
            row["question_id"],
            row["pack_id"],
            row["pack_version"],
        ): row["report_count"]
        for row in FeedbackReport.objects.values("question_id", "pack_id", "pack_version").annotate(
            report_count=Count("id")
        )
    }

    for row in telemetry_groups[:limit]:
        matching_events = CalibrationEvent.objects.filter(
            question_id=row["question_id"],
            pack_id=row["pack_id"],
            pack_version=row["pack_version"],
        )
        sample_count = row["sample_count"] or 0
        average_revealed_answers = 0.0
        if sample_count:
            average_revealed_answers = sum(
                len(event.revealed_answer_indices) for event in matching_events
            ) / sample_count
        skip_rate = (row["skip_count"] or 0) / sample_count if sample_count else 0.0

        insight_rows.append(
            {
                "question_id": row["question_id"],
                "pack_id": row["pack_id"],
                "pack_version": row["pack_version"],
                "prompt": row["prompt"],
                "sample_count": sample_count,
                "average_completion_ratio": average_revealed_answers / 10 if sample_count else 0,
                "average_points_awarded": row["average_points_awarded"] or 0,
                "skip_rate": skip_rate,
                "report_count": report_counts.get(
                    (row["question_id"], row["pack_id"], row["pack_version"]),
                    0,
                ),
            }
        )

    return insight_rows


@login_required
@require_GET
def dashboard(request: HttpRequest) -> HttpResponse:
    current_questions = QuestionCatalog.objects.filter(is_current=True)
    review_states = QuestionReviewState.objects.select_related("question_catalog")

    context = {
        "current_question_count": current_questions.count(),
        "pack_count": current_questions.values("pack_id").distinct().count(),
        "draft_count": review_states.filter(
            workflow_state__in=[
                QuestionReviewState.WorkflowState.PROPOSED,
                QuestionReviewState.WorkflowState.IN_REVIEW,
            ]
        ).count(),
        "changes_requested_count": review_states.filter(
            workflow_state=QuestionReviewState.WorkflowState.CHANGES_REQUESTED
        ).count(),
        "approved_count": review_states.filter(
            workflow_state__in=[
                QuestionReviewState.WorkflowState.APPROVED,
                QuestionReviewState.WorkflowState.PLAYTESTED,
            ]
        ).count(),
        "report_count": FeedbackReport.objects.count(),
        "calibration_event_count": CalibrationEvent.objects.count(),
    }
    return render(request, "editorial/dashboard.html", context)


@login_required
@require_GET
def question_list(request: HttpRequest) -> HttpResponse:
    filters = build_filters(request)
    questions = QuestionCatalog.objects.filter(is_current=True).select_related(
        "review_state",
        "review_state__assigned_user",
    )

    if filters["workflow_state"]:
        questions = questions.filter(review_state__workflow_state=filters["workflow_state"])
    if filters["pack_id"]:
        questions = questions.filter(pack_id__icontains=filters["pack_id"])
    if filters["category"]:
        questions = questions.filter(category__icontains=filters["category"])
    if filters["difficulty_tier"]:
        questions = questions.filter(difficulty_tier=filters["difficulty_tier"])
    if filters["assigned"] == "assigned":
        questions = questions.filter(review_state__assigned_user__isnull=False)
    elif filters["assigned"] == "unassigned":
        questions = questions.filter(
            Q(review_state__assigned_user__isnull=True) | Q(review_state__isnull=True)
        )

    context = {
        "questions": questions[:200],
        "filters": filters,
        "workflow_choices": QuestionReviewState.WorkflowState.choices,
        "difficulty_choices": QuestionCatalog.DifficultyTier.choices,
    }
    return render(request, "editorial/question_list.html", context)


@login_required
@require_GET
def question_detail(request: HttpRequest, question_id: int) -> HttpResponse:
    question = get_object_or_404(
        QuestionCatalog.objects.filter(is_current=True).select_related(
            "review_state",
            "review_state__assigned_user",
            "review_state__approved_by_user",
        ),
        pk=question_id,
    )
    review_state, _created = QuestionReviewState.objects.get_or_create(question_catalog=question)

    telemetry_base = CalibrationEvent.objects.filter(
        question_id=question.question_id,
        pack_id=question.pack_id,
        pack_version=question.pack_version or None,
    )
    sample_count = telemetry_base.count()
    average_points_awarded = (
        telemetry_base.aggregate(value=Avg("points_awarded"))["value"] or 0
    )
    average_revealed_answers = 0.0
    if sample_count:
        average_revealed_answers = sum(
            len(event.revealed_answer_indices) for event in telemetry_base
        ) / sample_count
    skip_rate = 0.0
    if sample_count:
        skipped_rounds = telemetry_base.filter(finish_reason="skipped").count()
        skip_rate = skipped_rounds / sample_count

    report_count = FeedbackReport.objects.filter(
        question_id=question.question_id,
        pack_id=question.pack_id,
        pack_version=question.pack_version or None,
    ).count()

    context = {
        "question": question,
        "review_state": review_state,
        "review_form": ReviewStateForm(instance=review_state),
        "assignment_form": AssignmentForm(instance=review_state),
        "comment_form": CommentForm(),
        "decisions": question.review_decisions.select_related("user")[:20],
        "comments": question.review_comments.select_related("user")[:20],
        "report_count": report_count,
        "telemetry": {
            "sample_count": sample_count,
            "average_completion_ratio": average_revealed_answers / 10 if sample_count else 0,
            "average_points_awarded": average_points_awarded,
            "skip_rate": skip_rate,
        },
    }
    return render(request, "editorial/question_detail.html", context)


@login_required
@require_POST
def question_review(request: HttpRequest, question_id: int) -> HttpResponse:
    question = get_object_or_404(QuestionCatalog, pk=question_id)
    review_state, _created = QuestionReviewState.objects.get_or_create(question_catalog=question)

    form = ReviewStateForm(request.POST, instance=review_state)
    if not form.is_valid():
        messages.error(request, "Review update could not be saved.")
        return redirect("editorial:question-detail", question_id=question_id)

    review_state = form.save(commit=False)
    notes = form.cleaned_data.get("notes", "").strip()

    if review_state.workflow_state == QuestionReviewState.WorkflowState.APPROVED:
        review_state.approved_by_user = request.user
        review_state.approved_at = timezone.now()
    elif review_state.workflow_state == QuestionReviewState.WorkflowState.PLAYTESTED:
        if review_state.approved_by_user is None:
            review_state.approved_by_user = request.user
        if review_state.approved_at is None:
            review_state.approved_at = timezone.now()
        review_state.playtested_at = timezone.now()
    elif review_state.workflow_state == QuestionReviewState.WorkflowState.REFRESH_NEEDED:
        review_state.refresh_needed_at = timezone.now()

    review_state.save()

    decision_map = {
        QuestionReviewState.WorkflowState.APPROVED: QuestionReviewDecision.Decision.APPROVE,
        QuestionReviewState.WorkflowState.CHANGES_REQUESTED: QuestionReviewDecision.Decision.REQUEST_CHANGES,
        QuestionReviewState.WorkflowState.PLAYTESTED: QuestionReviewDecision.Decision.MARK_PLAYTESTED,
        QuestionReviewState.WorkflowState.REFRESH_NEEDED: QuestionReviewDecision.Decision.MARK_REFRESH_NEEDED,
    }
    decision = decision_map.get(review_state.workflow_state)
    if decision:
        QuestionReviewDecision.objects.create(
            question_catalog=question,
            user=request.user,
            decision=decision,
            notes=notes,
        )

    messages.success(request, "Review state updated.")
    return redirect("editorial:question-detail", question_id=question_id)


@login_required
@require_POST
def question_assign(request: HttpRequest, question_id: int) -> HttpResponse:
    question = get_object_or_404(QuestionCatalog, pk=question_id)
    review_state, _created = QuestionReviewState.objects.get_or_create(question_catalog=question)
    form = AssignmentForm(request.POST, instance=review_state)
    if form.is_valid():
        form.save()
        messages.success(request, "Reviewer assignment updated.")
    else:
        messages.error(request, "Reviewer assignment could not be updated.")
    return redirect("editorial:question-detail", question_id=question_id)


@login_required
@require_POST
def question_comment(request: HttpRequest, question_id: int) -> HttpResponse:
    question = get_object_or_404(QuestionCatalog, pk=question_id)
    form = CommentForm(request.POST)
    if form.is_valid():
        comment = form.save(commit=False)
        comment.question_catalog = question
        comment.user = request.user
        comment.save()
        messages.success(request, "Comment added.")
    else:
        messages.error(request, "Comment could not be added.")
    return redirect("editorial:question-detail", question_id=question_id)


@login_required
@require_GET
def report_list(request: HttpRequest) -> HttpResponse:
    return render(
        request,
        "editorial/report_list.html",
        {"report_groups": build_report_groups()},
    )


@login_required
@require_GET
def insights(request: HttpRequest) -> HttpResponse:
    return render(request, "editorial/insights.html", {"insight_rows": build_insight_rows()})


@login_required
@require_GET
def pack_list(request: HttpRequest) -> HttpResponse:
    pack_rows = (
        QuestionCatalog.objects.filter(is_current=True)
        .values("pack_id", "pack_title", "pack_version")
        .annotate(question_count=Count("id"))
        .order_by("pack_id")
    )
    return render(request, "editorial/pack_list.html", {"pack_rows": pack_rows})


@staff_required
@require_GET
def reviewer_list(request: HttpRequest) -> HttpResponse:
    context = {
        "reviewers": User.objects.order_by("username"),
        "create_form": ReviewerCreateForm(),
    }
    return render(request, "editorial/reviewer_list.html", context)


@staff_required
@require_POST
def reviewer_create(request: HttpRequest) -> HttpResponse:
    form = ReviewerCreateForm(request.POST)
    if form.is_valid():
        reviewer = form.save(commit=False)
        reviewer.is_staff = form.cleaned_data["is_staff"]
        reviewer.save()
        messages.success(request, f"Reviewer {reviewer.username} created.")
    else:
        messages.error(request, "Reviewer could not be created.")
    return redirect("editorial:reviewer-list")


@staff_required
@require_POST
def reviewer_toggle_active(request: HttpRequest, user_id: int) -> HttpResponse:
    reviewer = get_object_or_404(User, pk=user_id)
    reviewer.is_active = not reviewer.is_active
    reviewer.save(update_fields=["is_active"])
    messages.success(
        request,
        f"Reviewer {reviewer.username} is now {'active' if reviewer.is_active else 'disabled'}.",
    )
    return redirect("editorial:reviewer-list")


@staff_required
@require_POST
def reviewer_reset_password(request: HttpRequest, user_id: int) -> HttpResponse:
    reviewer = get_object_or_404(User, pk=user_id)
    form = ReviewerPasswordResetForm(request.POST)
    if form.is_valid():
        reviewer.set_password(form.cleaned_data["password1"])
        reviewer.save(update_fields=["password"])
        messages.success(request, f"Password updated for {reviewer.username}.")
    else:
        messages.error(request, "Password reset failed.")
    return redirect("editorial:reviewer-list")


def csv_response(filename: str) -> HttpResponse:
    response = HttpResponse(content_type="text/csv")
    response["Content-Disposition"] = f'attachment; filename="{filename}"'
    return response


@staff_required
@require_GET
def export_reviews_csv(request: HttpRequest) -> HttpResponse:
    response = csv_response("tapten-reviews.csv")
    writer = csv.writer(response)
    writer.writerow(
        [
            "pack_id",
            "pack_version",
            "question_id",
            "prompt",
            "workflow_state",
            "assigned_user",
            "approved_by_user",
            "approved_at",
            "requires_second_approval",
            "updated_at",
        ]
    )

    for state in QuestionReviewState.objects.select_related(
        "question_catalog",
        "assigned_user",
        "approved_by_user",
    ).order_by("question_catalog__pack_id", "question_catalog__question_id"):
        writer.writerow(
            [
                state.question_catalog.pack_id,
                state.question_catalog.pack_version,
                state.question_catalog.question_id,
                state.question_catalog.prompt,
                state.workflow_state,
                state.assigned_user.username if state.assigned_user else "",
                state.approved_by_user.username if state.approved_by_user else "",
                state.approved_at.isoformat() if state.approved_at else "",
                "yes" if state.requires_second_approval else "no",
                state.updated_at.isoformat(),
            ]
        )

    return response


@staff_required
@require_GET
def export_reports_csv(request: HttpRequest) -> HttpResponse:
    response = csv_response("tapten-reports.csv")
    writer = csv.writer(response)
    writer.writerow(
        [
            "question_id",
            "pack_id",
            "pack_version",
            "reason",
            "report_count",
            "first_seen_at",
            "last_seen_at",
            "latest_note",
        ]
    )

    for group in build_report_groups(limit=10_000):
        writer.writerow(
            [
                group["question_id"],
                group["pack_id"] or "",
                group["pack_version"] or "",
                group["reason"],
                group["report_count"],
                group["first_seen_at"].isoformat() if group["first_seen_at"] else "",
                group["last_seen_at"].isoformat() if group["last_seen_at"] else "",
                group["latest_note"],
            ]
        )

    return response


@staff_required
@require_GET
def export_insights_csv(request: HttpRequest) -> HttpResponse:
    response = csv_response("tapten-insights.csv")
    writer = csv.writer(response)
    writer.writerow(
        [
            "question_id",
            "pack_id",
            "pack_version",
            "prompt",
            "sample_count",
            "average_completion_ratio",
            "average_points_awarded",
            "skip_rate",
            "report_count",
        ]
    )
    for row in build_insight_rows(limit=10_000):
        writer.writerow(
            [
                row["question_id"],
                row["pack_id"] or "",
                row["pack_version"] or "",
                row["prompt"],
                row["sample_count"],
                f'{row["average_completion_ratio"]:.4f}',
                f'{row["average_points_awarded"]:.4f}',
                f'{row["skip_rate"]:.4f}',
                row["report_count"],
            ]
        )
    return response
