import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';

class UpdateTaskScreen extends StatefulWidget {
  final Map<String, dynamic> task;
  const UpdateTaskScreen({super.key, required this.task});

  @override
  _UpdateTaskScreenState createState() => _UpdateTaskScreenState();
}

class _UpdateTaskScreenState extends State<UpdateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _dueDateController;
  int _priority = 0;
  bool _notification = false;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task['title']);
    _descriptionController = TextEditingController(text: widget.task['description']);
    _dueDateController = TextEditingController(text: widget.task['dueDate']);
    _priority = widget.task['priority'];
    _notification = widget.task['notification'] == 1;
    _completed = widget.task['completed'] == 1;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _dueDateController.dispose();
    super.dispose();
  }

  Future<void> _updateTask() async {
    if (_formKey.currentState!.validate()) {
      int result = await DatabaseHelper().updateTask(
        widget.task['id'],
        _titleController.text,
        _descriptionController.text,
        _priority,
        _notification ? 1 : 0,
        _dueDateController.text,
        _completed ? 1 : 0,
      );

      if (result > 0) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cập nhật thất bại!")),
        );
      }
    }
  }

  Future<void> _selectDueDateTime() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        setState(() {
          DateTime fullDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );

          _dueDateController.text = DateFormat('yyyy-MM-dd HH:mm').format(fullDateTime);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200], // Nền tổng thể
      appBar: AppBar(
        title: const Text("Cập nhật công việc", style: TextStyle(color: Colors.white, fontSize: 22)),
        backgroundColor: Colors.blueGrey[800], // Màu app bar
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 5,
          shadowColor: Colors.blueGrey.withOpacity(0.2),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextField("Tiêu đề", _titleController, "Nhập tiêu đề"),
                  const SizedBox(height: 16),
                  _buildTextField("Mô tả", _descriptionController, "Nhập mô tả", maxLines: 5),
                  const SizedBox(height: 16),
                  _buildDropdownField("Mức độ ưu tiên", _priority, {0: "Thấp", 1: "Trung Bình", 2: "Cao"},
                          (value) => setState(() => _priority = value)),
                  const SizedBox(height: 16),
                  _buildSwitchTile("Nhắc nhở", _notification, (value) => setState(() => _notification = value)),
                  const SizedBox(height: 16),
                  _buildDatePickerField("Hạn chót", _dueDateController),
                  const SizedBox(height: 16),
                  _buildSwitchTile("Trạng thái", _completed, (value) => setState(() => _completed = value)),
                  const SizedBox(height: 24),
                  _buildSaveButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _updateTask,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueGrey[800], // Màu nút
          foregroundColor: Colors.white, // Màu chữ
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 3,
        ),
        child: const Text("Lưu", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
        filled: true,
        fillColor: Colors.grey[100], // Màu nền input
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blueGrey, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blueGrey, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      ),
      validator: (value) => value == null || value.isEmpty ? "$label không được để trống" : null,
    );
  }

  Widget _buildDropdownField(String label, int? currentValue, Map<int, String> items, Function(int) onChanged) {
    return DropdownButtonFormField<int>(
      value: currentValue,
      items: items.entries.map((entry) => DropdownMenuItem<int>(
        value: entry.key,
        child: Text(
          entry.value,
          style: const TextStyle(fontSize: 16),
        ),
      )).toList(),
      onChanged: (value) => onChanged(value ?? 0),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.blueGrey[800], fontWeight: FontWeight.w500),
        filled: true,
        fillColor: Colors.grey[100], // Màu nền dịu nhẹ
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
        prefixIcon: const Icon(Icons.flag, color: Colors.blueGrey),
      ),
      dropdownColor: Colors.white, // Màu nền khi mở dropdown
    );
  }

  Widget _buildDatePickerField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        suffixIcon: IconButton(
          icon: const Icon(Icons.calendar_today, color: Colors.blueGrey),
          onPressed: _selectDueDateTime,
        ),
      ),
      validator: (value) => value == null || value.isEmpty ? "$label không được để trống" : null,
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
}