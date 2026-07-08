from rest_framework.permissions import BasePermission


class IsOwner(BasePermission):
    """
    Allows access only to users with owner role.
    """

    def has_permission(self, request, view):
        return (
            request.user.is_authenticated and
            request.user.role == 'owner'
        )