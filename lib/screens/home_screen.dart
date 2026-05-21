import 'package:flutter/material.dart';
import '../models/email_model.dart';
import '../services/email_storage_service.dart';
import 'compose_screen.dart';
import 'email_view_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late ValueNotifier<List<EmailModel>> _emailsNotifier;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _emailsNotifier = ValueNotifier<List<EmailModel>>([]);
    _loadEmails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailsNotifier.dispose();
    super.dispose();
  }

  Future<void> _loadEmails() async {
    final emails = await EmailStorageService.getAll();
    _emailsNotifier.value = emails;
  }

  Future<void> _deleteEmail(String id) async {
    await EmailStorageService.delete(id);
    _loadEmails();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email deleted')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mail Editor'),
        backgroundColor: Colors.blue,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.edit), text: 'Compose'),
            Tab(icon: Icon(Icons.inbox), text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ComposeScreen(),
          ValueListenableBuilder<List<EmailModel>>(
            valueListenable: _emailsNotifier,
            builder: (context, emails, _) => _buildHistoryTab(emails),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(List<EmailModel> emails) {
    if (emails.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No emails yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Compose an email to get started',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: emails.length,
      itemBuilder: (context, index) {
        final email = emails[index];
        return _EmailListItem(
          email: email,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EmailViewScreen(email: email),
              ),
            );
          },
          onDelete: () => _deleteEmail(email.id),
        );
      },
    );
  }
}

class _EmailListItem extends StatelessWidget {
  final EmailModel email;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _EmailListItem({
    required this.email,
    required this.onTap,
    required this.onDelete,
  });

  String _getPreview() {
    final text = email.body.replaceAll('\n', ' ').trim();
    return text.length > 100 ? '${text.substring(0, 100)}...' : text;
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(email.id),
      onDismissed: (_) => onDelete(),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Material(
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Text(
                    email.to.isNotEmpty ? email.to[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              email.subject,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${email.createdAt.day}/${email.createdAt.month}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              email.to,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getPreview(),
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
