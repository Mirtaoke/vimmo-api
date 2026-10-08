<?php

namespace App\Mail;

use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;
use Illuminate\Queue\SerializesModels;

class OneTimeCodeMail extends Mailable
{
    use Queueable, SerializesModels;

    public function __construct(
        public string $recipientName,
        public string $code,
        public string $purpose = 'registration',
    ) {}

    public function envelope(): Envelope
    {
        return new Envelope(subject: match ($this->purpose) {
            'password_reset' => 'Réinitialisation de votre mot de passe VIMMO',
            'family_activation' => 'Activation de votre espace familial VIMMO',
            default => 'Votre code de vérification VIMMO',
        });
    }

    public function content(): Content
    {
        return new Content(markdown: 'mail.auth.one-time-code');
    }

    public function attachments(): array
    {
        return [];
    }
}
