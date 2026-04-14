from django.http import HttpResponseForbidden

from app import models


def superuser_required(view_func):
    """
    Decorator to ensure that the user is a superuser.
    """

    def _wrapped_view(request, *args, **kwargs):
        if not request.user.is_superuser:
            return HttpResponseForbidden("You are not authorized to view this page.")
        return view_func(request, *args, **kwargs)

    return _wrapped_view


def self_required(view_func):
    """
    Decorator to ensure that the user is accessing itself.
    """

    def _wrapped_view(request, *args, **kwargs):
        if request.user.is_superuser:
            pass
        elif request.user.is_active:
            name = request.user.first_name + " " + request.user.last_name
            record = models.Attendance.objects.all()
            confirm = False
            for data in record:
                if name == data.name:
                    confirm = True
                    break
            if not confirm:
                return HttpResponseForbidden("Please contact admin to fix your account.")
        return view_func(request, *args, **kwargs)

    return _wrapped_view
