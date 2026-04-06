from __future__ import annotations

from functools import wraps

from django.contrib import messages
from django.contrib.auth.decorators import login_required
from django.http import HttpRequest, HttpResponse
from django.shortcuts import redirect


def staff_required(view_func):
    @login_required
    @wraps(view_func)
    def wrapped(request: HttpRequest, *args, **kwargs) -> HttpResponse:
        if not request.user.is_staff:
            messages.error(request, "Staff access is required for that page.")
            return redirect("editorial:dashboard")
        return view_func(request, *args, **kwargs)

    return wrapped
