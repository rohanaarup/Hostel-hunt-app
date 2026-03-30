"""
accounts/views.py — Authentication API Views

All views are thin: they parse requests, delegate to services/serializers,
and format responses. Business logic lives in services.py.

Endpoints:
    POST /api/auth/register/       — Create account (requires OTP verified)
    POST /api/auth/login/          — Login → returns JWT tokens
    POST /api/auth/logout/         — Blacklist refresh token
    POST /api/auth/token/refresh/  — Get new access token
    GET  /api/auth/me/             — Authenticated user profile
"""
from rest_framework import status
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.views import TokenRefreshView
from rest_framework_simplejwt.exceptions import TokenError
from django.contrib.auth import get_user_model

from .serializers import RegisterSerializer, LoginSerializer, UserProfileSerializer
from .services import UserService, AccountLockedException

User = get_user_model()


def _success(data=None, message='', status_code=status.HTTP_200_OK):
    """Consistent success envelope for all responses."""
    return Response({'success': True, 'message': message, 'data': data}, status=status_code)


class RegisterView(APIView):
    """
    POST /api/auth/register/

    Creates a new user. Email must have been verified via OTP first.
    Body: { full_name, email, password, password_confirm }
    """
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = RegisterSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()

        # Issue JWT tokens immediately so the user is logged in after signup
        refresh = RefreshToken.for_user(user)
        return _success(
            data={
                'user': UserProfileSerializer(user).data,
                'tokens': {
                    'access': str(refresh.access_token),
                    'refresh': str(refresh),
                },
            },
            message='Account created successfully!',
            status_code=status.HTTP_201_CREATED,
        )


class LoginView(APIView):
    """
    POST /api/auth/login/

    Validates credentials with lockout protection.
    Returns JWT access + refresh tokens on success.
    Body: { email, password }
    """
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = LoginSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        email = serializer.validated_data['email']
        password = serializer.validated_data['password']

        # Look up user
        try:
            user = User.objects.get(email=email)
        except User.DoesNotExist:
            return Response(
                {'success': False, 'message': 'User not registered.'},
                status=status.HTTP_401_UNAUTHORIZED,
            )

        # Check lockout before password verification (avoid timing oracle)
        try:
            UserService.check_lockout(user)
        except AccountLockedException as e:
            return Response(
                {
                    'success': False,
                    'message': f'Account locked. Try again in {e.remaining_minutes} minute(s).',
                },
                status=status.HTTP_403_FORBIDDEN,
            )

        # Verify password
        if not user.check_password(password):
            UserService.handle_failed_login(user)

            # Check if the failed attempt just caused a lockout
            if user.is_locked_out():
                return Response(
                    {'success': False, 'message': 'Too many failed attempts. Account locked for 15 minutes.'},
                    status=status.HTTP_403_FORBIDDEN,
                )

            remaining = user.MAX_LOGIN_ATTEMPTS - user.login_attempts
            return Response(
                {'success': False, 'message': f'Incorrect password. {remaining} attempt(s) remaining.'},
                status=status.HTTP_401_UNAUTHORIZED,
            )

        # Verify email
        if not user.email_verified:
            return Response(
                {'success': False, 'message': 'Email not verified. Please complete OTP verification.'},
                status=status.HTTP_403_FORBIDDEN,
            )

        # Success
        UserService.reset_login_attempts(user)

        refresh = RefreshToken.for_user(user)
        return _success(
            data={
                'user': UserProfileSerializer(user).data,
                'tokens': {
                    'access': str(refresh.access_token),
                    'refresh': str(refresh),
                },
            },
            message='Login successful!',
        )


class LogoutView(APIView):
    """
    POST /api/auth/logout/

    Blacklists the provided refresh token, invalidating the session.
    Body: { refresh }
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        refresh_token = request.data.get('refresh')
        if not refresh_token:
            return Response(
                {'success': False, 'message': 'Refresh token is required.'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        try:
            token = RefreshToken(refresh_token)
            token.blacklist()
            return _success(message='Logged out successfully.')
        except TokenError:
            return Response(
                {'success': False, 'message': 'Invalid or expired token.'},
                status=status.HTTP_400_BAD_REQUEST,
            )


class MeView(APIView):
    """
    GET /api/auth/me/

    Returns the authenticated user's profile.
    Requires: Authorization: Bearer <access_token>
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        return _success(
            data=UserProfileSerializer(request.user).data,
            message='Profile retrieved successfully.',
        )
