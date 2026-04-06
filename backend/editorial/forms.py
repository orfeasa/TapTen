from django import forms
from django.contrib.auth import get_user_model
from django.contrib.auth.forms import UserCreationForm

from .models import QuestionReviewComment, QuestionReviewState

User = get_user_model()


class ReviewStateForm(forms.ModelForm):
    notes = forms.CharField(
        required=False,
        widget=forms.Textarea(attrs={"rows": 4}),
        help_text="Optional decision notes stored in review history.",
    )

    class Meta:
        model = QuestionReviewState
        fields = ["workflow_state", "requires_second_approval"]


class AssignmentForm(forms.ModelForm):
    class Meta:
        model = QuestionReviewState
        fields = ["assigned_user"]

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.fields["assigned_user"].queryset = User.objects.filter(is_active=True).order_by(
            "username"
        )
        self.fields["assigned_user"].required = False
        self.fields["assigned_user"].empty_label = "Unassigned"


class CommentForm(forms.ModelForm):
    class Meta:
        model = QuestionReviewComment
        fields = ["body"]
        widgets = {
            "body": forms.Textarea(attrs={"rows": 4}),
        }


class ReviewerCreateForm(UserCreationForm):
    is_staff = forms.BooleanField(
        required=False,
        help_text="Allow this reviewer to manage reviewer accounts.",
    )

    class Meta(UserCreationForm.Meta):
        model = User
        fields = ["username", "email", "is_staff"]


class ReviewerPasswordResetForm(forms.Form):
    password1 = forms.CharField(widget=forms.PasswordInput, label="New password")
    password2 = forms.CharField(widget=forms.PasswordInput, label="Confirm password")

    def clean(self):
        cleaned_data = super().clean()
        password1 = cleaned_data.get("password1")
        password2 = cleaned_data.get("password2")
        if password1 and password2 and password1 != password2:
            raise forms.ValidationError("Passwords do not match.")
        return cleaned_data
