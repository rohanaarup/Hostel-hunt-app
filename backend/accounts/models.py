"""
accounts/models.py — Owner Model

Matches Railway Postgres `owners` table schema exactly.
Uses UUID primary key (owner_id) and app_label='owners' to align
with Railway's django_content_type and migration history.
"""
import uuid
from django.db import models
from django.contrib.auth.models import AbstractBaseUser, BaseUserManager, PermissionsMixin


class OwnerManager(BaseUserManager):
    def create_user(self, email, display_name, password=None, **extra_fields):
        if not email:
            raise ValueError("Email is required")

        email = self.normalize_email(email)
        user = self.model(email=email, display_name=display_name, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, email, display_name, password, **extra_fields):
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)
        extra_fields.setdefault('is_active', True)
        extra_fields.setdefault('is_verified', True)

        if extra_fields.get('is_staff') is not True:
            raise ValueError('Superuser must have is_staff=True.')
        if extra_fields.get('is_superuser') is not True:
            raise ValueError('Superuser must have is_superuser=True.')

        return self.create_user(email, display_name, password, **extra_fields)


class Owner(AbstractBaseUser, PermissionsMixin):
    """
    Custom user model matching Railway's `owners` table.

    PK: owner_id (UUID)
    Table: owners
    Content type: owners.owner
    """
    owner_id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    email = models.EmailField(max_length=254, unique=True, null=True, blank=True)
    phone_number = models.CharField(max_length=20, unique=True, null=True, blank=True)
    display_name = models.CharField(max_length=150)
    is_verified = models.BooleanField(default=False)
    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)
    profile_photo = models.ImageField(upload_to='profile_photos/', max_length=100, null=True, blank=True)

    ROLE_CHOICES = (
        ('student', 'Student'),
        ('owner', 'Owner'),
    )
    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default='student')

    SIGNUP_SOURCE_CHOICES = (
        ('admin_panel', 'Admin Panel'),
        ('app', 'App'),
    )
    signup_source = models.CharField(max_length=20, choices=SIGNUP_SOURCE_CHOICES, default='app')

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    # Override M2M tables to match Railway's existing table names and column names
    groups = models.ManyToManyField(
        'auth.Group',
        blank=True,
        related_name='owner_set',
        related_query_name='owner',
        verbose_name='groups',
        help_text='The groups this user belongs to.',
        db_table='owners_groups',
    )
    user_permissions = models.ManyToManyField(
        'auth.Permission',
        blank=True,
        related_name='owner_set',
        related_query_name='owner',
        verbose_name='user permissions',
        help_text='Specific permissions for this user.',
        db_table='owners_user_permissions',
    )

    objects = OwnerManager()

    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['display_name']

    class Meta:
        app_label = 'owners'
        db_table = 'owners'
        verbose_name = 'Owner'
        verbose_name_plural = 'Owners'
        ordering = ['-created_at']

    def __str__(self):
        return f'{self.display_name} <{self.email}>'

class AppUser(Owner):
    """Proxy model to separate App Users (students) in Django Admin"""
    class Meta:
        proxy = True
        app_label = 'owners'
        verbose_name = 'App User'
        verbose_name_plural = 'App Users'

class HostelOwner(Owner):
    """Proxy model to separate Hostel Owners in Django Admin"""
    class Meta:
        proxy = True
        app_label = 'owners'
        verbose_name = 'Hostel Owner'
        verbose_name_plural = 'Hostel Owners'