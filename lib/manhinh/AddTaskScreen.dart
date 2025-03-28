import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import 'package:intl/intl.dart';

class AddTaskScreen extends StatefulWidget {
  final int userId;
  const AddTaskScreen({super.key, required this.userId});

  @override
  _AddTaskScreenState createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  int _priority = -1;
  bool _notification = false;
  DateTime? _selectedDateTime;

  final _formKey = GlobalKey<FormState>(); // Form Key to handle validation

  Future<void> _selectDueDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (pickedTime != null) {
        setState(() {
          _selectedDateTime = DateTime(
              pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute);
        });
      }
    }
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) { // Check if form is valid
      return;
    }

    String title = _titleController.text.trim();
    String description = _descriptionController.text.trim();

    if (_priority == -1) { // Check if the priority is not selected
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn mức độ ưu tiên!')),
      );
      return;
    }

    if (_selectedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ngày giờ!')),
      );
      return;
    }

    await _dbHelper.addTask(
      widget.userId,
      title,
      description,
      _priority,
      _notification ? 1 : 0,
      _selectedDateTime!.toIso8601String(),
    );

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Thêm Công Việc", style: TextStyle(color: Colors.white, fontSize: 22)),
        backgroundColor: Colors.blueGrey[800],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            elevation: 5,
            shadowColor: Colors.blueGrey.withOpacity(0.2),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey, // Add the form key here
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTextField("Tiêu đề", _titleController, "Nhập tiêu đề"),
                    const SizedBox(height: 16),
                    _buildTextField("Mô tả", _descriptionController, "Nhập mô tả", maxLines: 5),
                    const SizedBox(height: 16),
                    _buildPriorityDropdown(),
                    const SizedBox(height: 16),
                    _buildSwitchTile("Nhắc nhở", _notification, (value) => setState(() => _notification = value)),
                    const SizedBox(height: 16),
                    _buildDateTimePicker(),
                    const SizedBox(height: 24),
                    _buildSaveButton(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, String hint, {int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.blueGrey, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.blueGrey, width: 1),
        ),
        labelStyle: TextStyle(color: Colors.blueGrey[800], fontWeight: FontWeight.w500),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "$label không được để trống"; // Error message
        }
        return null; // Return null if valid
      },
    );
  }

  Widget _buildPriorityDropdown() {
    return DropdownButtonFormField<int>(
      value: _priority,
      items: const [
        DropdownMenuItem(value: -1, child: Text("Chọn mức độ ưu tiên", style: TextStyle(color: Colors.grey))),
        DropdownMenuItem(value: 0, child: Text("Thấp", style: TextStyle(color: Colors.green))),
        DropdownMenuItem(value: 1, child: Text("Trung bình", style: TextStyle(color: Colors.orange))),
        DropdownMenuItem(value: 2, child: Text("Cao", style: TextStyle(color: Colors.red))),
      ],
      onChanged: (value) => setState(() => _priority = value!),
      decoration: InputDecoration(
        labelText: "Mức độ ưu tiên",
        labelStyle: TextStyle(color: Colors.blueGrey[800], fontWeight: FontWeight.w500),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blueGrey, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blueGrey, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blueGrey, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        prefixIcon: const Icon(Icons.flag, color: Colors.orangeAccent),
      ),
      dropdownColor: Colors.white,
    );
  }

  Widget _buildSwitchTile(String label, bool value, Function(bool) onChanged) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blueGrey.withOpacity(0.2)),
      ),
      child: SwitchListTile(
        title: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        value: value,
        onChanged: onChanged,
        activeColor: Colors.blueGrey[800],
      ),
    );
  }

  Widget _buildDateTimePicker() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blueGrey.withOpacity(0.2)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _selectedDateTime == null ? "Chưa chọn ngày" : DateFormat("yyyy-MM-dd HH:mm").format(_selectedDateTime!),
              style: const TextStyle(fontSize: 16),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today, color: Colors.blueGrey),
            onPressed: () => _selectDueDateTime(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _saveTask,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueGrey[800],
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: const Text("Lưu công việc", style: TextStyle(fontSize: 18, color: Colors.white)),
      ),
    );
  }
}