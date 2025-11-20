import 'package:supabase_flutter/supabase_flutter.dart';
import 'card_scanner_service.dart';

/// Model für User-spezifische Karten-Daten
class UserCard {
  final int id;
  final String userId;
  final String apiCardId;
  final String name;
  final String? setName;
  final String? cardNumber;
  final String? imageUrl;
  final String? rarity;
  
  // User-spezifische Felder
  final String condition;
  final double? purchasePriceEur;
  final double? currentMarketPriceEur;
  final int quantity;
  final bool isFoil;
  final DateTime createdAt;
  
  UserCard({
    required this.id,
    required this.userId,
    required this.apiCardId,
    required this.name,
    this.setName,
    this.cardNumber,
    this.imageUrl,
    this.rarity,
    this.condition = 'Near Mint',
    this.purchasePriceEur,
    this.currentMarketPriceEur,
    this.quantity = 1,
    this.isFoil = false,
    required this.createdAt,
  });
  
  factory UserCard.fromJson(Map<String, dynamic> json) {
    return UserCard(
      id: json['id'] as int,
      userId: json['user_id'] as String,
      apiCardId: json['api_card_id'] as String,
      name: json['name'] as String,
      setName: json['set_name'] as String?,
      cardNumber: json['card_number'] as String?,
      imageUrl: json['image_url'] as String?,
      rarity: json['rarity'] as String?,
      condition: json['condition'] as String? ?? 'Near Mint',
      purchasePriceEur: json['purchase_price_eur'] != null 
          ? (json['purchase_price_eur'] as num).toDouble() 
          : null,
      currentMarketPriceEur: json['current_market_price_eur'] != null
          ? (json['current_market_price_eur'] as num).toDouble()
          : null,
      quantity: json['quantity'] as int? ?? 1,
      isFoil: json['is_foil'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

/// Service für Supabase Datenbank-Operationen
class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();
  
  SupabaseClient get _client => Supabase.instance.client;
  
  /// Initialisiert Supabase (muss in main.dart aufgerufen werden)
  static Future<void> initialize({
    required String supabaseUrl,
    required String supabaseAnonKey,
  }) async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }
  
  User? get currentUser => _client.auth.currentUser;
  bool get isLoggedIn => currentUser != null;
  
  // Stream für Auth-Änderungen (Login/Logout)
  Stream<AuthState> getAuthStateChange() {
    return _client.auth.onAuthStateChange;
  }

  // Auth
  Future<AuthResponse> signUp({required String email, required String password}) async {
    return await _client.auth.signUp(email: email, password: password);
  }
  
  Future<AuthResponse> signIn({required String email, required String password}) async {
    return await _client.auth.signInWithPassword(email: email, password: password);
  }
  
  Future<void> signOut() async {
    await _client.auth.signOut();
  }
  
  // Datenbank: Karte hinzufügen
  Future<void> addCardToCollection({
    required PokemonCard card,
    String condition = 'Near Mint',
  }) async {
    if (!isLoggedIn) throw Exception('User muss eingeloggt sein');
      
    // Prüfe ob Karte bereits existiert
    final existing = await _client
        .from('user_cards')
        .select()
        .eq('user_id', currentUser!.id)
        .eq('api_card_id', card.id)
        .maybeSingle();
    
    if (existing != null) {
      // Erhöhe Anzahl
      await _client
          .from('user_cards')
          .update({'quantity': (existing['quantity'] as int) + 1})
          .eq('id', existing['id']);
    } else {
      // Neu anlegen
      await _client.from('user_cards').insert({
        'user_id': currentUser!.id,
        'api_card_id': card.id,
        'name': card.name,
        'set_name': card.setName,
        'card_number': card.number,
        'image_url': card.imageUrl,
        'rarity': card.rarity,
        'condition': condition,
        'quantity': 1,
      });
    }
  }
  
  // Datenbank: Karten holen
  Future<List<UserCard>> getUserCards({String? orderBy = 'created_at', bool ascending = false}) async {
    if (!isLoggedIn) return [];
    
    final response = await _client
        .from('user_cards')
        .select()
        .eq('user_id', currentUser!.id)
        .order(orderBy ?? 'created_at', ascending: ascending);
    
    return (response as List).map((json) => UserCard.fromJson(json)).toList();
  }
  
  // Datenbank: Löschen
  Future<bool> deleteCard(int cardId) async {
    try {
      await _client.from('user_cards').delete().eq('id', cardId);
      return true;
    } catch (e) {
      return false;
    }
  }
  
  // Datenbank: Stats
  Future<Map<String, dynamic>> getCollectionStats() async {
    if (!isLoggedIn) return {};
    try {
      // Wir nutzen die View, die wir im SQL erstellt haben
      final response = await _client
          .from('user_collection_stats')
          .select()
          .eq('user_id', currentUser!.id)
          .maybeSingle();
          
      return response ?? {};
    } catch (e) {
      return {};
    }
  }
}