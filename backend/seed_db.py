#!/usr/bin/env python
"""
Data Seeding Script — Create test data for Hostel Hunt

This script populates the PostgreSQL database with realistic sample data
for development and testing purposes.
"""
import os
import sys
import django

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'rohii_backend.settings')
sys.path.insert(0, os.path.dirname(__file__))
django.setup()

from decimal import Decimal
from accounts.models import CustomUser
from hostels.models import Hostel, HostelImage
from rooms.models import Room
from bookings.models import Booking
from reviews.models import Review
from datetime import date
import random

print("=" * 80)
print("SEEDING TEST DATA INTO PostgreSQL")
print("=" * 80)

# Clear existing data (be careful!)
print("\n[1] Preparing database...")
# Note: In production, never do this! This is for dev/test only
Room.objects.all().delete()
Hostel.objects.all().delete()
Booking.objects.all().delete()
Review.objects.all().delete()
print("  ✓ Cleared old hostels, rooms, bookings, reviews")

# Get or create a hostel owner
owner_email = "owner@rohii.com"
owner, created = CustomUser.objects.get_or_create(
    email=owner_email,
    defaults={
        'full_name': 'Hostel Owner',
        'role': 'owner',
        'email_verified': True,
        'is_active': True,
    }
)
if created:
    owner.set_password('OwnerPassword123!')
    owner.save()
    print(f"  ✓ Created hostel owner: {owner.email}")
else:
    print(f"  ✓ Using existing owner: {owner.email}")

# Sample hostels data
hostels_data = [
    {
        'name': 'Aspire Hostel',
        'description': 'Budget-friendly hostel with modern facilities. WiFi, AC, and daily meals included.',
        'address': '123 JP Nagar, IT Hub Road',
        'city': 'Bangalore',
        'state': 'Karnataka',
        'pincode': '560078',
        'hostel_type': 'mixed',
        'price_per_month': Decimal('8000.00'),
        'security_deposit': Decimal('5000.00'),
        'amenities': 'WiFi,AC,Meals,Parking,Laundry,Kitchen',
        'total_rooms': 20,
        'available_rooms': 8,
        'is_available': True,
        'latitude': Decimal('12.935142'),
        'longitude': Decimal('77.627953'),
        'contact_phone': '+91-9876543210',
        'contact_email': 'info@aspirehostel.com',
    },
    {
        'name': 'Horizon Boys Hostel',
        'description': 'Premium boys hostel in heart of the city. Spacious rooms with attached bathrooms.',
        'address': '456 Koramangala, 4th Block',
        'city': 'Bangalore',
        'state': 'Karnataka',
        'pincode': '560034',
        'hostel_type': 'boys',
        'price_per_month': Decimal('7500.00'),
        'security_deposit': Decimal('4500.00'),
        'amenities': 'WiFi,AC,Gym,Parking,Study Room,Hot Water',
        'total_rooms': 15,
        'available_rooms': 3,
        'is_available': True,
        'latitude': Decimal('12.935445'),
        'longitude': Decimal('77.620896'),
        'contact_phone': '+91-9876543211',
        'contact_email': 'contact@horizonhostel.com',
    },
    {
        'name': 'Serenity Girls Hostel',
        'description': 'Safe and comfortable girls hostel with 24/7 security and warden support.',
        'address': '789 Indira Nagar, Main Road',
        'city': 'Bangalore',
        'state': 'Karnataka',
        'pincode': '560038',
        'hostel_type': 'girls',
        'price_per_month': Decimal('9000.00'),
        'security_deposit': Decimal('6000.00'),
        'amenities': 'WiFi,AC,Meals,Laundry,Security,Common Hall',
        'total_rooms': 25,
        'available_rooms': 12,
        'is_available': True,
        'latitude': Decimal('12.972442'),
        'longitude': Decimal('77.641603'),
        'contact_phone': '+91-9876543212',
        'contact_email': 'info@serenitygl.com',
    },
    {
        'name': 'Urban Living Co-ed',
        'description': 'Modern co-ed hostel with rooftop lounge and co-working space.',
        'address': '321 Whitefield, Tech Park',
        'city': 'Bangalore',
        'state': 'Karnataka',
        'pincode': '560066',
        'hostel_type': 'mixed',
        'price_per_month': Decimal('10000.00'),
        'security_deposit': Decimal('7000.00'),
        'amenities': 'WiFi,AC,Meals,Parking,CoWorking,Entertainment',
        'total_rooms': 30,
        'available_rooms': 5,
        'is_available': True,
        'latitude': Decimal('12.955833'),
        'longitude': Decimal('77.727000'),
        'contact_phone': '+91-9876543213',
        'contact_email': 'info@urbanlivingco.com',
    },
]

print("\n[2] Creating Hostels...")
created_hostels = []
for data in hostels_data:
    hostel = Hostel.objects.create(
        owner=owner,
        **data
    )
    created_hostels.append(hostel)
    print(f"  ✓ Created: {hostel.name} ({hostel.city}) - {hostel.get_hostel_type_display()}")

# Create rooms for each hostel
print("\n[3] Creating Rooms...")
room_types = [
    {'name': 'Single Room', 'capacity': 1, 'price': Decimal('8000.00')},
    {'name': 'Double Room', 'capacity': 2, 'price': Decimal('6000.00')},
    {'name': 'Triple Room', 'capacity': 3, 'price': Decimal('5000.00')},
    {'name': 'Dormitory (4-bed)', 'capacity': 4, 'price': Decimal('4000.00')},
]

rooms_created = 0
for hostel in created_hostels:
    for i, room_type in enumerate(room_types, 1):
        room = Room.objects.create(
            hostel=hostel,
            room_number=f"{hostel.id:02d}-{i:02d}",
            room_name=room_type['name'],
            description=f"{room_type['name']} in {hostel.name}. Clean, spacious, with good ventilation.",
            capacity=room_type['capacity'],
            available_beds=random.randint(0, room_type['capacity']),
            price_per_month=room_type['price'],
            is_available=True,
        )
        rooms_created += 1
    print(f"  ✓ {hostel.name}: Created {len(room_types)} rooms ({rooms_created} total)")

# Create test bookings
print("\n[4] Creating Sample Bookings...")
students = CustomUser.objects.filter(role='student')[:2]
for i, student in enumerate(students):
    for hostel in created_hostels[:2]:
        rooms = hostel.rooms.all()
        if rooms.exists():
            booking = Booking.objects.create(
                user=student,
                hostel=hostel,
                room=rooms.first(),
                check_in=date(2024, 7, 1),
                check_out=date(2024, 8, 1),
                status='confirmed' if i == 0 else 'pending',
                total_amount=Decimal('8000.00'),
                notes='Test booking for development',
            )
            print(f"  ✓ Booking #{booking.id} - {student.email} @ {hostel.name}")

# Create reviews
print("\n[5] Creating Sample Reviews...")
for student in students[:1]:
    for hostel in created_hostels[:2]:
        review = Review.objects.create(
            user=student,
            hostel=hostel,
            rating=random.randint(3, 5),
            comment='Great hostel with excellent facilities and friendly staff!',
        )
        print(f"  ✓ Review #{review.id} - {student.email} → {hostel.name} ({review.rating}★)")

# Summary
print("\n" + "=" * 80)
print("DATA SEEDING SUMMARY")
print("=" * 80)
print(f"\nHostels Created:    {Hostel.objects.count()}")
print(f"Rooms Created:      {Room.objects.count()}")
print(f"Bookings Created:   {Booking.objects.count()}")
print(f"Reviews Created:    {Review.objects.count()}")
print(f"Users (total):      {CustomUser.objects.count()}")

print("\n✓ Test data successfully seeded into PostgreSQL!")
print("=" * 80)
