import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:frontend/services/api_service.dart';

class ParentDashboardScreen extends StatefulWidget {
  const ParentDashboardScreen({super.key});

  @override
  _ParentDashboardScreenState createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen> {
  List<dynamic> _progress = [];
  List<dynamic> _achievements = [];
  FlutterTts _tts = FlutterTts();
  bool _isSpeaking = false;
  bool _isLoading = true;
  String? _error;
  String _filter = 'All'; // Filter: All, Completed, In Progress
  Map<DateTime, int> _weeklyProgress = {};

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final progress = await ApiService.getStudentProgress();
      final achievements = await ApiService.getStudentAchievements();
      setState(() {
        _progress = progress ?? [];
        _achievements = achievements ?? [];
        _weeklyProgress = _calculateWeeklyProgress(progress);
        _error = null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error loading data: $e';
        _isLoading = false;
      });
    }
  }

  Map<DateTime, int> _calculateWeeklyProgress(List<dynamic> progress) {
    final Map<DateTime, int> weeklyProgress = {};
    for (var p in progress) {
      if (p['completedAt'] != null) {
        final date = DateTime.parse(p['completedAt']).toLocal();
        final weekStart = DateTime(date.year, date.month, date.day - date.weekday % 7);
        weeklyProgress[weekStart] = ((weeklyProgress[weekStart] ?? 0) + (p['completedSteps']?.length ?? 0)).toInt();
      }
    }
    return weeklyProgress;
  }

  String _getSuggestion() {
    final achievementCount = _achievements.length;
    final subjects = _achievements.map((a) => a['experimentId']['subjectArea'] ?? 'Other').toSet().toList();
    final subjectCounts = subjects.map((s) => _achievements.where((a) => a['experimentId']['subjectArea'] == s).length).toList();
    String recommendation = '';
    if (subjects.isNotEmpty) {
      final minCount = subjectCounts.reduce((a, b) => a < b ? a : b);
      final leastExplored = subjects[subjectCounts.indexOf(minCount)];
      recommendation = 'Try more $leastExplored experiments to diversify their learning.';
    }

    if (achievementCount >= 5) {
      return 'Excellent progress! Your child is excelling in science. $recommendation';
    } else if (achievementCount >= 3) {
      return 'Great job! Your child is making steady progress. $recommendation';
    } else if (achievementCount >= 1) {
      return 'Good start! Your child has earned some badges. $recommendation';
    } else {
      return 'Your child is just starting. Encourage them to try experiments in Chemistry, Physics, or Biology!';
    }
  }

  String _getSummaryText() {
    final completedCount = _progress.where((p) => p['status'] == 'completed').length;
    final totalExperiments = _progress.length;
    final badgeCount = _achievements.length;
    return 'Your child has completed $completedCount of $totalExperiments experiments and earned $badgeCount badges. ${_getSuggestion()}';
  }

  Future<void> _speakSummary() async {
    if (_isSpeaking) {
      await _tts.stop();
      setState(() => _isSpeaking = false);
    } else {
      await _tts.speak(_getSummaryText());
      setState(() => _isSpeaking = true);
      _tts.setCompletionHandler(() {
        setState(() => _isSpeaking = false);
      });
    }
  }

  Future<void> _speakExperimentDetails(Map<dynamic, dynamic> prog) async {
    if (_isSpeaking) {
      await _tts.stop();
      setState(() => _isSpeaking = false);
    } else {
      final text =
          '${prog['experimentId']['title'] ?? 'Untitled'}. Status: ${prog['status'] ?? 'Unknown'}. Completed ${prog['completedSteps']?.length ?? 0} of ${prog['experimentId']['steps']?.length ?? 0} steps.';
      await _tts.speak(text);
      setState(() => _isSpeaking = true);
      _tts.setCompletionHandler(() {
        setState(() => _isSpeaking = false);
      });
    }
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Parent Dashboard'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: Icon(_isSpeaking ? Icons.stop : Icons.volume_up),
            onPressed: _speakSummary,
            tooltip: 'Listen to Summary',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Summary Card
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Progress Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 8),
                              Text(_getSummaryText(), style: const TextStyle(fontSize: 14)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Filter Dropdown
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Filter Progress:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          Flexible(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 150),
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: _filter,
                                items: ['All', 'Completed', 'In Progress'].map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value, overflow: TextOverflow.ellipsis),
                                  );
                                }).toList(),
                                onChanged: (value) => setState(() => _filter = value!),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Pie Chart for Progress
                      const Text('Progress Analytics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 200,
                        width: double.infinity,
                        child: _progress.isEmpty
                            ? const Center(child: Text('No progress data available'))
                            : PieChart(
                                PieChartData(
                                  sections: [
                                    PieChartSectionData(
                                      color: const Color(0xFF4CAF50),
                                      value: _progress.where((p) => p['status'] == 'completed').length.toDouble(),
                                      title: 'Completed\n${((_progress.where((p) => p['status'] == 'completed').length / (_progress.length > 0 ? _progress.length : 1) * 100).toStringAsFixed(1))}%',
                                      radius: 60,
                                      titleStyle: const TextStyle(color: Colors.white, fontSize: 12),
                                    ),
                                    PieChartSectionData(
                                      color: const Color(0xFFFF9800),
                                      value: _progress.where((p) => p['status'] != 'completed' && p['status'] != null).length.toDouble(),
                                      title: 'In Progress\n${((_progress.where((p) => p['status'] != 'completed' && p['status'] != null).length / (_progress.length > 0 ? _progress.length : 1) * 100).toStringAsFixed(1))}%',
                                      radius: 60,
                                      titleStyle: const TextStyle(color: Colors.white, fontSize: 12),
                                    ),
                                  ],
                                  centerSpaceRadius: 40,
                                  sectionsSpace: 2,
                                  borderData: FlBorderData(show: false),
                                  pieTouchData: PieTouchData(
                                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                      if (event is FlTapUpEvent && pieTouchResponse != null) {
                                        final section = pieTouchResponse.touchedSection?.touchedSectionIndex;
                                        if (section != null) {
                                          final label = section == 0 ? 'Completed' : 'In Progress';
                                          final count = section == 0
                                              ? _progress.where((p) => p['status'] == 'completed').length
                                              : _progress.where((p) => p['status'] != 'completed' && p['status'] != null).length;
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('$label: $count experiments')),
                                          );
                                        }
                                      }
                                    },
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.circle, color: Color(0xFF4CAF50), size: 12),
                          const Text(' Completed', style: TextStyle(fontSize: 12)),
                          const SizedBox(width: 16),
                          const Icon(Icons.circle, color: Color(0xFFFF9800), size: 12),
                          const Text(' In Progress', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Bar Chart for Achievements
                      const Text('Achievements by Subject', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 200,
                        width: double.infinity,
                        child: _achievements.isEmpty
                            ? const Center(child: Text('No achievements data available'))
                            : BarChart(
                                BarChartData(
                                  barGroups: [
                                    BarChartGroupData(
                                      x: 0,
                                      barRods: [
                                        BarChartRodData(
                                          toY: _achievements.where((a) => a['experimentId']['subjectArea'] == 'Chemistry').length.toDouble(),
                                          color: const Color(0xFF2196F3),
                                          width: 20,
                                        ),
                                      ],
                                    ),
                                    BarChartGroupData(
                                      x: 1,
                                      barRods: [
                                        BarChartRodData(
                                          toY: _achievements.where((a) => a['experimentId']['subjectArea'] == 'Physics').length.toDouble(),
                                          color: const Color(0xFF4CAF50),
                                          width: 20,
                                        ),
                                      ],
                                    ),
                                    BarChartGroupData(
                                      x: 2,
                                      barRods: [
                                        BarChartRodData(
                                          toY: _achievements.where((a) => a['experimentId']['subjectArea'] == 'Biology').length.toDouble(),
                                          color: const Color(0xFFFF9800),
                                          width: 20,
                                        ),
                                      ],
                                    ),
                                  ],
                                  titlesData: FlTitlesData(
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 40,
                                        getTitlesWidget: (value, meta) => Text(
                                          value.toInt().toString(),
                                          style: const TextStyle(color: Colors.black, fontSize: 12),
                                        ),
                                      ),
                                      axisNameWidget: const Text('Achievements', style: TextStyle(color: Colors.black)),
                                    ),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (value, meta) => Text(
                                          value == 0 ? 'Chemistry' : value == 1 ? 'Physics' : 'Biology',
                                          style: const TextStyle(color: Colors.black, fontSize: 12),
                                        ),
                                      ),
                                      axisNameWidget: const Text('Subject Area', style: TextStyle(color: Colors.black)),
                                    ),
                                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  ),
                                  borderData: FlBorderData(show: false),
                                  barTouchData: BarTouchData(
                                    touchTooltipData: BarTouchTooltipData(
                                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                        final subject = groupIndex == 0 ? 'Chemistry' : groupIndex == 1 ? 'Physics' : 'Biology';
                                        return BarTooltipItem(
                                          '$subject\n${rod.toY.toInt()}',
                                          const TextStyle(color: Colors.white),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(height: 16),
                      // Line Chart for Weekly Progress
                      const Text('Weekly Progress', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 200,
                        width: double.infinity,
                        child: _weeklyProgress.isEmpty
                            ? const Center(child: Text('No weekly progress data available'))
                            : LineChart(
                                LineChartData(
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: _weeklyProgress.entries
                                          .toList()
                                          .asMap()
                                          .entries
                                          .map((e) => FlSpot(e.key.toDouble(), e.value.value.toDouble()))
                                          .toList()
                                        ..sort((a, b) => a.x.compareTo(b.x)),
                                      isCurved: true,
                                      color: const Color(0xFF2196F3),
                                      dotData: FlDotData(show: true),
                                    ),
                                  ],
                                  titlesData: FlTitlesData(
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 40,
                                        getTitlesWidget: (value, meta) => Text(
                                          value.toInt().toString(),
                                          style: const TextStyle(color: Colors.black, fontSize: 12),
                                        ),
                                      ),
                                      axisNameWidget: const Text('Steps Completed', style: TextStyle(color: Colors.black)),
                                    ),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (value, meta) {
                                          if (_weeklyProgress.isEmpty || value.toInt() >= _weeklyProgress.length) {
                                            return const Text('');
                                          }
                                          final date = _weeklyProgress.keys.toList()[value.toInt()];
                                          return Text(
                                            '${date.month}/${date.day}',
                                            style: const TextStyle(color: Colors.black, fontSize: 12),
                                          );
                                        },
                                      ),
                                      axisNameWidget: const Text('Week Starting', style: TextStyle(color: Colors.black)),
                                    ),
                                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  ),
                                  borderData: FlBorderData(show: false),
                                  lineTouchData: LineTouchData(
                                    touchTooltipData: LineTouchTooltipData(
                                      getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
                                        if (spot.x.toInt() >= _weeklyProgress.length) {
                                          return null;
                                        }
                                        final date = _weeklyProgress.keys.toList()[spot.x.toInt()];
                                        return LineTooltipItem(
                                          '${date.month}/${date.day}: ${spot.y.toInt()} steps',
                                          const TextStyle(color: Colors.white),
                                        );
                                      }).whereType<LineTooltipItem>().toList(),
                                    ),
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(height: 16),
                      // Detailed Experiment Progress
                      const Text('Experiment Progress', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      if (_progress.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('No experiments started yet.'),
                        )
                      else
                        ...(_filter == 'All'
                                ? _progress
                                : _filter == 'Completed'
                                    ? _progress.where((p) => p['status'] == 'completed')
                                    : _progress.where((p) => p['status'] != 'completed' && p['status'] != null))
                            .map((prog) => Card(
                                  margin: const EdgeInsets.symmetric(vertical: 8),
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  child: ExpansionTile(
                                    title: Text(prog['experimentId']['title'] ?? 'Untitled', overflow: TextOverflow.ellipsis),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Status: ${prog['status'] ?? 'Unknown'}'),
                                        const SizedBox(height: 4),
                                        LinearProgressIndicator(
                                          value: (prog['completedSteps']?.length ?? 0) / (prog['experimentId']['steps']?.length ?? 1),
                                          backgroundColor: Colors.grey[300],
                                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
                                        ),
                                      ],
                                    ),
                                    trailing: IconButton(
                                      icon: Icon(_isSpeaking ? Icons.stop : Icons.volume_up),
                                      onPressed: () => _speakExperimentDetails(prog),
                                    ),
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Steps: ${prog['completedSteps']?.length ?? 0}/${prog['experimentId']['steps']?.length ?? 0}',
                                              style: const TextStyle(fontWeight: FontWeight.w600),
                                            ),
                                            if (prog['completedAt'] != null)
                                              Text(
                                                'Completed: ${DateTime.parse(prog['completedAt']).toLocal().toString().substring(0, 16)}',
                                              ),
                                            const SizedBox(height: 8),
                                            ...?(prog['experimentId']['steps'] as List<dynamic>?)?.asMap().entries.map((entry) {
                                              final stepIndex = entry.key;
                                              final step = entry.value;
                                              final isCompleted = (prog['completedSteps'] as List<dynamic>?)?.contains(stepIndex + 1) ?? false;
                                              return ListTile(
                                                leading: Icon(
                                                  isCompleted ? Icons.check_circle : Icons.circle_outlined,
                                                  color: isCompleted ? Colors.green : Colors.grey,
                                                ),
                                                title: Text(
                                                  'Step ${stepIndex + 1}: ${step['text'] ?? 'No description'}',
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              );
                                            }).toList(),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                      const SizedBox(height: 16),
                      // Achievements List
                      const Text('Earned Badges', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      if (_achievements.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('No badges earned yet.'),
                        )
                      else
                        ..._achievements.map((ach) => Card(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                leading: const Icon(Icons.star, color: Colors.amber),
                                title: Text(ach['badge'] ?? 'Badge', overflow: TextOverflow.ellipsis),
                                subtitle: Text('For: ${ach['experimentId']['title'] ?? 'Untitled'}', overflow: TextOverflow.ellipsis),
                              ),
                            )),
                    ],
                  ),
                ),
    );
  }
}