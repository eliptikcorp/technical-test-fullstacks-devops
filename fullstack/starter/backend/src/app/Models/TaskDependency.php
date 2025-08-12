<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class TaskDependency extends Model
{
    protected $table = 'task_dependencies';
    protected $fillable = ['task_id', 'dependency_id'];
}
