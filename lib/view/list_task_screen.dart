import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test/models/task.dart';
import 'package:test/view/list_task_controller.dart';
import 'package:uuid/uuid.dart';

class TaskScreen extends StatefulWidget {
  const TaskScreen({super.key});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  DateTime? _deadline;

  String _filterKeyword = "";
  bool? _filterStatus;
  void _addTask(BuildContext context) {
    if (_titleController.text.isEmpty || _deadline == null) return;

    final task = Task(
      id: const Uuid().v4(),
      title: _titleController.text,
      description: _descController.text,
      deadline: _deadline!,
    );

    Provider.of<TaskProvider>(context, listen: false).addTask(task);
    _titleController.clear();
    _descController.clear();
    _deadline = null;
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final tasks = taskProvider.filterTasks(
      keyword: _filterKeyword,
      isCompleted: _filterStatus,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("Task Manager"),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                if (value == "all") _filterStatus = null;
                if (value == "done") _filterStatus = true;
                if (value == "progress") _filterStatus = false;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: "all", child: Text("All")),
              const PopupMenuItem(value: "done", child: Text("Completed")),
              const PopupMenuItem(value: "progress", child: Text("In Progress")),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: "Search",
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _filterKeyword = value;
                });
              },
            ),
          ),
          // Task List
          Expanded(
            child: ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (ctx, i) {
                final task = tasks[i];

                return Dismissible(
                  key: ValueKey(task.id),
                  direction: DismissDirection.startToEnd, // swipe left-to-right
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (direction) {
                    Provider.of<TaskProvider>(context, listen: false).deleteTask(task.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("${task.title} deleted")),
                    );
                  },
                  child: InkWell(
                    onTap: () => _showUpdateDialog(context, task), // open update dialog
                    child: ListTile(
                      title: Text(task.title),
                      subtitle: Text("${task.description} - ${task.deadline.toLocal()}"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              task.isCompleted ? Icons.check_box : Icons.check_box_outline_blank,
                              color: task.isCompleted ? Colors.green : null,
                            ),
                            onPressed: () => Provider.of<TaskProvider>(context, listen: false).toggleStatus(task.id),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _showUpdateDialog(context, task),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              Provider.of<TaskProvider>(context, listen: false).deleteTask(task.id);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text("Add Task"),
              content: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: "Title"),
                      validator: (value) {
                        if (value == null || value.isEmpty) return "Title cannot be empty";
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _descController,
                      decoration: const InputDecoration(labelText: "Description"),
                      validator: (value) {
                        if (value == null || value.isEmpty) return "Description cannot be empty";
                        return null;
                      },
                    ),
                    TextButton(
                      child: Text(_deadline == null ? "Select Deadline" : _deadline.toString()),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                          initialDate: DateTime.now(),
                        );
                        if (picked != null) setState(() => _deadline = picked);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate() && _deadline != null) {
                      _addTask(context);
                      Navigator.pop(context);
                    } else if (_deadline == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please select a deadline")),
                      );
                    }
                  },
                  child: const Text("Add"),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showUpdateDialog(BuildContext context, Task task) {
    final titleController = TextEditingController(text: task.title);
    final descController = TextEditingController(text: task.description);
    DateTime? deadline = task.deadline;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Update Task"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: "Title")),
            TextField(controller: descController, decoration: const InputDecoration(labelText: "Description")),
            TextButton(
              child: Text(deadline == null ? "Select Deadline" : deadline.toString()),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                  initialDate: deadline ?? DateTime.now(),
                );
                if (picked != null) {
                  setState(() => deadline = picked);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              Provider.of<TaskProvider>(context, listen: false).updateTask(
                task.id,
                title: titleController.text,
                description: descController.text,
                deadline: deadline,
              );
              Navigator.pop(context);
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }
}
