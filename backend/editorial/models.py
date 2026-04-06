from __future__ import annotations

from django.conf import settings
from django.db import models


class QuestionCatalog(models.Model):
    class DifficultyTier(models.TextChoices):
        EASY = "easy", "Easy"
        MEDIUM = "medium", "Medium"
        HARD = "hard", "Hard"

    class ValidationStyle(models.TextChoices):
        FACTUAL = "factual", "Factual"
        EDITORIAL = "editorial", "Editorial"
        HUMOROUS = "humorous", "Humorous"

    class Quality(models.TextChoices):
        DRAFT = "draft", "Draft"
        REVIEWED = "reviewed", "Reviewed"
        PLAYTESTED = "playtested", "Playtested"
        NEEDS_REFRESH = "needs-refresh", "Needs Refresh"

    pack_id = models.CharField(max_length=200)
    pack_title = models.CharField(max_length=200)
    pack_version = models.CharField(max_length=100, blank=True, default="")
    question_id = models.CharField(max_length=200)
    prompt = models.TextField()
    category = models.CharField(max_length=200)
    difficulty_tier = models.CharField(max_length=16, choices=DifficultyTier.choices)
    difficulty_score = models.PositiveSmallIntegerField()
    validation_style = models.CharField(max_length=16, choices=ValidationStyle.choices)
    source_url = models.URLField()
    content_type = models.CharField(max_length=100, blank=True, default="")
    quality = models.CharField(
        max_length=32,
        choices=Quality.choices,
        default=Quality.DRAFT,
    )
    difficulty_notes = models.TextField(blank=True, default="")
    editorial_notes = models.TextField(blank=True, default="")
    answers_json = models.JSONField(default=list)
    content_hash = models.CharField(max_length=64)
    imported_at = models.DateTimeField(auto_now_add=True)
    is_current = models.BooleanField(default=True)

    class Meta:
        ordering = ["pack_id", "question_id"]
        constraints = [
            models.UniqueConstraint(
                fields=["pack_id", "question_id", "pack_version", "content_hash"],
                name="unique_question_catalog_revision",
            )
        ]
        indexes = [
            models.Index(fields=["pack_id", "question_id"]),
            models.Index(fields=["is_current", "quality"]),
            models.Index(fields=["category", "difficulty_tier"]),
        ]

    def __str__(self) -> str:
        return f"{self.pack_id}:{self.question_id}"


class QuestionReviewState(models.Model):
    class WorkflowState(models.TextChoices):
        PROPOSED = "proposed", "Proposed"
        IN_REVIEW = "in-review", "In Review"
        CHANGES_REQUESTED = "changes-requested", "Changes Requested"
        APPROVED = "approved", "Approved"
        PLAYTESTED = "playtested", "Playtested"
        SHIPPED = "shipped", "Shipped"
        REFRESH_NEEDED = "refresh-needed", "Refresh Needed"

    question_catalog = models.OneToOneField(
        QuestionCatalog,
        on_delete=models.CASCADE,
        related_name="review_state",
    )
    workflow_state = models.CharField(
        max_length=32,
        choices=WorkflowState.choices,
        default=WorkflowState.PROPOSED,
    )
    assigned_user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="assigned_question_reviews",
    )
    requires_second_approval = models.BooleanField(default=False)
    approved_by_user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="approved_question_reviews",
    )
    approved_at = models.DateTimeField(null=True, blank=True)
    playtested_at = models.DateTimeField(null=True, blank=True)
    refresh_needed_at = models.DateTimeField(null=True, blank=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["question_catalog__pack_id", "question_catalog__question_id"]

    def __str__(self) -> str:
        return f"{self.question_catalog} [{self.workflow_state}]"


class QuestionReviewDecision(models.Model):
    class Decision(models.TextChoices):
        APPROVE = "approve", "Approve"
        REQUEST_CHANGES = "request-changes", "Request Changes"
        MARK_REFRESH_NEEDED = "mark-refresh-needed", "Mark Refresh Needed"
        MARK_PLAYTESTED = "mark-playtested", "Mark Playtested"

    question_catalog = models.ForeignKey(
        QuestionCatalog,
        on_delete=models.CASCADE,
        related_name="review_decisions",
    )
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="question_review_decisions",
    )
    decision = models.CharField(max_length=32, choices=Decision.choices)
    notes = models.TextField(blank=True, default="")
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]


class QuestionReviewComment(models.Model):
    class CommentType(models.TextChoices):
        GENERAL = "general", "General"
        EDITORIAL = "editorial", "Editorial"
        PLAYTEST = "playtest", "Playtest"

    question_catalog = models.ForeignKey(
        QuestionCatalog,
        on_delete=models.CASCADE,
        related_name="review_comments",
    )
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="question_review_comments",
    )
    comment_type = models.CharField(
        max_length=32,
        choices=CommentType.choices,
        default=CommentType.GENERAL,
    )
    body = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]


class FeedbackReport(models.Model):
    report_id = models.UUIDField(unique=True)
    received_at = models.DateTimeField(auto_now_add=True)
    submitted_at = models.DateTimeField()
    reason = models.CharField(max_length=64)
    note = models.TextField(blank=True, default="")
    app_version = models.CharField(max_length=64)
    pack_id = models.CharField(max_length=200, null=True, blank=True)
    pack_title = models.CharField(max_length=200, null=True, blank=True)
    pack_version = models.CharField(max_length=100, null=True, blank=True)
    question_id = models.CharField(max_length=200)
    prompt = models.TextField()
    category = models.CharField(max_length=200)
    difficulty_tier = models.CharField(max_length=16)
    validation_style = models.CharField(max_length=16)
    source_url = models.URLField()

    class Meta:
        ordering = ["-received_at"]
        indexes = [
            models.Index(fields=["question_id", "pack_id", "pack_version"]),
            models.Index(fields=["reason", "received_at"]),
        ]


class CalibrationEvent(models.Model):
    event_id = models.UUIDField(unique=True)
    received_at = models.DateTimeField(auto_now_add=True)
    client_timestamp = models.DateTimeField()
    pack_id = models.CharField(max_length=200, null=True, blank=True)
    pack_title = models.CharField(max_length=200, null=True, blank=True)
    pack_version = models.CharField(max_length=100, null=True, blank=True)
    question_id = models.CharField(max_length=200)
    prompt = models.TextField()
    category = models.CharField(max_length=200)
    difficulty_tier = models.CharField(max_length=16)
    finish_reason = models.CharField(max_length=32, null=True, blank=True)
    round_duration_seconds = models.PositiveIntegerField()
    revealed_answer_indices = models.JSONField(default=list)
    total_answers = models.PositiveSmallIntegerField()
    points_awarded = models.PositiveSmallIntegerField()
    remaining_time_at_finish = models.FloatField()
    time_to_first_reveal = models.FloatField(null=True, blank=True)

    class Meta:
        ordering = ["-client_timestamp"]
        indexes = [
            models.Index(fields=["question_id", "pack_id", "pack_version"]),
            models.Index(fields=["difficulty_tier", "client_timestamp"]),
        ]
