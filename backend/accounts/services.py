"""
accounts/services.py — Business Logic Layer

All lockout logic lives here, not in views.
This matches the logic from the original firebase_service.dart.
"""
from django.utils import timezone
from datetime import timedelta


class AccountLockedException(Exception):
    """Raised when a login attempt is made on a locked account."""
    def __init__(self, remaining_minutes: int):
        self.remaining_minutes = remaining_minutes
        super().__init__(f'Account locked for {remaining_minutes} more minute(s).')


class InvalidCredentialsException(Exception):
    """Raised when email/password don't match."""
    pass


class EmailNotVerifiedException(Exception):
    """Raised when a user's email hasn't been OTP-verified yet."""
    pass


class UserService:
    """
    Service layer for user-related business logic.

    All methods operate on a CustomUser instance received from the view.
    Views remain thin — they only parse requests and format responses.
    """

    @staticmethod
    def check_lockout(user):
        """
        Raise AccountLockedException if the account is locked.
        Auto-clears expired lockouts (side-effect intentional).
        """
        if user.is_locked_out():
            raise AccountLockedException(user.remaining_lockout_minutes())

    @staticmethod
    def handle_failed_login(user):
        """
        Increment failed login counter and lock the account if threshold reached.
        Mirrors firebase_service.dart:incrementLoginAttempts().
        """
        user.login_attempts += 1

        if user.login_attempts >= user.MAX_LOGIN_ATTEMPTS:
            user.locked_until = timezone.now() + timedelta(minutes=user.LOCKOUT_MINUTES)

        user.save(update_fields=['login_attempts', 'locked_until'])

    @staticmethod
    def reset_login_attempts(user):
        """
        Reset failed attempts on successful login.
        Mirrors firebase_service.dart:resetLoginAttempts().
        """
        if user.login_attempts > 0 or user.locked_until is not None:
            user.login_attempts = 0
            user.locked_until = None
            user.save(update_fields=['login_attempts', 'locked_until'])
