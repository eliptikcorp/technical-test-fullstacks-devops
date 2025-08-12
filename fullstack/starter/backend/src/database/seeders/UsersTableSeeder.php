<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class UsersTableSeeder extends Seeder
{
    public function run()
    {
        DB::table('users')->insert([
            [
                'id' => 1,
                'name' => 'Alice',
                'email' => 'alice@example.com',
                'password' => bcrypt('password')
            ],
            [
                'id' => 2,
                'name' => 'Alice Dup',
                'email' => 'alice@example.com',
                'password' => bcrypt('password')
            ],
            [
                'id' => 3,
                'name' => 'Bob',
                'email' => 'bob@example.com',
                'password' => bcrypt('password')
            ],
            [
                'id' => 4,
                'name' => 'Charlie',
                'email' => 'charlie@example.com',
                'password' => bcrypt('password')
            ],
        ]);
    }
}
