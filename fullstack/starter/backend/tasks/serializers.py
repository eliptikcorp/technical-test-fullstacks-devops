from rest_framework import serializers
from .models import Task, Event

class TaskSerializer(serializers.ModelSerializer):
    priority = serializers.ReadOnlyField()
    class Meta:
        model = Task
        fields = '__all__'

class EventSerializer(serializers.ModelSerializer):
    class Meta:
        model = Event
        fields = '__all__'
