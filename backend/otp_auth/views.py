"""
otp_auth/views.py — OTP API Views

Endpoints:
    POST /api/otp/send/    — Generate OTP and send via email
    POST /api/otp/verify/  — Verify OTP code

Both endpoints are public (AllowAny) — user doesn't have a JWT yet.
All business logic is delegated to OTPService.
"""
from rest_framework import status
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import AllowAny
from django.contrib.auth import get_user_model

from .serializers import SendOTPSerializer, VerifyOTPSerializer
from .services import OTPService, OTPRateLimitException, OTPVerificationException

User = get_user_model()


class SendOTPView(APIView):
    """
    POST /api/otp/send/

    Generates a 6-digit OTP, stores a hashed record, and sends it via email.
    Rate limited: 60s cooldown, max 5 per hour.

    Body: { email, full_name }
    Response: { success, message }
    """
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = SendOTPSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        email = serializer.validated_data['email']

        # Reject if email already has an active, verified account
        if User.objects.filter(email=email, email_verified=True).exists():
            return Response(
                {'success': False, 'message': 'Email already registered. Please login instead.'},
                status=status.HTTP_409_CONFLICT,
            )

        try:
            OTPService.generate_and_send(email)
            return Response(
                {'success': True, 'message': 'OTP sent to your email. Valid for 5 minutes.'},
                status=status.HTTP_200_OK,
            )
        except OTPRateLimitException as e:
            return Response(
                {'success': False, 'message': e.reason},
                status=status.HTTP_429_TOO_MANY_REQUESTS,
            )
        except Exception:
            return Response(
                {'success': False, 'message': 'Failed to send OTP. Please try again.'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
            )


class VerifyOTPView(APIView):
    """
    POST /api/otp/verify/

    Verifies the 6-digit OTP. On success, marks the email as verified.
    Registration can proceed only after this step.

    Body: { email, otp }
    Response: { success, message }
    """
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = VerifyOTPSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        email = serializer.validated_data['email']
        otp_code = serializer.validated_data['otp']

        try:
            OTPService.verify(email, otp_code)
            return Response(
                {'success': True, 'message': 'Email verified successfully!'},
                status=status.HTTP_200_OK,
            )
        except OTPVerificationException as e:
            return Response(
                {
                    'success': False,
                    'message': str(e),
                    'remaining_attempts': e.remaining_attempts,
                },
                status=status.HTTP_400_BAD_REQUEST,
            )
