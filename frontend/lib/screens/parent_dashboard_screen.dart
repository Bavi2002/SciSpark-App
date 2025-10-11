import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:frontend/services/api_service.dart';
import 'package:intl/intl.dart';

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
  String _filter = 'All';
  Map<DateTime, int> _weeklyProgress = {};
  final Map<String, Map<String, dynamic>> _experimentCache = {};

  // Theme colors
  final Color _primaryColor = const Color.fromRGBO(124, 58, 237, 1);
  final Color _backgroundColor = const Color(0xFFF8F9FA);
  final Color _cardColor = Colors.white;
  final Color _textColor = Colors.black;
  final Color _secondaryTextColor = Colors.black87;
  final Color _disabledColor = Colors.black54;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    debugPrint('Fetching parent dashboard data');
    setState(() => _isLoading = true);
    try {
      final progress = await ApiService.getStudentProgress();
      for (var p in progress ?? []) {
        final experimentId = p['experimentId']?['_id'];
        if (experimentId != null && (p['experimentId']?['steps'] == null || p['experimentId']['steps'].isEmpty)) {
          debugPrint('Steps missing for experiment $experimentId, fetching full data');
          if (!_experimentCache.containsKey(experimentId)) {
            final experiment = await ApiService.getExperimentById(experimentId);
            _experimentCache[experimentId] = experiment;
            p['experimentId'] = experiment;
          } else {
            p['experimentId'] = _experimentCache[experimentId];
          }
        }
      }
      final achievements = await ApiService.getStudentAchievements();
      if (mounted) {
        setState(() {
          _progress = progress ?? [];
          _achievements = achievements ?? [];
          _weeklyProgress = _calculateWeeklyProgress(progress ?? []);
          _error = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Fetch data error: $e');
      if (mounted) {
        setState(() {
          _error = 'Error loading data: $e';
          _isLoading = false;
        });
      }
    }
  }

  Map<DateTime, int> _calculateWeeklyProgress(List<dynamic> progress) {
    final Map<DateTime, int> weeklyProgress = {};
    final now = DateTime.now().toLocal();
    for (int i = 0; i < 4; i++) {
      final weekStart = DateTime(now.year, now.month, now.day - (now.weekday - 1) - (i * 7));
      weeklyProgress[weekStart] = 0;
    }
    for (var p in progress) {
      final completedSteps = p['completedSteps']?.length ?? 0;
      final date = p['completedAt'] != null
          ? DateTime.parse(p['completedAt']).toLocal()
          : now;
      final weekStart = DateTime(date.year, date.month, date.day - (date.weekday - 1));
      weeklyProgress[weekStart] = ((weeklyProgress[weekStart] ?? 0) + completedSteps).toInt();
    }
    return weeklyProgress;
  }

  String _getSuggestion() {
    final achievementCount = _achievements.length;
    final subjects = _achievements.map((a) => a['experimentId']?['subject'] ?? 'Other').toSet().toList();
    final subjectCounts = subjects.map((s) => _achievements.where((a) => a['experimentId']?['subject'] == s).length).toList();
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
    try {
      if (_isSpeaking) {
        await _tts.stop();
        if (mounted) setState(() => _isSpeaking = false);
      } else {
        await _tts.speak(_getSummaryText());
        if (mounted) setState(() => _isSpeaking = true);
        _tts.setCompletionHandler(() {
          if (mounted) setState(() => _isSpeaking = false);
        });
      }
    } catch (e) {
      debugPrint('TTS error in speakSummary: $e');
    }
  }

  Future<void> _speakExperimentDetails(Map<dynamic, dynamic> prog) async {
    try {
      if (_isSpeaking) {
        await _tts.stop();
        if (mounted) setState(() => _isSpeaking = false);
      } else {
        final totalSteps = prog['experimentId']?['steps']?.length ?? 0;
        final text =
            '${prog['experimentId']?['title'] ?? 'Untitled'}. Status: ${prog['status'] ?? 'Unknown'}. Completed ${prog['completedSteps']?.length ?? 0} of $totalSteps steps.';
        await _tts.speak(text);
        if (mounted) setState(() => _isSpeaking = true);
        _tts.setCompletionHandler(() {
          if (mounted) setState(() => _isSpeaking = false);
        });
      }
    } catch (e) {
      debugPrint('TTS error in speakExperimentDetails: $e');
    }
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('Building ParentDashboardScreen: _isLoading=$_isLoading, _progress=${_progress.length}, _achievements=${_achievements.length}');
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Parent Dashboard',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        elevation: 0,
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: _isSpeaking ? Colors.white.withOpacity(0.2) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(_isSpeaking ? Icons.stop_rounded : Icons.volume_up_rounded),
              onPressed: _speakSummary,
              tooltip: 'Listen to Summary',
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: _primaryColor,
                strokeWidth: 3,
              ),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: _primaryColor.withOpacity(0.7)),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: TextStyle(color: _textColor, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: _primaryColor,
                  onRefresh: _fetchData,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Summary Card with gradient accent
                        Container(
                          decoration: BoxDecoration(
                            color: _primaryColor,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: _primaryColor.withOpacity(0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.insights_rounded,
                                        color: Colors.white,
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    const Text(
                                      'Progress Summary',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _getSuggestion(),
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.white.withOpacity(0.9),
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Filter Section
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          decoration: BoxDecoration(
                            color: _cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _primaryColor.withOpacity(0.1)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Filter Progress',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.3,
                                  color: _textColor,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _primaryColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: DropdownButton<String>(
                                  value: _filter,
                                  underline: const SizedBox(),
                                  dropdownColor: _primaryColor,
                                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white),
                                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                                  items: ['All', 'Completed', 'In Progress'].map((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                                  onChanged: (value) => setState(() => _filter = value!),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Progress Analytics
                        _buildSectionTitle('Progress Analytics', Icons.pie_chart_rounded),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: _cardColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _primaryColor.withOpacity(0.1)),
                          ),
                          child: Column(
                            children: [
                              SizedBox(
                                height: 220,
                                child: _progress.isEmpty
                                    ? Center(child: Text('No progress data available', style: TextStyle(color: _disabledColor)))
                                    : PieChart(
                                        PieChartData(
                                          sections: [
                                            PieChartSectionData(
                                              color: _primaryColor,
                                              value: _progress.where((p) => p['status'] == 'completed').length.toDouble(),
                                              title: 'Completed\n${((_progress.where((p) => p['status'] == 'completed').length / (_progress.length > 0 ? _progress.length : 1) * 100).toStringAsFixed(1))}%',
                                              radius: 70,
                                              titleStyle: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            PieChartSectionData(
                                              color: Colors.grey[300],
                                              value: _progress.where((p) => p['status'] != 'completed' && p['status'] != null).length.toDouble(),
                                              title: 'In Progress\n${((_progress.where((p) => p['status'] != 'completed' && p['status'] != null).length / (_progress.length > 0 ? _progress.length : 1) * 100).toStringAsFixed(1))}%',
                                              radius: 70,
                                              titleStyle: TextStyle(
                                                color: _textColor,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                          centerSpaceRadius: 50,
                                          sectionsSpace: 4,
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
                                                    SnackBar(
                                                      content: Text('$label: $count experiments'),
                                                      backgroundColor: _primaryColor,
                                                      behavior: SnackBarBehavior.floating,
                                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                    ),
                                                  );
                                                }
                                              }
                                            },
                                          ),
                                        ),
                                      ),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildLegendItem(_primaryColor, 'Completed'),
                                  const SizedBox(width: 24),
                                  _buildLegendItem(Colors.grey[300]!, 'In Progress'),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Achievements by Subject
                        _buildSectionTitle('Achievements by Subject', Icons.emoji_events_rounded),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: _cardColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _primaryColor.withOpacity(0.1)),
                          ),
                          child: SizedBox(
                            height: 220,
                            child: _achievements.isEmpty
                                ? Center(child: Text('No achievements data available', style: TextStyle(color: _disabledColor)))
                                : BarChart(
                                    BarChartData(
                                      barGroups: [
                                        BarChartGroupData(
                                          x: 0,
                                          barRods: [
                                            BarChartRodData(
                                              toY: _achievements.where((a) => a['experimentId']?['subject'] == 'Chemistry').length.toDouble(),
                                              color: _primaryColor,
                                              width: 32,
                                              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                                            ),
                                          ],
                                        ),
                                        BarChartGroupData(
                                          x: 1,
                                          barRods: [
                                            BarChartRodData(
                                              toY: _achievements.where((a) => a['experimentId']?['subject'] == 'Physics').length.toDouble(),
                                              color: _primaryColor.withOpacity(0.7),
                                              width: 32,
                                              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                                            ),
                                          ],
                                        ),
                                        BarChartGroupData(
                                          x: 2,
                                          barRods: [
                                            BarChartRodData(
                                              toY: _achievements.where((a) => a['experimentId']?['subject'] == 'Biology').length.toDouble(),
                                              color: _primaryColor.withOpacity(0.5),
                                              width: 32,
                                              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
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
                                              style: TextStyle(color: _secondaryTextColor, fontSize: 12, fontWeight: FontWeight.w500),
                                            ),
                                          ),
                                        ),
                                        bottomTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            getTitlesWidget: (value, meta) => Padding(
                                              padding: const EdgeInsets.only(top: 8),
                                              child: Text(
                                                value == 0 ? 'Chemistry' : value == 1 ? 'Physics' : 'Biology',
                                                style: TextStyle(color: _secondaryTextColor, fontSize: 12, fontWeight: FontWeight.w600),
                                              ),
                                            ),
                                          ),
                                        ),
                                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                      ),
                                      borderData: FlBorderData(show: false),
                                      gridData: FlGridData(show: false),
                                      barTouchData: BarTouchData(
                                        touchTooltipData: BarTouchTooltipData(
                                          getTooltipColor: (group) => _primaryColor,
                                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                            final subject = groupIndex == 0 ? 'Chemistry' : groupIndex == 1 ? 'Physics' : 'Biology';
                                            return BarTooltipItem(
                                              '$subject\n${rod.toY.toInt()}',
                                              const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Weekly Progress
                        _buildSectionTitle('Weekly Progress', Icons.show_chart_rounded),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: _cardColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _primaryColor.withOpacity(0.1)),
                          ),
                          child: SizedBox(
                            height: 220,
                            child: _weeklyProgress.isEmpty
                                ? Center(child: Text('No weekly progress data available', style: TextStyle(color: _disabledColor)))
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
                                          color: _primaryColor,
                                          barWidth: 3,
                                          dotData: FlDotData(
                                            show: true,
                                            getDotPainter: (spot, percent, barData, index) {
                                              return FlDotCirclePainter(
                                                radius: 5,
                                                color: _primaryColor,
                                                strokeWidth: 2,
                                                strokeColor: Colors.white,
                                              );
                                            },
                                          ),
                                          belowBarData: BarAreaData(
                                            show: true,
                                            color: _primaryColor.withOpacity(0.1),
                                          ),
                                        ),
                                      ],
                                      titlesData: FlTitlesData(
                                        leftTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            reservedSize: 40,
                                            getTitlesWidget: (value, meta) => Text(
                                              value.toInt().toString(),
                                              style: TextStyle(color: _secondaryTextColor, fontSize: 12, fontWeight: FontWeight.w500),
                                            ),
                                          ),
                                        ),
                                        bottomTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            getTitlesWidget: (value, meta) {
                                              final sortedKeys = _weeklyProgress.keys.toList()..sort();
                                              if (value.toInt() >= sortedKeys.length || _weeklyProgress.isEmpty) {
                                                return const Text('');
                                              }
                                              final date = sortedKeys[value.toInt()];
                                              return Padding(
                                                padding: const EdgeInsets.only(top: 8),
                                                child: Text(
                                                  '${date.month}/${date.day}',
                                                  style: TextStyle(color: _secondaryTextColor, fontSize: 11, fontWeight: FontWeight.w500),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                      ),
                                      borderData: FlBorderData(show: false),
                                      gridData: FlGridData(
                                        show: true,
                                        drawVerticalLine: false,
                                        getDrawingHorizontalLine: (value) => FlLine(
                                          color: _primaryColor.withOpacity(0.1),
                                          strokeWidth: 1,
                                        ),
                                      ),
                                      lineTouchData: LineTouchData(
                                        touchTooltipData: LineTouchTooltipData(
                                          getTooltipColor: (touchedSpot) => _primaryColor,
                                          getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
                                            final sortedKeys = _weeklyProgress.keys.toList()..sort();
                                            if (spot.x.toInt() >= sortedKeys.length) {
                                              return null;
                                            }
                                            final date = sortedKeys[spot.x.toInt()];
                                            return LineTooltipItem(
                                              '${date.month}/${date.day}\n${spot.y.toInt()} steps',
                                              const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                            );
                                          }).whereType<LineTooltipItem>().toList(),
                                        ),
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Experiment Progress
                        _buildSectionTitle('Experiment Progress', Icons.science_rounded),
                        const SizedBox(height: 16),
                        if (_progress.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: _cardColor,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: _primaryColor.withOpacity(0.1)),
                            ),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(Icons.science_outlined, size: 48, color: _primaryColor.withOpacity(0.3)),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No experiments started yet.',
                                    style: TextStyle(color: _disabledColor, fontSize: 15),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ...(_filter == 'All'
                                  ? _progress
                                  : _filter == 'Completed'
                                      ? _progress.where((p) => p['status'] == 'completed')
                                      : _progress.where((p) => p['status'] != 'completed' && p['status'] != null))
                              .map((prog) {
                                final totalSteps = prog['experimentId']?['steps']?.length ?? 0;
                                final completedSteps = prog['completedSteps']?.length ?? 0;
                                final isCompleted = prog['status'] == 'completed';
                                
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: _cardColor,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isCompleted ? _primaryColor : _primaryColor.withOpacity(0.1),
                                      width: isCompleted ? 2 : 1,
                                    ),
                                  ),
                                  child: Theme(
                                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                                    child: ExpansionTile(
                                      tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                      childrenPadding: const EdgeInsets.all(20),
                                      leading: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: isCompleted ? _primaryColor : Colors.grey[200],
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          isCompleted ? Icons.check_circle_rounded : Icons.hourglass_empty_rounded,
                                          color: isCompleted ? Colors.white : _disabledColor,
                                          size: 24,
                                        ),
                                      ),
                                      title: Text(
                                        prog['experimentId']?['title'] ?? 'Untitled',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                          letterSpacing: -0.3,
                                          color: _textColor,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: isCompleted ? _primaryColor : Colors.grey[300],
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              prog['status'] ?? 'Unknown',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: isCompleted ? Colors.white : _secondaryTextColor,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: LinearProgressIndicator(
                                              value: totalSteps > 0 ? completedSteps / totalSteps : 0.0,
                                              backgroundColor: Colors.grey[200],
                                              color: _primaryColor,
                                              minHeight: 8,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            '$completedSteps of $totalSteps steps completed',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: _secondaryTextColor.withOpacity(0.6),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      trailing: Container(
                                        decoration: BoxDecoration(
                                          color: _isSpeaking ? _primaryColor.withOpacity(0.1) : Colors.transparent,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: IconButton(
                                          icon: Icon(
                                            _isSpeaking ? Icons.stop_rounded : Icons.volume_up_rounded,
                                            color: _primaryColor,
                                          ),
                                          onPressed: () => _speakExperimentDetails(prog),
                                        ),
                                      ),
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(20),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[50],
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(Icons.format_list_numbered_rounded, size: 20, color: _primaryColor.withOpacity(0.7)),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    'Steps: $completedSteps/$totalSteps',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 15,
                                                      color: _textColor,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              if (prog['completedAt'] != null) ...[
                                                const SizedBox(height: 12),
                                                Row(
                                                  children: [
                                                    Icon(Icons.check_circle_outline_rounded, size: 20, color: _primaryColor.withOpacity(0.7)),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      'Completed: ${_formatDate(prog['completedAt'])}',
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        color: _secondaryTextColor.withOpacity(0.7),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                              const SizedBox(height: 16),
                                              Divider(height: 1, color: _primaryColor.withOpacity(0.1)),
                                              const SizedBox(height: 16),
                                              ...?(prog['experimentId']?['steps'] as List<dynamic>?)?.asMap().entries.map((entry) {
                                                final stepIndex = entry.key;
                                                final step = entry.value;
                                                final isStepCompleted = (prog['completedSteps'] as List<dynamic>?)?.contains(stepIndex + 1) ?? false;
                                                return Container(
                                                  margin: const EdgeInsets.only(bottom: 12),
                                                  padding: const EdgeInsets.all(16),
                                                  decoration: BoxDecoration(
                                                    color: isStepCompleted ? _primaryColor : _cardColor,
                                                    borderRadius: BorderRadius.circular(12),
                                                    border: Border.all(
                                                      color: isStepCompleted ? _primaryColor : _primaryColor.withOpacity(0.1),
                                                    ),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Container(
                                                        padding: const EdgeInsets.all(8),
                                                        decoration: BoxDecoration(
                                                          color: isStepCompleted ? Colors.white : Colors.grey[100],
                                                          borderRadius: BorderRadius.circular(8),
                                                        ),
                                                        child: Icon(
                                                          isStepCompleted ? Icons.check_rounded : Icons.circle_outlined,
                                                          color: isStepCompleted ? _primaryColor : Colors.black38,
                                                          size: 20,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 12),
                                                      Expanded(
                                                        child: Text(
                                                          'Step ${stepIndex + 1}: ${step['instruction'] ?? 'No description'}',
                                                          style: TextStyle(
                                                            fontSize: 14,
                                                            color: isStepCompleted ? Colors.white : _secondaryTextColor,
                                                            fontWeight: isStepCompleted ? FontWeight.w500 : FontWeight.normal,
                                                          ),
                                                          overflow: TextOverflow.ellipsis,
                                                          maxLines: 2,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              }).toList() ?? [],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                        const SizedBox(height: 32),

                        // Earned Badges
                        _buildSectionTitle('Earned Badges', Icons.stars_rounded),
                        const SizedBox(height: 16),
                        if (_achievements.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: _cardColor,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: _primaryColor.withOpacity(0.1)),
                            ),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(Icons.emoji_events_outlined, size: 48, color: _primaryColor.withOpacity(0.3)),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No badges earned yet.',
                                    style: TextStyle(color: _disabledColor, fontSize: 15),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ..._achievements.map((ach) => Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: _cardColor,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: _primaryColor.withOpacity(0.1)),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  leading: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: _primaryColor,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.star_rounded,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  title: Text(
                                    ach['badge'] ?? 'Badge',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                      letterSpacing: -0.3,
                                      color: _textColor,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      'For: ${ach['experimentId']?['title'] ?? 'Untitled'}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: _secondaryTextColor.withOpacity(0.6),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              )),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 24, color: _primaryColor),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: _textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: _secondaryTextColor,
          ),
        ),
      ],
    );
  }

  String _formatDate(String? date) {
    if (date == null) return 'N/A';
    try {
      final parsedDate = DateTime.parse(date).toLocal();
      return DateFormat('MMM dd, yyyy, HH:mm').format(parsedDate);
    } catch (e) {
      return 'Invalid Date';
    }
  }
}