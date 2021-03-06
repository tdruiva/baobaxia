from rest_framework import serializers
from mucua.models import Mucua


class MucuaSerializer(serializers.ModelSerializer):
    class Meta:
        model = Mucua
        fields = ('description', 'note', 'uuid', 'repository', 'mocambolas')

    def restore_object(self, attrs, instance=None):
        if instance:
            # Update existing instance
            instance.description = attrs.get('description',
                                             instance.description)
            instance.note = attrs.get('namespace', instance.note)
            instance.uuid = attrs.get('uuid', instance.uuid)

            return instance

        # Create new instance
        return Mucua(**attrs)
