<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class TasksTableSeeder extends Seeder
{
    public function run()
    {
        DB::table('tasks')->insert([
            [
                'id' => 1,
                'title' => 'Setup project',
                'base_priority' => 3,
                'estimated_hours' => 'n/a', // invalide
                'due_date' => null,
                'assigned_to' => 1,
                'status' => 'TODO',
                'dependencies' => json_encode([2])
            ],
            [
                'id' => 2,
                'title' => 'Configure CI/CD',
                'base_priority' => 5,
                'estimated_hours' => 4,
                'due_date' => '2025-08-15',
                'assigned_to' => 2,
                'status' => 'TODO',
                'dependencies' => json_encode([1])
            ],
            [
                'id' => 3,
                'title' => 'Deploy to prod',
                'base_priority' => 7,
                'estimated_hours' => 2,
                'due_date' => '2025-08-14',
                'assigned_to' => null, // non assignée
                'status' => 'TODO',
                'dependencies' => json_encode([3]) // dépendance circulaire
            ],
        ]);
    }
}
