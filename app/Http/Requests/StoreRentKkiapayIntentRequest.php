<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreRentKkiapayIntentRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()?->role === 'tenant';
    }

    public function rules(): array
    {
        return [
            'lease_contract_id' => ['required', 'integer', 'exists:lease_contracts,id'],
            'schedule_ids' => ['required', 'array', 'min:1'],
            'schedule_ids.*' => ['required', 'integer', 'distinct', 'exists:rent_schedules,id'],
        ];
    }

    public function messages(): array
    {
        return [
            'lease_contract_id.required' => 'Sélectionnez le contrat concerné.',
            'schedule_ids.required' => 'Sélectionnez au moins une échéance.',
            'schedule_ids.min' => 'Sélectionnez au moins une échéance.',
            'schedule_ids.*.distinct' => 'Une échéance ne peut être sélectionnée qu’une fois.',
        ];
    }
}
