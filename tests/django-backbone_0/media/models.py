# -*- coding: utf-8 -*-

from django.db import models
from django.contrib.auth.models import User
from django.forms import ModelForm
from mucua.models import Mucua
from etiqueta.models import Etiqueta
from bbx.settings import ANNEX_DIR
#from media.serializers import MediaSerializer

import os
import uuid
import logging
import subprocess
from datetime import datetime

TYPE_CHOICES = ( ('audio', 'audio'), ('imagem', 'imagem'), ('video', 'video'), ('arquivo','arquivo') )
FORMAT_CHOICES = ( ('ogg', 'ogg'), ('webm', 'webm'), ('mp4', 'mp4'), ('jpg','jpg') )



def media_file_name(instance, filename):
    logging.debug(os.path.join(getFilePath(instance) + instance.getFileName()))
    return os.path.join(getFilePath(instance), instance.getFileName())


def generateUUID():
    return str(uuid.uuid4())


def getFilePath(instance):
    if instance.date == '':
        t = datetime.now
        date = t.strftime("%y/%m/%d/")
    else:
        date = instance.date.strftime("%y/%m/%d/")

    t = datetime.now()
    return os.path.join(ANNEX_DIR, instance.getRepository(),
                        instance.getMucua(), instance.getType(), 
                        date)

    
class Media(models.Model):
    date = models.DateTimeField(auto_now_add=True)
    uuid = models.CharField(max_length=36, default=generateUUID())
    title = models.CharField(max_length=100, blank=True, default='')
    comment = models.TextField(max_length=300, blank=True)
    author = models.ForeignKey(User)
    origin = models.ForeignKey(Mucua, related_name='origin')
    type = models.CharField(max_length=14, choices=TYPE_CHOICES, 
                            default='arquivo', blank=True)
    format = models.CharField(max_length=14, choices=FORMAT_CHOICES, 
                              default='ogg', blank=True)
    license = models.CharField(max_length=100, blank=True)
    mediafile = models.FileField(upload_to=media_file_name, blank=True)
    repository = models.ForeignKey('gitannex.Repository', related_name='repository')
    #    versions = 
    tags = models.ManyToManyField(Etiqueta, related_name='tags')
    
    def __unicode__(self):
        return self.title

    def getFileName(self):
        return str(self.uuid)  + '.' + self.format
    
    def getRepository(self):
        return self.repository.repositoryName

    def getMucua(self):
        return self.origin.description

    def getType(self):
        return self.type

    def getFormat(self):
        return self.format

    class Meta:
        ordering = ('date',)
    


