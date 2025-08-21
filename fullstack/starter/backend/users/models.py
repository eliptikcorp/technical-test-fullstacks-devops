from django.contrib.auth.models import AbstractUser
from django.db import models

class User(AbstractUser):
    ROLE_CHOICES = [
        ('User', 'User'),
        ('Lead', 'Lead'),
        ('Manager', 'Manager')
    ]
    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default='User')
    manager = models.ForeignKey('self', null=True, blank=True, on_delete=models.SET_NULL, related_name='team')
    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)
