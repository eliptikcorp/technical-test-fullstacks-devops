from rest_framework import viewsets, permissions
from .models import Task, Event
from .serializers import TaskSerializer, EventSerializer
from rest_framework.decorators import action
from rest_framework.response import Response

class TaskViewSet(viewsets.ModelViewSet):
    queryset = Task.objects.all()
    serializer_class = TaskSerializer

    @action(detail=True, methods=['post'], permission_classes=[permissions.IsAdminUser])
    def force_close(self, request, pk=None):
        task = self.get_object()
        task.status = 'DONE'
        task.save()
        return Response({'status':'forced closed'})

class EventViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Event.objects.all()
    serializer_class = EventSerializer
