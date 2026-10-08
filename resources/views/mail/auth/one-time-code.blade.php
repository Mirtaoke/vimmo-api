<x-mail::message>
# Bonjour {{ $recipientName }},

@if($purpose === 'password_reset')
Utilisez ce code pour réinitialiser votre mot de passe VIMMO :
@elseif($purpose === 'family_activation')
Utilisez ce code pour activer votre espace familial VIMMO :
@else
Utilisez ce code pour vérifier votre adresse e-mail et terminer la création de votre compte VIMMO :
@endif

<div style="margin: 24px 0; text-align: center; font-size: 32px; font-weight: 800; letter-spacing: 8px; color: #0f766e;">
{{ $code }}
</div>

Ce code expire dans **10 minutes**. Ne le communiquez à personne.

Si vous n’êtes pas à l’origine de cette demande, ignorez simplement ce message.

À bientôt,<br>
L’équipe {{ config('app.name') }}
</x-mail::message>
