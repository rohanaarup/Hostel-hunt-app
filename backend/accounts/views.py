from rest_framework import status
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.exceptions import TokenError
from django.contrib.auth import get_user_model

from .serializers import RegisterSerializer, LoginSerializer, UserProfileSerializer

User = get_user_model()

def _success(data=None, message='', status_code=status.HTTP_200_OK):
    return Response({'success': True, 'message': message, 'data': data}, status=status_code)


class RegisterView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = RegisterSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        user = serializer.save()
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
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = LoginSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        email = serializer.validated_data['email']
        password = serializer.validated_data['password']

        try:
            user = User.objects.get(email=email)
        except User.DoesNotExist:
            return Response({'success': False, 'message': 'User not registered.'}, status=status.HTTP_401_UNAUTHORIZED)

        if not user.check_password(password):
            return Response({'success': False, 'message': 'Incorrect password.'}, status=status.HTTP_401_UNAUTHORIZED)

        if not user.is_verified:
            return Response({'success': False, 'message': 'Email not verified. Please complete OTP verification.'}, status=status.HTTP_403_FORBIDDEN)

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
    permission_classes = [IsAuthenticated]

    def post(self, request):
        refresh_token = request.data.get('refresh')
        if not refresh_token:
            return Response({'success': False, 'message': 'Refresh token is required.'}, status=status.HTTP_400_BAD_REQUEST)
            
        try:
            token = RefreshToken(refresh_token)
            token.blacklist()
            return _success(message='Logged out successfully.')
        except TokenError:
            return Response({'success': False, 'message': 'Invalid or expired token.'}, status=status.HTTP_400_BAD_REQUEST)


class MeView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        return _success(
            data=UserProfileSerializer(request.user).data,
            message='Profile retrieved successfully.',
        )
