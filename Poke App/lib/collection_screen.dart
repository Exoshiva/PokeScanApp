import 'package:flutter/material.dart';
import 'supabase_service.dart';

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  final _supabase = SupabaseService();
  List<UserCard> _cards = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadCollection();
  }
  
  Future<void> _loadCollection() async {
    setState(() => _isLoading = true);
    
    final cards = await _supabase.getUserCards(orderBy: 'created_at', ascending: false);
    final stats = await _supabase.getCollectionStats();
    
    if (mounted) {
      setState(() {
        _cards = cards;
        _stats = stats;
        _isLoading = false;
      });
    }
  }
  
  Future<void> _deleteCard(UserCard card) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F3A),
        title: const Text('Löschen?', style: TextStyle(color: Colors.white)),
        content: Text('Soll "${card.name}" gelöscht werden?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Nein')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Ja', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    
    if (confirm == true) {
      await _supabase.deleteCard(card.id);
      _loadCollection();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1F3A),
        title: const Text('Meine Sammlung'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _supabase.signOut();
              if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadCollection,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF4A90E2), Color(0xFF357ABD)]),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatItem(icon: Icons.style, label: 'Karten', value: '${_stats['total_cards'] ?? 0}'),
                          _StatItem(icon: Icons.euro, label: 'Wert', value: '${(_stats['total_collection_value'] ?? 0).toStringAsFixed(2)}€'),
                        ],
                      ),
                    ),
                  ),
                  if (_cards.isEmpty)
                    const SliverFillRemaining(
                      child: Center(child: Text('Noch keine Karten gescannt.', style: TextStyle(color: Colors.white54))),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, childAspectRatio: 0.7, crossAxisSpacing: 12, mainAxisSpacing: 12,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final card = _cards[index];
                            return GestureDetector(
                              onLongPress: () => _deleteCard(card),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A1F3A),
                                  borderRadius: BorderRadius.circular(16),
                                  image: card.imageUrl != null 
                                      ? DecorationImage(image: NetworkImage(card.imageUrl!), fit: BoxFit.cover)
                                      : null,
                                ),
                                child: Align(
                                  alignment: Alignment.bottomCenter,
                                  child: Container(
                                    width: double.infinity,
                                    color: Colors.black54,
                                    padding: const EdgeInsets.all(8),
                                    child: Text(
                                      "${card.quantity}x ${card.name}", 
                                      style: const TextStyle(color: Colors.white, fontSize: 12),
                                      maxLines: 1, overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                          childCount: _cards.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatItem({required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Icon(icon, color: Colors.white, size: 28),
      Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
      Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
    ]);
  }
}