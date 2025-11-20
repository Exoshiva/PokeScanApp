import 'dart:async';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:dio/dio.dart';

class PokemonCard {
  final String id;
  final String name;
  final String? number;
  final String? setName;
  final String? imageUrl;
  final String? rarity;

  PokemonCard({
    required this.id,
    required this.name,
    this.number,
    this.setName,
    this.imageUrl,
    this.rarity,
  });

  factory PokemonCard.fromJson(Map<String, dynamic> json) {
    return PokemonCard(
      id: json['id'],
      name: json['name'],
      number: json['number'],
      setName: json['set']?['name'],
      imageUrl: json['images']?['large'] ?? json['images']?['small'],
      rarity: json['rarity'],
    );
  }
}

class CardScannerService {
  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final _dio = Dio();
  
  // Regex für Formate wie "151/165", "TG01/TG30"
  final _cardNumberRegex = RegExp(r'[a-zA-Z0-9]{1,4}\s?/\s?[a-zA-Z0-9]{1,4}');

  Future<void> dispose() async {
    await _textRecognizer.close();
  }

  // Diese Methode hat gefehlt! Sie verarbeitet das Foto.
  Future<PokemonCard?> processFileImage(String filePath) async {
     try {
       final inputImage = InputImage.fromFilePath(filePath);
       final recognizedText = await _textRecognizer.processImage(inputImage);
       
       for (var block in recognizedText.blocks) {
          final text = block.text.trim();
          
          if (_cardNumberRegex.hasMatch(text)) {
            final match = _cardNumberRegex.firstMatch(text)?.group(0);
            if (match != null) {
               final cleanNumber = match.replaceAll(' ', '');
               print("✅ Treffer: $cleanNumber");
               return await _fetchCardFromApi(cleanNumber);
            }
          }
        }
     } catch (e) {
       print("OCR Fehler: $e");
     }
     return null;
  }

  Future<PokemonCard?> _fetchCardFromApi(String numberQuery) async {
    try {
      final parts = numberQuery.split('/');
      if (parts.length != 2) return null;
      
      final number = parts[0];
      
      final response = await _dio.get(
        'https://api.pokemontcg.io/v2/cards',
        queryParameters: {
          'q': 'number:"$number"', 
          'pageSize': 1
        },
      );

      if (response.data['data'] != null && (response.data['data'] as List).isNotEmpty) {
        return PokemonCard.fromJson(response.data['data'][0]);
      }
    } catch (e) {
      print('API Error: $e');
    }
    return null;
  }
}