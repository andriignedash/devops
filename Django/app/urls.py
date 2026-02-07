from django.urls import path
from django.http import HttpResponse

def health(request):
    return HttpResponse("ok", content_type="text/plain")

urlpatterns = [path("health/", health)]
