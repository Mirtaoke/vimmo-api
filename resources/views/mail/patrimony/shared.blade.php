<x-mail::message>
# Bonjour {{ $recipientName }},

{{ $ownerName }} vient de partager avec vous le bien **{{ $propertyName }}** sur VIMMO.

Votre niveau d’accès : **{{ $permissionLabel }}**.

@if($activationCode)
Un espace **Membre familial** vient d’être créé automatiquement pour vous.

Votre identifiant : **{{ $recipientEmail }}**  
Votre code d’activation : **{{ $activationCode }}**

Ce code expire dans 10 minutes. Dans l’application, choisissez **Membre familial**, puis **Activer mon accès** afin de définir votre propre mot de passe. Aucun mot de passe permanent n’est envoyé par e-mail.
@endif

Ouvrez l’application VIMMO avec cette adresse e-mail, puis consultez votre espace de patrimoine partagé pour accéder au bien et aux documents autorisés.

À bientôt,<br>
L’équipe {{ config('app.name') }}
</x-mail::message>
