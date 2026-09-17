<x-mail::message>
# Bonjour {{ $recipientName }},

{{ $ownerName }} vient de partager avec vous le bien **{{ $propertyName }}** sur VIMMO.

Votre niveau d’accès : **{{ $permissionLabel }}**.

Ouvrez l’application VIMMO avec cette adresse e-mail, puis consultez votre espace de patrimoine partagé pour accéder au bien et aux documents autorisés.

À bientôt,<br>
L’équipe {{ config('app.name') }}
</x-mail::message>
