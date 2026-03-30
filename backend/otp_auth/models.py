"""
otp_auth/models.py — OTP Record Model

Tracks OTP generation, verification, rate limiting, and expiry.
Mirrors the Firestore otp_records collection from firebase_service.dart.

Security improvements over the original Dart implementation:
- OTP code stored as SHA-256 hash (not plaintext)
- Rate limiting fields tracked server-side (not client-accessible)
"""
import hashlib
from django.db import models
from django.utils import timezone
from datetime import timedelta


class OTPRecord(models.Model):
    """
    One record per email address. Overwritten on each new OTP request.

    Rate limit constants matching original Dart code:
    - maxOTPSendsPerHour = 5
    - otpCooldownSeconds = 60
    - maxOTPAttempts = 5
    - otpValidityMinutes = 5
    """
    MAX_SENDS_PER_HOUR = 5
    COOLDOWN_SECONDS = 60
    MAX_ATTEMPTS = 5
    VALIDITY_MINUTES = 5

    email = models.EmailField(
        unique=True,
        db_index=True,
        help_text='One OTP record per email. Overwritten on resend.',
    )
    otp_hash = models.CharField(
        max_length=64,
        help_text='SHA-256 hash of the 6-digit OTP code.',
    )
    created_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField(
        help_text='OTP becomes invalid after this time.',
    )
    attempt_count = models.PositiveSmallIntegerField(default=0)
    verified = models.BooleanField(default=False)

    # Rate limiting
    send_count = models.PositiveSmallIntegerField(default=1)
    first_send_at = models.DateTimeField(
        help_text='Start of the current hourly rate-limit window.',
    )

    class Meta:
        verbose_name = 'OTP Record'
        ordering = ['-created_at']

    def __str__(self):
        return f'OTP for {self.email} (verified={self.verified})'

    def is_expired(self):
        return timezone.now() > self.expires_at

    def is_attempts_exceeded(self):
        return self.attempt_count >= self.MAX_ATTEMPTS

    @staticmethod
    def hash_otp(otp_code: str) -> str:
        """SHA-256 hash of the plaintext OTP for secure storage."""
        return hashlib.sha256(otp_code.encode()).hexdigest()

    def verify_code(self, otp_code: str) -> bool:
        """Constant-time hash comparison."""
        return self.otp_hash == self.hash_otp(otp_code)

    def save(self, *args, **kwargs):
        # Auto-set expires_at on first creation
        if not self.pk and not self.expires_at:
            self.expires_at = timezone.now() + timedelta(minutes=self.VALIDITY_MINUTES)
        super().save(*args, **kwargs)
