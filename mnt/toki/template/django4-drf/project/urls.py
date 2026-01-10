from django.contrib import admin
from django.urls import include, path
from rest_framework.routers import DefaultRouter

from project.app import views

router = DefaultRouter()
router.register(r"users", views.UserViewSet, basename="user")
router.register(r"animals", views.AnimalViewSet, basename="animal")


urlpatterns = [
    path("admin/", admin.site.urls),
    path("", include(router.urls)),
]
