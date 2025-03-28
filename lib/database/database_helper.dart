import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() {
    return _instance;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'task_manager.db');

    // Kiểm tra xem database đã tồn tại chưa
    bool dbExists = await databaseExists(path);

    // Mở database
    Database db = await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );

    // Nếu database chưa tồn tại, thêm dữ liệu mẫu
    if (!dbExists) {
      await _insertSampleData(db);
    }

    return db;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
    CREATE TABLE users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT UNIQUE,
      password TEXT
    )
  ''');

    await db.execute('''
    CREATE TABLE tasks (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      userId INTEGER,
      title TEXT,
      description TEXT,
      priority INTEGER DEFAULT 1,
      notification INTEGER DEFAULT 0,
      dueDate TEXT,
      completed  INTEGER DEFAULT 0,
      pinned INTEGER DEFAULT 0,
      FOREIGN KEY (userId) REFERENCES users(id) ON DELETE CASCADE
    )
  ''');
  }

  // Thêm dữ liệu mẫu
  Future<void> _insertSampleData(Database db) async {
    await db.insert('users', {'username': 'user1', 'password': sha256.convert(utf8.encode('123456')).toString()});
    await db.insert('users', {'username': 'user2', 'password': sha256.convert(utf8.encode('password')).toString()});

    await db.insert('tasks', {
      'userId': 1,
      'title': 'Hoàn thành báo cáo',
      'description': 'Viết báo cáo tháng cho phòng kế toán',
      'priority': 2,
      'notification': 1,
      'dueDate': '2024-03-20 10:00',
      'completed' : 0,
      'pinned' :0
    });

    await db.insert('tasks', {
      'userId': 1,
      'title': 'Họp nhóm dự án',
      'description': 'Họp với nhóm để thảo luận tiến độ dự án',
      'priority': 1,
      'notification': 1,
      'dueDate': '2024-03-21 14:00',
      'completed' : 0,
      'pinned' :0
    });

    await db.insert('tasks', {
      'userId': 2,
      'title': 'Đi mua sắm',
      'description': 'Mua đồ dùng văn phòng phẩm',
      'priority': 0,
      'notification': 0,
      'dueDate': '2024-03-22 16:00',
      'completed' : 0,
      'pinned' :0
    });
  }

  // -------------------- HÀM BĂM MẬT KHẨU --------------------
  String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  // -------------------- USER METHODS --------------------
  Future<int> registerUser(String username, String password) async {
    final db = await database;
    String hashedPassword = _hashPassword(password);
    return await db.insert('users', {'username': username, 'password': hashedPassword});
  }

  Future<int?> login(String username, String password) async {
    final db = await database;

    // Mã hóa mật khẩu nhập vào bằng SHA-256
    String hashedPassword = _hashPassword(password);

    List<Map<String, dynamic>> result = await db.query(
      'users',
      columns: ['id'],
      where: 'username = ? AND password = ?',
      whereArgs: [username, hashedPassword],
    );

    if (result.isNotEmpty) {
      return result.first['id'];
    }
    return null;
  }

  Future<bool> checkPassword(int userId, String currentPassword) async {
    final db = await database;

    // Mã hóa mật khẩu hiện tại
    String hashedPassword = _hashPassword(currentPassword);

    // Kiểm tra xem mật khẩu có khớp không
    List<Map<String, dynamic>> result = await db.query(
      'users',
      columns: ['id'],
      where: 'id = ? AND password = ?',
      whereArgs: [userId, hashedPassword],
    );

    return result.isNotEmpty; // Trả về true nếu mật khẩu đúng, ngược lại false
  }

  // -------------------- CẬP NHẬT MẬT KHẨU --------------------
  Future<int> updatePassword(int userId, String newPassword) async {
    final db = await database;

    // Mã hóa mật khẩu mới
    String hashedPassword = _hashPassword(newPassword);

    // Cập nhật mật khẩu mới
    int result = await db.update(
      'users',
      {'password': hashedPassword},
      where: 'id = ?',
      whereArgs: [userId],
    );

    return result; // Trả về số hàng được cập nhật
  }

  // -------------------- TASK METHODS --------------------
  Future<int> addTask(int userId, String title, String description, int priority, int notification, String dueDate) async {
    final db = await database;
    return await db.insert('tasks', {
      'userId': userId,
      'title': title,
      'description': description,
      'priority': priority,
      'notification': notification,
      'dueDate': dueDate,
      'completed': 0,
      'pinned' :0
    });
  }

  Future<List<Map<String, dynamic>>> getUserTasks(int userId) async {
    final db = await database;
    return await db.query(
      'tasks',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'dueDate ASC',
    );
  }

  Future<int> updateTask(int id, String title, String description, int priority, int notification, String dueDate, int completed) async {
    final db = await database;
    int result = await db.update(
      'tasks',
      {
        'title': title,
        'description': description,
        'priority': priority,
        'notification': notification,
        'dueDate': dueDate,
        'completed': completed,
      },
      where: 'id = ?',
      whereArgs: [id],
    );

    return result;
  }


  Future<int> deleteTask(int taskId) async {
    final db = await database;
    return await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  // -------------------- CẬP NHẬT TRẠNG THÁI HOÀN THÀNH --------------------
  Future<int> markTaskCompleted(int taskId, bool isCompleted) async {
    final db = await database;
    return await db.update(
      'tasks',
      {'completed': isCompleted ? 1 : 0},
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }


  Future<void> toggleTaskPin(int taskId, bool pinned) async {
    final db = await database;
    await db.update(
      'tasks',
      {'pinned': pinned ? 1 : 0},
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  Future<Map<String, int>> getTaskStatistics(int userId, int month, int year) async {
    final db = await database;
    String startDate = "$year-${month.toString().padLeft(2, '0')}-01";
    String endDate = "$year-${month.toString().padLeft(2, '0')}-31";

    int totalTasks = Sqflite.firstIntValue(await db.rawQuery(
      "SELECT COUNT(*) FROM tasks WHERE userId = ? AND dueDate BETWEEN ? AND ?",
      [userId, startDate, endDate],
    )) ?? 0;

    int completedTasks = Sqflite.firstIntValue(await db.rawQuery(
      "SELECT COUNT(*) FROM tasks WHERE userId = ? AND completed = 1 AND dueDate BETWEEN ? AND ?",
      [userId, startDate, endDate],
    )) ?? 0;

    int incompleteTasks = totalTasks - completedTasks;

    return {
      'total': totalTasks,
      'completed': completedTasks,
      'incomplete': incompleteTasks,
    };
  }

  Future<Map<String, int>> getTaskStatisticsAll(int userId) async {
    final db = await database;

    List<Map<String, dynamic>> total = await db.rawQuery(
        'SELECT COUNT(*) as total FROM tasks WHERE userId = ?',
        [userId]
    );

    List<Map<String, dynamic>> completed = await db.rawQuery(
        'SELECT COUNT(*) as completed FROM tasks WHERE userId = ? AND completed = 1',
        [userId]
    );

    List<Map<String, dynamic>> incomplete = await db.rawQuery(
        'SELECT COUNT(*) as incomplete FROM tasks WHERE userId = ? AND completed = 0',
        [userId]
    );

    return {
      'total': total.first['total'] ?? 0,
      'completed': completed.first['completed'] ?? 0,
      'incomplete': incomplete.first['incomplete'] ?? 0,
    };
  }
}