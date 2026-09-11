<!doctype html>
<html lang="fr"><head><meta charset="utf-8"><style>
body{font-family:DejaVu Sans,sans-serif;color:#102A43;margin:42px;font-size:13px}.brand{font-size:26px;font-weight:bold;color:#0F766E}.gold{color:#9A7415}.hero{background:#102A43;color:white;padding:24px;border-radius:14px;margin:22px 0}.amount{font-size:29px;font-weight:bold;margin-top:8px}.grid{width:100%;border-collapse:collapse}.grid td{padding:11px;border-bottom:1px solid #dfe8e5}.label{color:#64748b;width:36%}.footer{margin-top:35px;padding:16px;background:#edf5f3;border-left:5px solid #0F766E;font-size:11px}.signature{text-align:right;margin-top:45px}.badge{display:inline-block;background:#d9efe9;color:#0F766E;padding:7px 12px;border-radius:20px;font-weight:bold}
</style></head><body>
<div class="brand">VIMMO</div><div class="gold">Votre immobilier, votre patrimoine, votre quotidien.</div>
<div class="hero"><div>QUITTANCE DE LOYER</div><div class="amount">{{ number_format((float)$payment->amount,0,',',' ') }} FCFA</div><div>{{ $periods }}</div></div>
<p><span class="badge">PAIEMENT CONFIRMÉ</span></p>
<table class="grid"><tr><td class="label">Référence</td><td>{{ $receipt->reference }}</td></tr><tr><td class="label">Propriétaire</td><td>{{ $contract->owner->name }}</td></tr><tr><td class="label">Locataire</td><td>{{ $contract->tenant->name }}</td></tr><tr><td class="label">Logement</td><td>{{ $contract->unit->property->name }} — {{ $contract->unit->reference }}</td></tr><tr><td class="label">Période</td><td>{{ $periods }}</td></tr><tr><td class="label">Mode de paiement</td><td>{{ strtoupper(str_replace('_',' ',$payment->method)) }}</td></tr><tr><td class="label">Date du paiement</td><td>{{ $payment->paid_at->locale('fr')->translatedFormat('d F Y à H:i') }}</td></tr></table>
<div class="signature">Émise automatiquement par VIMMO<br><strong>{{ $receipt->generated_at->locale('fr')->translatedFormat('d F Y à H:i') }}</strong></div>
<div class="footer"><strong>Authenticité du document</strong><br>Jeton de vérification : {{ $receipt->verification_token }}<br>Cette quittance est rattachée au contrat {{ $contract->reference }} et au paiement {{ $payment->reference }}.</div>
</body></html>
