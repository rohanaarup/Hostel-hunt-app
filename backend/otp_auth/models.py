"""
otp_auth/models.py — OTP Record Model

Matches Railway Postgres `otp_records` table schema exactly.
Uses app_label='owners' to match Railway's content type `owners.otprecord`.
"""
import hashlib
import uuid
from django.db import models
from django.utils import timezone
from datetime import timedelta


class OTPRecord(models.Model):
    """
    OTP verification record matching Railway's `otp_records` table.

    Table: otp_records
    Content type: owners.otprecord
    """
    # Rate limit constants (enforced in service layer)
    MAX_SENDS_PER_HOUR = 5
    COOLDOWN_SECONDS = 60
    MAX_ATTEMPTS = 5
    VALIDITY_MINUTES = 5

    identifier = models.CharField(max_length=150)
    otp_code = models.CharField(max_length=128)  # Stores SHA-256 hash of the 6-digit code
    purpose = models.CharField(max_length=20, default='registration')
    is_used = models.BooleanField(default=False)
    is_verified = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField()
    verification_token = models.UUIDField(null=True, blank=True)

    class Meta:
        app_label = 'owners'
        db_table = 'otp_records'
        verbose_name = 'OTP Record'
        verbose_name_plural = 'OTP Records'

    def is_expired(self):
        return timezone.now() > self.expires_at

    @staticmethod
    def hash_otp(otp_code: str) -> str:
        return hashlib.sha256(otp_code.encode()).hexdigest()

    def verify_code(self, otp_code: str) -> bool:
        return self.otp_code == self.hash_otp(otp_code)

    def save(self, *args, **kwargs):
        if not self.pk and not self.expires_at:
            self.expires_at = timezone.now() + timedelta(minutes=self.VALIDITY_MINUTES)
        super().save(*args, **kwargs)

    def __str__(self):
        return f'OTP for {self.identifier} ({self.purpose})'
