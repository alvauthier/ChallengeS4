import 'package:flutter/material.dart';
import 'package:weezemaster/core/models/log.dart';
import 'package:weezemaster/core/services/api_services.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  _LogsScreenState createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<Log>> _logsFuture;
  DateTime _selectedDate = DateTime.now();
  String? _selectedEvent;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _logsFuture = ApiServices.getLogs(date: _selectedDate);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    setState(() {
      switch (_tabController.index) {
        case 0:
          _selectedEvent = null;
          break;
        case 1:
          _selectedEvent = "TicketPurchased";
          break;
        case 2:
          _selectedEvent = "ConcertAdded";
          break;
        case 3:
          _selectedEvent = "UserAuthenticated";
          break;
        case 4:
          _selectedEvent = "errorEvent";
          break;
      }
      _logsFuture = ApiServices.getLogs(date: _selectedDate, event: _selectedEvent);
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _logsFuture = ApiServices.getLogs(date: _selectedDate, event: _selectedEvent);
      });
    }
  }

  void _previousDay() {
    setState(() {
      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
      _logsFuture = ApiServices.getLogs(date: _selectedDate, event: _selectedEvent);
    });
  }

  void _nextDay() {
    if (!_isToday(_selectedDate)) {
      setState(() {
        _selectedDate = _selectedDate.add(const Duration(days: 1));
        _logsFuture = ApiServices.getLogs(date: _selectedDate, event: _selectedEvent);
      });
    }
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Logs"),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: "Tous les logs"),
            Tab(text: "Tickets réservés"),
            Tab(text: "Concerts ajoutés"),
            Tab(text: "Connexions"),
            Tab(text: "Erreurs"),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_left),
                  onPressed: _previousDay,
                ),
                TextButton(
                  onPressed: () => _selectDate(context),
                  child: Text(
                    "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}",
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_right),
                  onPressed: _isToday(_selectedDate) ? null : _nextDay,
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildLogsTab(),
                _buildLogsTab(),
                _buildLogsTab(),
                _buildLogsTab(),
                _buildLogsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogsTab() {
    return FutureBuilder<List<Log>>(
      future: _logsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Aucun log disponible.'));
        } else {
          List<Log> logs = snapshot.data!;
          return ListView.separated(
            itemCount: logs.length,
            separatorBuilder: (context, index) => const Divider(color: Colors.grey),
            itemBuilder: (context, index) {
              Log log = logs[index];
              String title = log.message ?? 'Aucun message';
              if (log.method != null && log.status != null && log.uri != null) {
                title = '${log.method} ${log.uri}';
              }
              return ListTile(
                title: Text(title),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Heure: ${(log.time).toLocal()}"),
                    if (log.level != null) Text("Niveau: ${log.level}"),
                    if (log.method != null) Text("Méthode: ${log.method}"),
                    if (log.status != null) Text("Statut: ${log.status}"),
                    if (log.latencyHuman != null) Text("Latence: ${log.latencyHuman}"),
                    if (log.error != null) Text("Erreur: ${log.error}"),
                  ],
                ),
              );
            },
          );
        }
      },
    );
  }
}
