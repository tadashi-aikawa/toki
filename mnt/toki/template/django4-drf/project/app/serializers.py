from django.contrib.auth.models import User
from rest_framework import serializers

from project.app.models import Animal


class AnimalSerializer(serializers.ModelSerializer):
    class Meta:  # pyright: ignore[reportIncompatibleVariableOverride]
        model = Animal
        fields = "__all__"


class UserSerializer(serializers.ModelSerializer):
    animals = AnimalSerializer(many=True)

    class Meta:  # pyright: ignore[reportIncompatibleVariableOverride]
        model = User
        fields = ["id", "username", "animals"]
