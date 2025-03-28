import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:restart_app/restart_app.dart';
import '../database/database_helper.dart';
import 'TaskDetailScreen.dart';
import 'AddTaskScreen.dart';
import 'login_screen.dart'; // Giả sử bạn có màn hình đăng nhập tên là LoginScreen

class ListViewTaskScreen extends StatefulWidget {
  final int userId;
  const ListViewTaskScreen({super.key, required this.userId});

  @override
  _ListViewTaskScreenState createState() => _ListViewTaskScreenState();
}

class _ListViewTaskScreenState extends State<ListViewTaskScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _tasks = [];
  List<Map<String, dynamic>> _filteredTasks = [];
  Map<String, List<Map<String, dynamic>>> _groupedTasks = {};
  String _searchQuery = '';
  String _priorityFilter = 'All';
  String _sortOrder = 'Newest';

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    List<Map<String, dynamic>> tasks = await _dbHelper.getUserTasks(widget.userId);
    setState(() {
      _tasks = tasks;
      _applyFilters();
    });
  }

  void _applyFilters() {
    Map<String, int> priorityMap = {'Low': 0, 'Medium': 1, 'High': 2};

    List<Map<String, dynamic>> filtered = _tasks.where((task) {
      bool matchesSearch = task['title'].toLowerCase().contains(_searchQuery.toLowerCase());

      // Chuyển đổi giá trị từ chuỗi sang số để so sánh với database
      bool matchesPriority = _priorityFilter == 'All' ||
          (priorityMap.containsKey(_priorityFilter) && task['priority'] == priorityMap[_priorityFilter]);

      return matchesSearch && matchesPriority;
    }).toList();

    // Sắp xếp: ghim trước -> ngày gần nhất
    filtered.sort((a, b) {
      if (a['pinned'] != b['pinned']) {
        return b['pinned'].compareTo(a['pinned']); // Chỉ ghim công việc, không nhóm theo ngày
      }

      // Nếu cả hai đều ghim hoặc cả hai đều không ghim, sắp xếp theo ngày
      DateTime dateA = DateTime.parse(a['dueDate']);
      DateTime dateB = DateTime.parse(b['dueDate']);
      return _sortOrder == 'Newest' ? dateB.compareTo(dateA) : dateA.compareTo(dateB);
    });

    Map<String, List<Map<String, dynamic>>> groupedTasks = {};
    for (var task in filtered) {
      String date = DateFormat("yyyy-MM-dd").format(DateTime.parse(task['dueDate']));
      if (!groupedTasks.containsKey(date)) {
        groupedTasks[date] = [];
      }
      groupedTasks[date]!.add(task);
    }

    setState(() {
      _filteredTasks = filtered;
      _groupedTasks = groupedTasks;
    });
  }

  Future<void> _toggleTaskCompletion(int taskId, bool currentStatus) async {
    await _dbHelper.markTaskCompleted(taskId, !currentStatus);
    _loadTasks();
  }

  Future<void> _navigateToAddTask() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTaskScreen(userId: widget.userId),
      ),
    );

    if (result == true) {
      _loadTasks();
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

  // Hàm hiển thị Dialog thông tin người dùng
  void _showUserInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Thông tin người dùng", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.lock, color: Colors.blueGrey),
              title: const Text("Đổi mật khẩu"),
              onTap: () {
                Navigator.pop(context); // Đóng Dialog hiện tại
                _showChangePasswordDialog(); // Hiển thị Dialog đổi mật khẩu
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Đăng xuất"),
              onTap: () {
                Navigator.pop(context); // Đóng Dialog
                _logout(); // Gọi hàm đăng xuất
                },
            ),
          ],
        ),
      ),
    );
  }

  // Hàm hiển thị Dialog đổi mật khẩu
  void _showChangePasswordDialog() {
    final TextEditingController _currentPasswordController = TextEditingController();
    final TextEditingController _newPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Đổi mật khẩu", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _currentPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Mật khẩu hiện tại",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Mật khẩu mới",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Đóng Dialog
            },
            child: const Text("Quay lại", style: TextStyle(color: Colors.blueGrey)),
          ),
          ElevatedButton(
            onPressed: () async {
              // Lấy giá trị từ các trường nhập liệu
              String currentPassword = _currentPasswordController.text;
              String newPassword = _newPasswordController.text;

              // Kiểm tra mật khẩu hiện tại
              bool isCurrentPasswordCorrect = await _dbHelper.checkPassword(widget.userId, currentPassword);
              if (!isCurrentPasswordCorrect) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Mật khẩu hiện tại không đúng!")),
                );
                return;
              }

              // Cập nhật mật khẩu mới
              int result = await _dbHelper.updatePassword(widget.userId, newPassword);
              if (result > 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Đổi mật khẩu thành công!")),
                );
                Navigator.pop(context); // Đóng Dialog
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Đổi mật khẩu thất bại!")),
                );
              }
            },
            child: const Text("Lưu"),
          ),
        ],
      ),
    );
  }

  void _logout() {
    Restart.restartApp(); // Khởi động lại ứng dụng
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Danh sách công việc",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.blueGrey[800],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.person, size: 30), // Icon người dùng
            onPressed: _showUserInfoDialog, // Hiển thị Dialog khi nhấn
          ),
        ],
      ),
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Tìm kiếm công việc',
                    prefixIcon: Icon(Icons.search, color: Colors.blueGrey[800]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.blueGrey[800]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.blueGrey[800]!),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                      _applyFilters();
                    });
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    DropdownButton<String>(
                      value: _priorityFilter,
                      items: ['All', 'High', 'Medium', 'Low']
                          .map((priority) => DropdownMenuItem(
                        value: priority,
                        child: Text(priority, style: TextStyle(color: Colors.blueGrey[800])),
                      ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _priorityFilter = value!;
                          _applyFilters();
                        });
                      },
                      dropdownColor: Colors.grey[100],
                      icon: Icon(Icons.arrow_drop_down, color: Colors.blueGrey[800]),
                      underline: Container(height: 2, color: Colors.blueGrey[800]),
                    ),
                    DropdownButton<String>(
                      value: _sortOrder,
                      items: ['Newest', 'Oldest']
                          .map((order) => DropdownMenuItem(
                        value: order,
                        child: Text(order, style: TextStyle(color: Colors.blueGrey[800])),
                      ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _sortOrder = value!;
                          _applyFilters();
                        });
                      },
                      dropdownColor: Colors.grey[100],
                      icon: Icon(Icons.arrow_drop_down, color: Colors.blueGrey[800]),
                      underline: Container(height: 2, color: Colors.blueGrey[800]),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _filteredTasks.isEmpty
                ? Center(
              child: Text(
                "Không có công việc nào",
                style: TextStyle(fontSize: 18, color: Colors.blueGrey[800]),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _groupedTasks.length,
              itemBuilder: (context, index) {
                String date = _groupedTasks.keys.elementAt(index);
                List<Map<String, dynamic>> tasks = _groupedTasks[date]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: Text(
                        "📅 $date",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueGrey[800]),
                      ),
                    ),
                    ...tasks.map((task) => Dismissible(
                      key: Key(task['id'].toString()),
                      background: Container(
                        color: Colors.red[400],
                        alignment: Alignment.centerRight,
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Icon(Icons.delete, color: Colors.white, size: 30),
                      ),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (direction) async {
                        return await showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(
                                "Xác nhận xóa",
                                style: TextStyle(color: Colors.blueGrey[800]),
                              ),
                              content: Text(
                                "Bạn có chắc muốn xóa công việc này không?",
                                style: TextStyle(color: Colors.blueGrey[800]),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: Text(
                                    "Hủy",
                                    style: TextStyle(color: Colors.blueGrey[800]),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(true),
                                  child: Text(
                                    "Xóa",
                                    style: TextStyle(color: Colors.red[400]),
                                  ),
                                ),
                              ],
                            )
                        );
                      },
                      onDismissed: (direction) async {
                        await _dbHelper.deleteTask(task['id']);
                        _loadTasks();
                      },
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 3,
                        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                          leading: task['pinned'] == 1 ? Icon(Icons.push_pin, color: Colors.orange[800]) : null,
                          title: Text(
                            task['title'],
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              decoration: task['completed'] == 1 ? TextDecoration.lineThrough : TextDecoration.none,
                              color: task['completed'] == 1 ? Colors.grey : Colors.blueGrey[800],
                            ),
                          ),
                          subtitle: Text("Hạn chót: ${_formatDueDate(task['dueDate'])}", style: TextStyle(color: Colors.blueGrey[600])),
                          trailing: IconButton(
                            icon: Icon(
                              task['completed'] == 1 ? Icons.check_circle : Icons.radio_button_unchecked,
                              color: task['completed'] == 1 ? Colors.green[800] : Colors.redAccent[400],
                            ),
                            onPressed: () {
                              _toggleTaskCompletion(task['id'], task['completed'] == 1);
                            },
                          ),
                          onTap: () async {
                            bool? isUpdated = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TaskDetailScreen(task: task),
                              ),
                            );
                            if (isUpdated == true) _loadTasks();
                          },
                          onLongPress: () async {
                            await _dbHelper.toggleTaskPin(task['id'], task['pinned'] == 0);
                            _loadTasks();
                          },
                        ),
                      ),
                    )),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddTask,
        backgroundColor: Colors.blueGrey[800],
        child: const Icon(Icons.add, size: 30, color: Colors.white),
      ),
    );
  }
}