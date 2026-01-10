import uuid

from django.contrib.auth.models import User
from django.db import models

ANIMAL_KIND = (
    ("dog", "犬"),
    ("cat", "猫"),
    ("owl", "フクロウ"),
    ("gorilla", "ゴリラ"),
)


class Animal(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=100, blank=True, default="")
    description = models.TextField()
    proper = models.BooleanField(default=False)
    kind = models.CharField(choices=ANIMAL_KIND, default="owl", max_length=32)

    owner = models.ForeignKey(
        User, related_name="animals", on_delete=models.CASCADE, null=True
    )
    created = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["created"]
