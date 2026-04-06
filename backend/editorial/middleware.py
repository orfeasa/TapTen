from __future__ import annotations

from django.conf import settings
from django.http import Http404


class HostRoutingMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        host = request.get_host().split(":")[0].lower()

        if (
            settings.TAPTEN_API_HOST
            and request.path.startswith("/tapten/")
            and host != settings.TAPTEN_API_HOST
            and host not in {"127.0.0.1", "localhost"}
        ):
            raise Http404("Unknown route for this host.")

        if (
            settings.TAPTEN_REVIEW_HOST
            and request.path.startswith("/internal/")
            and host != settings.TAPTEN_REVIEW_HOST
            and host not in {"127.0.0.1", "localhost"}
        ):
            raise Http404("Unknown route for this host.")

        return self.get_response(request)
