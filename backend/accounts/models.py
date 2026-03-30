"""
accounts/models.py — Custom User Model

Using email as the primary identifier (no username).
Includes login lockout tracking directly on the model.
"""
from django.contrib.auth.models import AbstractBaseUser, BaseUserManager, PermissionsMixin
from django.db import models
from django.utils import timezone


class CustomUserManager(BaseUserManager):
    """Manager that handles email-based user creation."""

    def create_user(self, email, full_name, password=None, **extra_fields):
        if not email:
            raise ValueError('Email address is required.')
        email = self.normalize_email(email)
        user = self.model(email=email, full_name=full_name, **extra_fields)
        user.set_password(password)  # Django's PBKDF2 hashing
        user.save(using=self._db)
        return user

    def create_superuser(self, email, full_name, password, **extra_fields):
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)
        extra_fields.setdefault('is_active', True)
        extra_fields.setdefault('email_verified', True)

        if extra_fields.get('is_staff') is not True:
            raise ValueError('Superuser must have is_staff=True.')
        if extra_fields.get('is_superuser') is not True:
            raise ValueError('Superuser must have is_superuser=True.')

        return self.create_user(email, full_name, password, **extra_fields)


class CustomUser(AbstractBaseUser, PermissionsMixin):
    """
    Custom user model using email as the login identifier.

    Security fields:
    - email_verified: must be True (via OTP) before login is allowed
    - login_attempts: incremented on each failed login
    - locked_until: set when login_attempts >= MAX_LOGIN_ATTEMPTS
    """

    # Constants matching the original Dart firebase_service.dart
    MAX_LOGIN_ATTEMPTS = 5
    LOCKOUT_MINUTES = 15

    email = models.EmailField(
        unique=True,
        db_index=True,
        help_text='Primary login identifier.',
    )
    full_name = models.CharField(max_length=150)
    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)
    email_verified = models.BooleanField(
        default=False,
        help_text='Set to True after OTP email verification.',
    )

    # Login lockout
    login_attempts = models.PositiveSmallIntegerField(default=0)
    locked_until = models.DateTimeField(null=True, blank=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    objects = CustomUserManager()

    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['full_name']

    class Meta:
        verbose_name = 'User'
        verbose_name_plural = 'Users'
        ordering = ['-created_at']

    def __str__(self):
        return f'{self.full_name} <{self.email}>'

    def is_locked_out(self):
        """Check if the account is currently locked."""
        if self.locked_until is None:
            return False
        if timezone.now() < self.locked_until:
            return True
        # Lock expired — clear it
        self.login_attempts = 0
        self.locked_until = None
        self.save(update_fields=['login_attempts', 'locked_until'])
        return False

    def remaining_lockout_minutes(self):
        """Minutes remaining in lockout (0 if not locked)."""
        if not self.is_locked_out():
            return 0
        delta = self.locked_until - timezone.now()
        return max(1, int(delta.total_seconds() / 60) + 1)
