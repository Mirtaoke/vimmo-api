<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        $this->call([UserSeeder::class, PropertySeeder::class, UnitSeeder::class, ListingSeeder::class, RentalApplicationSeeder::class, LeaseContractSeeder::class, RentScheduleSeeder::class, PaymentSeeder::class, ReceiptSeeder::class, InspectionSeeder::class, InspectionWorkflowSeeder::class, MaintenanceRequestSeeder::class, MaintenanceCommentSeeder::class, DocumentSeeder::class, PatrimonyDocumentSeeder::class, AssetShareSeeder::class, MarketplaceActivitySeeder::class, EventCategorySeeder::class, EventSeeder::class, EventScheduleSeeder::class, TicketTypeSeeder::class, TicketOrderSeeder::class, TicketPaymentSeeder::class, ConversationSeeder::class, MessageSeeder::class, NotificationSeeder::class, AuditLogSeeder::class]);
    }
}
