import 'package:flutter/material.dart';
import '../../models/app_models.dart';
import '../../services/supabase_client.dart';
import '../../widgets/common_widgets.dart';
import '../messages/messages_screen.dart';

class PartnersScreen extends StatefulWidget {
  final UserProfile currentProfile;

  const PartnersScreen({super.key, required this.currentProfile});

  @override
  State createState() => _PartnersScreenState();
}

class _PartnersScreenState extends State {
  String _searchQuery = '';
  bool _onlyLanguageMatches = false;
  bool _isLoading = true;
  List _partners = [];

  @override
  void initState() {
    super.initState();
    _loadPartners();
  }

  Future _loadPartners() async {
    final w = widget as PartnersScreen;
    try {
      final rows = await supabase
          .from('profiles')
          .select()
          .neq('id', w.currentProfile.id)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _partners = (rows as List).map((r) => UserProfile.fromMap(r as Map)).toList();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = widget as PartnersScreen;
    final filtered = _partners.where((p) {
      final partner = p as UserProfile;
      final matchesQuery = _searchQuery.isEmpty ||
          partner.handle.toLowerCase().contains(_searchQuery) ||
          partner.nativeLang.toLowerCase().contains(_searchQuery) ||
          partner.learningLang.toLowerCase().contains(_searchQuery);
      final matchesLang = !_onlyLanguageMatches ||
          partner.nativeLang.toLowerCase() == w.currentProfile.learningLang.toLowerCase();
      return matchesQuery && matchesLang;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fellow Readers'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadPartners),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search by @handle or language...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Theme.of(context).cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Theme.of(context).dividerColor),
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FilterChip(
                label: Text('Speaks ${w.currentProfile.learningLang}'),
                selected: _onlyLanguageMatches,
                onSelected: (val) => setState(() => _onlyLanguageMatches = val),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                ? Center(
                    child: Text(
                      'No matching readers found.',
                      style: TextStyle(color: Theme.of(context).disabledColor),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final partner = filtered[index] as UserProfile;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: ParleyAvatar(profile: partner),
                          title: Text('${partner.handle} ${partner.countryFlag}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${partner.gender} • ${partner.country} • Speaks ${partner.nativeLang}'),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PartnerDetailScreen(
                                  currentProfile: w.currentProfile,
                                  partner: partner,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class PartnerDetailScreen extends StatelessWidget {
  final UserProfile currentProfile;
  final UserProfile partner;

  const PartnerDetailScreen({
    super.key,
    required this.currentProfile,
    required this.partner,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(partner.handle), actions: [PopupMenuButton(onSelected: (v) async { if (v == "block") { await supabase.from("blocked_users").upsert({"blocker_id": currentProfile.id, "blocked_id": partner.id}); if (context.mounted) Navigator.of(context).popUntil((r) => r.isFirst); } else { await supabase.from("user_reports").insert({"reporter_id": currentProfile.id, "reported_id": partner.id, "reason": "Reported"}); if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Report submitted."))); } }, itemBuilder: (_) => const [PopupMenuItem(value: "report", child: Text("Report User")), PopupMenuItem(value: "block", child: Text("Block User", style: TextStyle(color: Colors.red)))])]),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            ParleyAvatar(profile: partner, radius: 48),
            const SizedBox(height: 16),
            Text(partner.handle, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              children: [
                Chip(label: Text('${partner.countryFlag} ${partner.country}')), Chip(label: Text(partner.gender)), Chip(label: Text('Native: ${partner.nativeLang}')),
                Chip(label: Text('Learning: ${partner.learningLang}')),
              ],
            ),
            const SizedBox(height: 24),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('About Me', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                partner.bio.isEmpty ? 'No bio provided yet.' : partner.bio,
                style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.chat),
                label: Text('Message ${partner.handle}'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        currentProfile: currentProfile,
                        partner: partner,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
