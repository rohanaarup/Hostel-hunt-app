from rest_framework import status
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.shortcuts import get_object_or_404

from .models import FavoriteHostel, FavoriteRoom
from .serializers import FavoriteHostelSerializer, FavoriteRoomSerializer
from hostels.models import Hostel
from rooms.models import Room


class FavoriteHostelListView(APIView):
    """
    List all favorited hostels for the authenticated user.
    GET /api/favorites/hostels/
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        favorites = FavoriteHostel.objects.filter(user=request.user)
        serializer = FavoriteHostelSerializer(favorites, many=True)
        return Response({
            'success': True,
            'count': favorites.count(),
            'data': serializer.data
        })


class FavoriteHostelToggleView(APIView):
    """
    Add or remove a hostel from favorites.
    POST /api/favorites/hostels/{hostel_id}/toggle/
    """
    permission_classes = [IsAuthenticated]

    def post(self, request, hostel_id):
        hostel = get_object_or_404(Hostel, id=hostel_id)
        
        favorite, created = FavoriteHostel.objects.get_or_create(
            user=request.user,
            hostel=hostel
        )

        if not created:
            # If it already existed, remove it
            favorite.delete()
            return Response({
                'success': True,
                'message': f'Removed {hostel.name} from favorites',
                'favorited': False
            })
        else:
            # If we just created it
            return Response({
                'success': True,
                'message': f'Added {hostel.name} to favorites',
                'favorited': True
            }, status=status.HTTP_201_CREATED)


class FavoriteRoomListView(APIView):
    """
    List all favorited rooms for the authenticated user.
    GET /api/favorites/rooms/
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        favorites = FavoriteRoom.objects.filter(user=request.user)
        serializer = FavoriteRoomSerializer(favorites, many=True)
        return Response({
            'success': True,
            'count': favorites.count(),
            'data': serializer.data
        })


class FavoriteRoomToggleView(APIView):
    """
    Add or remove a room from favorites.
    POST /api/favorites/rooms/{room_id}/toggle/
    """
    permission_classes = [IsAuthenticated]

    def post(self, request, room_id):
        room = get_object_or_404(Room, id=room_id)
        
        favorite, created = FavoriteRoom.objects.get_or_create(
            user=request.user,
            room=room
        )

        if not created:
            # If it already existed, remove it
            favorite.delete()
            return Response({
                'success': True,
                'message': f'Removed {room.room_name} from favorites',
                'favorited': False
            })
        else:
            # If we just created it
            return Response({
                'success': True,
                'message': f'Added {room.room_name} to favorites',
                'favorited': True
            }, status=status.HTTP_201_CREATED)
