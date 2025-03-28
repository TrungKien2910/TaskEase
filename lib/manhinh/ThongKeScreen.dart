import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';

class ThongKeScreen extends StatefulWidget {
  final int userId;

  const ThongKeScreen({super.key, required this.userId});

  @override
  State<ThongKeScreen> createState() => _ThongKeScreenState();
}

class _ThongKeScreenState extends State<ThongKeScreen> {
  late Future<Map<String, int>> _statistics;
  int? _selectedMonth;
  int? _selectedYear;
  bool _isFetchingAll = false;

  @override
  void initState() {
    super.initState();
    DateTime now = DateTime.now();
    _selectedMonth = now.month;
    _selectedYear = now.year;
    _fetchStatistics();
  }

  void _fetchStatistics({bool fetchAll = false}) {
    setState(() {
      _isFetchingAll = fetchAll;
      _statistics = fetchAll
          ? DatabaseHelper().getTaskStatisticsAll(widget.userId)
          : DatabaseHelper().getTaskStatistics(widget.userId, _selectedMonth!, _selectedYear!);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Thống kê công việc",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.blueGrey[800], // Màu app bar đồng nhất
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          _buildTimeSelector(),
          _buildAllStatsButton(),
          Expanded(
            child: Card(
              elevation: 5,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: FutureBuilder<Map<String, int>>(
                  future: _statistics,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text("Lỗi: ${snapshot.error}", style: TextStyle(color: Colors.blueGrey[800])));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Text(
                          "Không có dữ liệu.",
                          style: TextStyle(fontSize: 16, color: Colors.blueGrey[800]),
                        ),
                      );
                    }
                    return _buildBarChart(snapshot.data!);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSelector() {
    return Card(
      margin: const EdgeInsets.all(10),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DropdownButton<int>(
              value: _selectedMonth,
              items: List.generate(12, (index) => DropdownMenuItem(
                value: index + 1,
                child: Text(
                  DateFormat('MMMM').format(DateTime(0, index + 1)),
                  style: TextStyle(fontSize: 16, color: Colors.blueGrey[800]),
                ),
              )),
              onChanged: (newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedMonth = newValue;
                    _fetchStatistics();
                  });
                }
              },
              dropdownColor: Colors.white,
              icon: const Icon(Icons.arrow_drop_down, color: Colors.blueGrey),
              underline: Container(height: 2, color: Colors.blueGrey),
            ),
            const SizedBox(width: 10),
            DropdownButton<int>(
              value: _selectedYear,
              items: List.generate(5, (index) {
                int year = DateTime.now().year - index;
                return DropdownMenuItem(
                  value: year,
                  child: Text(
                    year.toString(),
                    style: TextStyle(fontSize: 16, color: Colors.blueGrey[800]),
                  ),
                );
              }),
              onChanged: (newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedYear = newValue;
                    _fetchStatistics();
                  });
                }
              },
              dropdownColor: Colors.white,
              icon: const Icon(Icons.arrow_drop_down, color: Colors.blueGrey),
              underline: Container(height: 2, color: Colors.blueGrey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllStatsButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueGrey[800], // Màu nút đồng nhất
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 3,
      ),
      onPressed: () => _fetchStatistics(fetchAll: true),
      child: const Text(
        "Thống kê tất cả",
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }

  Widget _buildBarChart(Map<String, int> stats) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceEvenly,
        maxY: (stats.values.reduce((a, b) => a > b ? a : b) + 5).toDouble(),
        groupsSpace: 20, // Tăng khoảng cách giữa các cột
        barGroups: [
          _buildBarChartGroup(0, "Tổng", stats['total'] ?? 0, Colors.blueGrey[800]!),
          _buildBarChartGroup(1, "Hoàn thành", stats['completed'] ?? 0, Colors.green[800]!),
          _buildBarChartGroup(2, "Chưa hoàn thành", stats['incomplete'] ?? 0, Colors.red[400]!),
        ],
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                switch (value.toInt()) {
                  case 0:
                    return _buildBottomTitle("Tổng");
                  case 1:
                    return _buildBottomTitle("Hoàn thành");
                  case 2:
                    return _buildBottomTitle("Chưa hoàn thành");
                }
                return Container();
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  Widget _buildBottomTitle(String title) {
    Map<String, String> shortTitles = {
      "Tổng": "T",
      "Hoàn thành": "HT",
      "Chưa hoàn thành": "CHT",
    };

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Text(
        shortTitles[title] ?? title,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blueGrey[800]),
        textAlign: TextAlign.center,
      ),
    );
  }

  BarChartGroupData _buildBarChartGroup(int x, String label, int value, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: value.toDouble(),
          color: color,
          width: 30,
          borderRadius: BorderRadius.circular(5),
        ),
      ],
    );
  }
}