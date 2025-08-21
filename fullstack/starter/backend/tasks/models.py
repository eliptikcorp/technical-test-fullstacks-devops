from django.db import models
from users.models import User

class Task(models.Model):
    STATUS_CHOICES = [
        ('TODO', 'To Do'),
        ('IN_PROGRESS', 'In Progress'),
        ('DONE', 'Done'),
    ]

    title = models.CharField(max_length=255)
    description = models.TextField(blank=True)
    base_priority = models.IntegerField(default=1)
    estimated_hours = models.FloatField(null=True, blank=True)
    due_date = models.DateField(null=True, blank=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='TODO')
    assigned_to = models.ForeignKey(User, null=True, blank=True, on_delete=models.SET_NULL, related_name='tasks')
    dependencies = models.ManyToManyField('self', symmetrical=False, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    @property
    def urgency_score(self):
        score = 0
        if self.due_date:
            from datetime import date
            days_left = (self.due_date - date.today()).days
            score += max(0, 10 - days_left)
        score += self.dependencies.filter(status__in=['TODO','IN_PROGRESS']).count() * 2
        if self.estimated_hours:
            score += self.estimated_hours / 2
        return score

    @property
    def priority(self):
        return self.base_priority + self.urgency_score

class Event(models.Model):
    task = models.ForeignKey(Task, on_delete=models.CASCADE, related_name='events')
    user = models.ForeignKey(User, on_delete=models.SET_NULL, null=True)
    action = models.CharField(max_length=255)
    previous_value = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
