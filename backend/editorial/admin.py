from django.contrib import admin

from .models import (
    CalibrationEvent,
    FeedbackReport,
    QuestionCatalog,
    QuestionReviewComment,
    QuestionReviewDecision,
    QuestionReviewState,
)

admin.site.site_header = "Tap Ten Editorial Admin"
admin.site.site_title = "Tap Ten Admin"
admin.site.index_title = "Editorial Operations"


@admin.register(QuestionCatalog)
class QuestionCatalogAdmin(admin.ModelAdmin):
    list_display = (
        "question_id",
        "pack_id",
        "pack_version",
        "category",
        "difficulty_tier",
        "quality",
        "is_current",
    )
    list_filter = ("pack_id", "difficulty_tier", "quality", "is_current")
    search_fields = ("question_id", "prompt", "category", "pack_id")


@admin.register(QuestionReviewState)
class QuestionReviewStateAdmin(admin.ModelAdmin):
    list_display = (
        "question_catalog",
        "workflow_state",
        "assigned_user",
        "requires_second_approval",
        "approved_at",
    )
    list_filter = ("workflow_state", "requires_second_approval")
    search_fields = ("question_catalog__question_id", "question_catalog__prompt")


@admin.register(QuestionReviewDecision)
class QuestionReviewDecisionAdmin(admin.ModelAdmin):
    list_display = ("question_catalog", "decision", "user", "created_at")
    list_filter = ("decision",)
    search_fields = ("question_catalog__question_id", "question_catalog__prompt", "notes")


@admin.register(QuestionReviewComment)
class QuestionReviewCommentAdmin(admin.ModelAdmin):
    list_display = ("question_catalog", "comment_type", "user", "created_at")
    list_filter = ("comment_type",)
    search_fields = ("question_catalog__question_id", "body")


@admin.register(FeedbackReport)
class FeedbackReportAdmin(admin.ModelAdmin):
    list_display = ("question_id", "reason", "pack_id", "pack_version", "received_at")
    list_filter = ("reason", "difficulty_tier", "validation_style")
    search_fields = ("question_id", "prompt", "category", "note")


@admin.register(CalibrationEvent)
class CalibrationEventAdmin(admin.ModelAdmin):
    list_display = ("question_id", "pack_id", "pack_version", "difficulty_tier", "received_at")
    list_filter = ("difficulty_tier", "finish_reason")
    search_fields = ("question_id", "prompt", "category")
