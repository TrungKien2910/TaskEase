import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../manhinh/UpdateTaskScreen.dart';

class TaskDetailScreen extends StatefulWidget {
  final Map<String, dynamic> task;

  const TaskDetailScreen({super.key, required this.task});

  @override
  _TaskDetailScreenState createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late Map<String, dynamic> task;

  @override
  void initState() {
    super.initState();
    task = widget.task;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text(
          task['title'],
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.blueGrey[800],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 5,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                shadowColor: Colors.blueGrey.withOpacity(0.2),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                      _buildListTile(Icons.description, "Mô tả", task['description']),
                  _divider(),
                  _buildListTile(Icons.flag, "Mức độ ưu tiên", _getPriorityText(task['priority'])),
                    _divider(),
                    _buildListTile(Icons.notifications, "Thông báo", task['notification'] == 1 ? "Bật" : "Tắt"),
                    _divider(),
                    _buildListTile(Icons.calendar_today, "Hạn chót", _formatDueDate(task['dueDate'])),
                    _divider(),
                    _buildListTile(Icons.check_circle, "Trạng thái",
                        task['completed'] == 1 ? "Hoàn thành" : "Chưa hoàn thành"),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _divider() {
    return Divider(color: Colors.grey.shade300, thickness: 1);
  }

  Widget _buildListTile(IconData icon, String title, String value) {
    return ListTile(
      leading: Icon(icon, color: Colors.blueGrey[800], size: 30),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blueGrey[800]),
      ),
      subtitle: Text(
        value,
        style: TextStyle(fontSize: 15, color: Colors.blueGrey[600]),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _navigateToUpdate(context),
            icon: const Icon(Icons.edit, color: Colors.white),
            label: const Text("Cập nhật", style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueGrey[800],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              elevation: 3,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _confirmDelete(context),
            icon: const Icon(Icons.delete, color: Colors.white),
            label: const Text("Xóa", style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[400],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              elevation: 3,
            ),
          ),
        ),
      ],
    );
  }

  String _getPriorityText(int priority) {
    switch (priority) {
      case 0:
        return "Thấp";
      case 1:
        return "Trung Bình";
      case 2:
        return "Cao";
      default:
        return "Không xác định";
    }
  }

  String _formatDueDate(String dueDate) {
    try {
      DateTime dateTime = DateTime.parse(dueDate);
      return DateFormat("yyyy-MM-dd HH:mm").format(dateTime);
    } catch (e) {
      return dueDate;
    }
  }

  Future<void> _navigateToUpdate(BuildContext context) async {
    bool? isUpdated = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => UpdateTaskScreen(task: task)),
    );

    if (isUpdated == true) {
      Navigator.pop(context, true);
    }
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title:  Text("Xác nhận xóa", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey[800])),
          content:  Text("Bạn có chắc chắn muốn xóa công việc này không?", style: TextStyle(color: Colors.blueGrey[600])),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child:  Text("Hủy", style: TextStyle(color: Colors.blueGrey[800])),
            ),
            TextButton(
              onPressed: () async {
                int result = await DatabaseHelper().deleteTask(task['id']);
                Navigator.pop(dialogContext);
                if (result > 0) {
                  Navigator.pop(context, true);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Xóa thất bại!", style: TextStyle(color: Colors.white))),
                  );
                }
              },
              child:  Text("Xóa", style: TextStyle(color: Colors.red[400], fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}