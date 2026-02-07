import os

SECRET_KEY = os.environ.get("SECRET_KEY", "change-me-in-production")
DEBUG = os.environ.get("DEBUG", "false").lower() == "true"
ALLOWED_HOSTS = os.environ.get("ALLOWED_HOSTS", "*").split(",")
ROOT_URLCONF = "app.urls"
WSGI_APPLICATION = "app.wsgi.application"
DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.sqlite3",
        "NAME": os.environ.get("DB_PATH", "db.sqlite3"),
    }
}
INSTALLED_APPS = ["django.contrib.contenttypes", "django.contrib.staticfiles"]
