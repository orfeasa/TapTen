from django.contrib.auth.views import LoginView, LogoutView
from django.urls import path

from . import views

urlpatterns = [
    path("login/", LoginView.as_view(template_name="editorial/login.html"), name="login"),
    path("logout/", LogoutView.as_view(), name="logout"),
    path("", views.dashboard, name="dashboard"),
    path("questions/", views.question_list, name="question-list"),
    path("questions/<int:question_id>/", views.question_detail, name="question-detail"),
    path("questions/<int:question_id>/review/", views.question_review, name="question-review"),
    path("questions/<int:question_id>/assign/", views.question_assign, name="question-assign"),
    path("questions/<int:question_id>/comments/", views.question_comment, name="question-comment"),
    path("reports/", views.report_list, name="report-list"),
    path("insights/", views.insights, name="insights"),
    path("packs/", views.pack_list, name="pack-list"),
    path("reviewers/", views.reviewer_list, name="reviewer-list"),
    path("reviewers/create/", views.reviewer_create, name="reviewer-create"),
    path(
        "reviewers/<int:user_id>/toggle-active/",
        views.reviewer_toggle_active,
        name="reviewer-toggle-active",
    ),
    path(
        "reviewers/<int:user_id>/reset-password/",
        views.reviewer_reset_password,
        name="reviewer-reset-password",
    ),
    path("export/reviews.csv", views.export_reviews_csv, name="export-reviews"),
    path("export/reports.csv", views.export_reports_csv, name="export-reports"),
    path("export/insights.csv", views.export_insights_csv, name="export-insights"),
]
