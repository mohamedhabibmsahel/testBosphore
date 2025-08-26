import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:test/models/task.dart';

class TaskProvider with ChangeNotifier {
  final Box<Task> _taskBox = Hive.box<Task>('tasksBox');

  List<Task> get tasks => _taskBox.values.toList();

  void addTask(Task task) {
    _taskBox.put(task.id, task);
    notifyListeners();
  }

  void updateTask(String id, {String? title, String? description, DateTime? deadline}) {
    final task = _taskBox.get(id);
    if (task != null) {
      if (title != null) task.title = title;
      if (description != null) task.description = description;
      if (deadline != null) task.deadline = deadline;
      task.save();
      notifyListeners();
    }
  }

  void deleteTask(String id) {
    _taskBox.delete(id);
    notifyListeners();
  }

  void toggleStatus(String id) {
    final task = _taskBox.get(id);
    if (task != null) {
      task.isCompleted = !task.isCompleted;
      task.save();
      notifyListeners();
    }
  }

  List<Task> filterTasks({String keyword = "", bool? isCompleted}) {
    return tasks.where((task) {
      final matchesKeyword = task.title.contains(keyword) || task.description.contains(keyword);
      final matchesStatus = isCompleted == null || task.isCompleted == isCompleted;
      return matchesKeyword && matchesStatus;
    }).toList();
  }
}
