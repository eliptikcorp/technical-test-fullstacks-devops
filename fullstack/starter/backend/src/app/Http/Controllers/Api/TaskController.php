<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Task;
use Illuminate\Http\Request;

class TaskController extends Controller
{
    public function index(Request $req)
    {
        return response()->json(Task::all());
    }

    public function store(Request $req)
    {
        $task = Task::create($req->only(['title','base_priority','estimated_hours','due_date','assigned_to','status']));
        return response()->json($task, 201);
    }
}
