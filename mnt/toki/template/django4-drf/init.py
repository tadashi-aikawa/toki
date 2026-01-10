from django.contrib.auth.models import User
from django.db import transaction
from project.app.models import Animal

with transaction.atomic():
    User.objects.all().delete()
    User.objects.create_superuser(id=1, username="admin", password="password", email="")
    User.objects.bulk_create(
        [
            User(id=2, username="ミネルヴァ"),
            User(id=3, username="オブシディア"),
            User(id=4, username="ネオちゃん"),
        ]
    )

with transaction.atomic():
    Animal.objects.all().delete()
    Animal.objects.bulk_create(
        [
            Animal(
                name="みみぞう",
                description="ピーッ！",
                proper=True,
                kind="owl",
                owner_id=2,  # ミネルヴァ
            ),
            Animal(
                name="タツヲ",
                description="ウホ♡",
                proper=True,
                kind="gorilla",
            ),
            Animal(
                name="ポチ",
                description="ワンワン！",
                proper=False,
                kind="dog",
                owner_id=4,  # ネオちゃん
            ),
        ]
    )
