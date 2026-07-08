from rest_framework import serializers
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from django.contrib.auth import get_user_model
from django.contrib.auth.password_validation import validate_password
from otp_auth.models import OTPRecord

User = get_user_model()


class CustomTokenObtainPairSerializer(TokenObtainPairSerializer):
    @classmethod
    def get_token(cls, user):
        token = super().get_token(user)
        token['email'] = user.email
        token['display_name'] = user.display_name
        return token


class RegisterSerializer(serializers.Serializer):
    display_name = serializers.CharField(max_length=150, min_length=2)
    email = serializers.EmailField()
    role = serializers.ChoiceField(choices=['student', 'owner'], default='student')
    signup_source = serializers.ChoiceField(choices=['admin_panel', 'app'], default='app')
    
    password = serializers.CharField(write_only=True, min_length=8, style={'input_type': 'password'})
    password_confirm = serializers.CharField(write_only=True, style={'input_type': 'password'})

    def validate_email(self, value):
        email = value.strip().lower()
        if User.objects.filter(email=email).exists():
            raise serializers.ValidationError('Email is already registered.')
        return email

    def validate_password(self, value):
        validate_password(value)
        return value

    def validate(self, attrs):
        if attrs['password'] != attrs['password_confirm']:
            raise serializers.ValidationError({'password_confirm': 'Passwords do not match.'})

        email = attrs['email'].strip().lower()
        otp_record = OTPRecord.objects.filter(identifier=email, purpose='registration', is_used=True).first()
        
        if not otp_record:
            raise serializers.ValidationError({'email': 'Email not verified. Please complete OTP verification first.'})

        return attrs

    def create(self, validated_data):
        validated_data.pop('password_confirm')
        
        user = User.objects.create_user(
            role=validated_data['role'],
            signup_source=validated_data['signup_source'],
            email=validated_data['email'],
            display_name=validated_data['display_name'],
            password=validated_data['password'],
            is_verified=True,
        )
        
        OTPRecord.objects.filter(identifier=user.email).delete()
        
        return user


class UserProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['owner_id', 'email', 'display_name', 'phone_number', 'is_verified', 'created_at', 'role']
        read_only_fields = fields


class LoginSerializer(serializers.Serializer):
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True, style={'input_type': 'password'})

    def validate_email(self, value):
        return value.strip().lower()
