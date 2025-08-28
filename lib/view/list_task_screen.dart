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
  final ScrollController _scrollController = ScrollController();

  DateTime? _deadline;
  String _filterKeyword = "";
  String _filterStatus = "all";

  int _perPage = 10;
  int _currentMax = 10;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      setState(() {
        _currentMax += _perPage;
      });
    }
  }

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
      isCompleted: _filterStatus == "all"
          ? null
          : _filterStatus == "done"
              ? true
              : false,
    );

    final paginatedTasks = tasks.take(_currentMax).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Task Manager"),
        centerTitle: true,
        backgroundColor: Colors.indigo,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search tasks...",
                prefixIcon: const Icon(Icons.search),
                fillColor: Colors.grey[100],
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _filterKeyword = value;
                  _currentMax = _perPage;
                });
              },
            ),
          ),

          // Filter buttons
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: ToggleButtons(
              isSelected: [
                _filterStatus == "all",
                _filterStatus == "done",
                _filterStatus == "progress",
              ],
              borderRadius: BorderRadius.circular(25),
              selectedColor: Colors.white,
              fillColor: Colors.indigo,
              color: Colors.black87,
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.0),
                  child: Text("All"),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.0),
                  child: Text("Completed"),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.0),
                  child: Text("In Progress"),
                ),
              ],
              onPressed: (index) {
                setState(() {
                  if (index == 0) _filterStatus = "all";
                  if (index == 1) _filterStatus = "done";
                  if (index == 2) _filterStatus = "progress";
                  _currentMax = _perPage;
                });
              },
            ),
          ),

          // Task list
          Expanded(
            child: paginatedTasks.isEmpty
                ? const Center(child: Text("No tasks found", style: TextStyle(fontSize: 18)))
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: paginatedTasks.length + 1,
                    itemBuilder: (ctx, i) {
                      if (i == paginatedTasks.length) {
                        return _currentMax < tasks.length
                            ? const Padding(
                                padding: EdgeInsets.all(10),
                                child: Center(child: CircularProgressIndicator()),
                              )
                            : const SizedBox();
                      }

                      final task = paginatedTasks[i];

                      return Dismissible(
                        key: ValueKey(task.id),
                        direction: DismissDirection.startToEnd,
                        background: Container(
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(left: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) {
                          Provider.of<TaskProvider>(context, listen: false).deleteTask(task.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("${task.title} deleted")),
                          );
                        },
                        child: Card(
                          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                          elevation: 5,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            title: Text(task.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                                )),
                            subtitle: Text(
                              "${task.description}\nDeadline: ${task.deadline.toLocal().toString().split(' ')[0]}",
                              style: const TextStyle(fontSize: 14),
                            ),
                            isThreeLine: true,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => _showUpdateDialog(context, task),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    Provider.of<TaskProvider>(context, listen: false).deleteTask(task.id);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text("${task.title} deleted")),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: Icon(
                                    task.isCompleted ? Icons.check_circle : Icons.circle_outlined,
                                    color: task.isCompleted ? Colors.green : Colors.grey,
                                  ),
                                  onPressed: () {
                                    Provider.of<TaskProvider>(context, listen: false).toggleStatus(task.id);
                                  },
                                ),
                              ],
                            ),
                            onTap: () => _showUpdateDialog(context, task),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add),
        onPressed: () => _showAddDialog(context),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Add Task", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: "Title", border: OutlineInputBorder()),
                validator: (value) => value == null || value.isEmpty ? "Enter title" : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: "Description", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(_deadline == null ? "Select Deadline" : _deadline.toString().split(' ')[0]),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
            onPressed: () {
              if (_formKey.currentState!.validate() && _deadline != null) {
                _addTask(context);
                Navigator.pop(context);
              }
            },
            child: const Text("Add"),
          ),
        ],
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Update Task", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: "Title", border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: descController, decoration: const InputDecoration(labelText: "Description", border: OutlineInputBorder())),
            const SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(deadline == null ? "Select Deadline" : deadline.toString().split(' ')[0]),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
