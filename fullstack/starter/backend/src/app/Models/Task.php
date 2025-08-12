<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Task extends Model
{
    protected $fillable = ['title', 'base_priority', 'estimated_hours', 'due_date', 'assigned_to', 'status'];
    public function dependencies()
    {
        return $this->hasMany(TaskDependency::class, 'task_id');
    }
}
