"""
otp_auth/services.py — OTP Business Logic

Handles generation, rate limiting, email dispatch, and verification.
Replaces: OtpService + FirebaseService OTP methods from Dart.

Security improvements:
- OTP stored as SHA-256 hash (never plaintext in DB)
- Rate limiting enforced server-side
- Email sent via Django's email backend (configurable: console for dev, SMTP for prod)
"""
import secrets
from datetime import timedelta

from django.core.mail import send_mail
from django.utils import timezone
from django.conf import settings

from .models import OTPRecord


class OTPRateLimitException(Exception):
    """Raised when the client is sending OTPs too quickly."""
    def __init__(self, reason: str):
        self.reason = reason
        super().__init__(reason)


class OTPVerificationException(Exception):
    """Raised when OTP verification fails for any reason."""
    def __init__(self, message: str, remaining_attempts: int = 0):
        self.remaining_attempts = remaining_attempts
        super().__init__(message)


class OTPService:
    """
    Service layer for all OTP operations.

    Methods mirror firebase_service.dart + otp_service.dart behavior,
    but with server-side enforcement and hashed storage.
    """

    @staticmethod
    def _generate_otp() -> str:
        """Cryptographically secure 6-digit OTP (no leading zeros stripped)."""
        return str(secrets.randbelow(900000) + 100000)

    @staticmethod
    def _check_rate_limit(existing, email):
        # type: (OTPRecord, str) -> None
        """
        Enforce:
        1. 60-second cooldown between sends
        2. Max 5 sends per hour
        """
        if existing is None:
            return

        now = timezone.now()
        seconds_since_last = (now - existing.created_at).total_seconds()

        if seconds_since_last < OTPRecord.COOLDOWN_SECONDS:
            remaining = int(OTPRecord.COOLDOWN_SECONDS - seconds_since_last)
            raise OTPRateLimitException(
                f'Please wait {remaining} second(s) before requesting a new OTP.'
            )

        # Hourly send limit
        if existing.first_send_at:
            hours_since_first = (now - existing.first_send_at).total_seconds() / 3600
            if hours_since_first < 1 and existing.send_count >= OTPRecord.MAX_SENDS_PER_HOUR:
                raise OTPRateLimitException(
                    'Maximum OTP requests exceeded. Please try again in an hour.'
                )

    @staticmethod
    def _send_email(recipient_email: str, otp_code: str) -> None:
        """Send OTP email via configured Django email backend."""
        subject = 'Your OTP for ROHII Hostel Hunt'
        html_message = _build_email_html(otp_code)
        plain_message = f'Your ROHII Hostel Hunt OTP is: {otp_code}. Valid for 5 minutes.'

        send_mail(
            subject=subject,
            message=plain_message,
            html_message=html_message,
            from_email=settings.DEFAULT_FROM_EMAIL,
            recipient_list=[recipient_email],
            fail_silently=False,
        )

    @classmethod
    def generate_and_send(cls, email: str) -> None:
        """
        Generate a new OTP, enforce rate limits, send email, and persist record.
        Mirrors: OtpService.generateOTP() + OtpService.sendOTPEmail() + FirebaseService.storeOTPRecord()
        """
        email = email.strip().lower()
        existing = OTPRecord.objects.filter(email=email).first()

        cls._check_rate_limit(existing, email)

        now = timezone.now()
        otp_code = cls._generate_otp()
        otp_hash = OTPRecord.hash_otp(otp_code)

        # Calculate new send_count and first_send_at for rate limiting
        send_count = 1
        first_send_at = now

        if existing and existing.first_send_at:
            hours_since_first = (now - existing.first_send_at).total_seconds() / 3600
            if hours_since_first < 1:
                send_count = existing.send_count + 1
                first_send_at = existing.first_send_at

        # Upsert the OTP record (delete old, create new keeps clean single-row-per-email)
        OTPRecord.objects.filter(email=email).delete()
        OTPRecord.objects.create(
            email=email,
            otp_hash=otp_hash,
            expires_at=now + timedelta(minutes=OTPRecord.VALIDITY_MINUTES),
            attempt_count=0,
            verified=False,
            send_count=send_count,
            first_send_at=first_send_at,
        )

        # Send after persisting so the record exists even if email fails
        cls._send_email(email, otp_code)

    @staticmethod
    def verify(email: str, otp_code: str) -> None:
        """
        Verify an OTP code. Raises OTPVerificationException on any failure.
        On success, marks the record as verified (but does NOT delete it —
        registration will clean it up after user creation).

        Mirrors: FirebaseService.verifyOTP()
        """
        email = email.strip().lower()
        record = OTPRecord.objects.filter(email=email).first()

        if record is None:
            raise OTPVerificationException('No OTP found. Please request a new one.')

        if record.verified:
            raise OTPVerificationException('OTP already used. Please request a new one.')

        if record.is_expired():
            raise OTPVerificationException('OTP expired. Please request a new one.')

        if record.is_attempts_exceeded():
            raise OTPVerificationException(
                'Maximum verification attempts exceeded. Please request a new OTP.'
            )

        if not record.verify_code(otp_code):
            record.attempt_count += 1
            record.save(update_fields=['attempt_count'])
            remaining = OTPRecord.MAX_ATTEMPTS - record.attempt_count
            raise OTPVerificationException(
                f'Incorrect OTP. {remaining} attempt(s) remaining.',
                remaining_attempts=remaining,
            )

        # Mark verified
        record.verified = True
        record.save(update_fields=['verified'])


# ---------------------------------------------------------------------------
# Email Template
# ---------------------------------------------------------------------------
def _build_email_html(otp: str) -> str:
    """HTML email template matching the original Dart otp_service.dart design."""
    return f"""<!DOCTYPE html>
<html>
<head>
  <style>
    body {{ font-family: Arial, sans-serif; background-color: #f4f4f4; padding: 20px; }}
    .container {{ background-color: white; border-radius: 10px; padding: 30px;
                 max-width: 500px; margin: 0 auto; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }}
    .header {{ color: #ff6b35; text-align: center; margin-bottom: 20px; }}
    .otp-box {{ background-color: #fff3e0; border: 2px solid #ff6b35; border-radius: 8px;
               padding: 20px; text-align: center; margin: 20px 0; }}
    .otp-code {{ font-size: 32px; font-weight: bold; color: #ff6b35; letter-spacing: 5px; }}
    .footer {{ color: #666; font-size: 12px; text-align: center; margin-top: 20px; }}
  </style>
</head>
<body>
  <div class="container">
    <h1 class="header">🏠 ROHII Hostel Hunt</h1>
    <p>Welcome! Use the following One-Time Password (OTP) to verify your email address:</p>
    <div class="otp-box">
      <div class="otp-code">{otp}</div>
    </div>
    <p><strong>⏰ This OTP is valid for 5 minutes only.</strong></p>
    <p>If you didn't request this OTP, please ignore this email.</p>
    <div class="footer">
      <p>© 2026 ROHII Hostel Hunt. All rights reserved.</p>
      <p>This is an automated email. Please do not reply.</p>
    </div>
  </div>
</body>
</html>"""
