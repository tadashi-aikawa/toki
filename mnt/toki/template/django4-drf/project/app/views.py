from django.contrib.auth.models import User
from rest_framework import permissions, viewsets

from project.app.models import Animal
from project.app.serializers import AnimalSerializer, UserSerializer


class UserViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = User.objects.all()
    model_class = User
    serializer_class = UserSerializer


class AnimalViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Animal.objects.all()
    serializer_class = AnimalSerializer
    permission_classes = [
        permissions.IsAuthenticatedOrReadOnly,
    ]
