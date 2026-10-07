<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('units', function (Blueprint $table) {
            $table->json('amenity_details')->nullable()->after('amenities');
            $table->decimal('monthly_charges', 14, 2)->default(0)->after('monthly_rent');
            $table->decimal('deposit_amount', 14, 2)->default(0)->after('monthly_charges');
            $table->unsignedSmallInteger('advance_months')->default(0)->after('deposit_amount');
            $table->text('charges_description')->nullable()->after('advance_months');
            $table->text('deposit_description')->nullable()->after('charges_description');
        });

        Schema::table('listings', function (Blueprint $table) {
            $table->decimal('advance_amount', 14, 2)->default(0)->after('charges');
            $table->text('charges_description')->nullable()->after('advance_amount');
            $table->text('deposit_description')->nullable()->after('charges_description');
        });

        Schema::table('maintenance_requests', function (Blueprint $table) {
            $table->text('availability_notes')->nullable()->after('description');
        });
    }

    public function down(): void
    {
        Schema::table('maintenance_requests', function (Blueprint $table) {
            $table->dropColumn('availability_notes');
        });

        Schema::table('listings', function (Blueprint $table) {
            $table->dropColumn([
                'advance_amount',
                'charges_description',
                'deposit_description',
            ]);
        });

        Schema::table('units', function (Blueprint $table) {
            $table->dropColumn([
                'amenity_details',
                'monthly_charges',
                'deposit_amount',
                'advance_months',
                'charges_description',
                'deposit_description',
            ]);
        });
    }
};
