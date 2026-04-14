"""
URL configuration for OASUFR project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/5.1/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""
from django.contrib import admin
from django.shortcuts import redirect
from django.urls import path
from app import views

urlpatterns = [
    path('admin/', admin.site.urls, name='admins'),
    path('admin', lambda request: redirect('admin/'), name='admins'),
    path('', views.show_dashboard, name='dashboard'),
    path('attendance/<str:pk>/', views.show_specific_data, name='attendance'),
    path('logs/', views.show_logs, name='logs'),
    path('login/', views.Login.as_view(), name='login'),
    path('logout/', views.Logout.as_view(), name='logout'),
    path('stripe/', views.StripeInfoHide.as_view(), name='hide_detail'),
    path('success/', views.StripeSuccess.as_view(), name='stripe_payment'),
]
