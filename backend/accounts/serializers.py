"""
accounts/serializers.py — Request/Response Serializers

Keeps validation logic out of views. Each serializer is responsible
for one specific operation to keep things focused and testable.
"""
from rest_framework import serializers
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from django.contrib.auth import get_user_model
from django.contrib.auth.password_validation import validate_password
from otp_auth.models import OTPRecord

User = get_user_model()


# ---------------------------------------------------------------------------
# JWT Custom Claims
# ---------------------------------------------------------------------------
class CustomTokenObtainPairSerializer(TokenObtainPairSerializer):
    """Add extra claims to the JWT payload."""

    @classmethod
    def get_token(cls, user):
        token = super().get_token(user)
        token['email'] = user.email
        token['full_name'] = user.full_name
        return token


# ---------------------------------------------------------------------------
# Registration
# ---------------------------------------------------------------------------
class RegisterSerializer(serializers.Serializer):
    """
    Validates and creates a new user.

    Prerequisites enforced here:
    1. Email must not already be registered.
    2. A verified OTPRecord for this email must exist.
    3. Password meets strength requirements + both fields match.
    """
    full_name = serializers.CharField(max_length=150, min_length=2)
    email = serializers.EmailField()
    password = serializers.CharField(
        write_only=True,
        min_length=8,
        style={'input_type': 'password'},
    )
    password_confirm = serializers.CharField(
        write_only=True,
        style={'input_type': 'password'},
    )

    def validate_email(self, value):
        email = value.strip().lower()
        if User.objects.filter(email=email).exists():
            raise serializers.ValidationError('Email already registered. Please login instead.')
        return email

    def validate_password(self, value):
        validate_password(value)  # Runs Django's built-in validators
        return value

    def validate(self, attrs):
        if attrs['password'] != attrs['password_confirm']:
            raise serializers.ValidationError({'password_confirm': 'Passwords do not match.'})

        # Require OTP verification before account creation
        email = attrs['email'].strip().lower()
        otp_record = OTPRecord.objects.filter(email=email, verified=True).first()
        if not otp_record:
            raise serializers.ValidationError(
                {'email': 'Email not verified. Please complete OTP verification first.'}
            )

        return attrs

    def create(self, validated_data):
        validated_data.pop('password_confirm')
        user = User.objects.create_user(
            email=validated_data['email'],
            full_name=validated_data['full_name'],
            password=validated_data['password'],
            email_verified=True,
        )
        # Clean up the OTP record after successful registration
        OTPRecord.objects.filter(email=user.email).delete()
        return user


# ---------------------------------------------------------------------------
# User Profile (read-only)
# ---------------------------------------------------------------------------
class UserProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'email', 'full_name', 'email_verified', 'created_at']
        read_only_fields = fields


# ---------------------------------------------------------------------------
# Login (thin — actual auth is handled by simplejwt + our view)
# ---------------------------------------------------------------------------
class LoginSerializer(serializers.Serializer):
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True, style={'input_type': 'password'})

    def validate_email(self, value):
        return value.strip().lower()
