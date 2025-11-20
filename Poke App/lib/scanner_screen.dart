import 'dart:async'; // Wichtig für Timer
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'card_scanner_service.dart';
import '../../supabase_service.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> with WidgetsBindingObserver {
  CameraController? _cameraController;
  final CardScannerService _scannerService = CardScannerService();
  
  bool _isScanning = false;
  bool _isProcessing = false; // Verhindert doppelte Scans
  PokemonCard? _detectedCard;
  String _statusText = 'Halte eine Karte ruhig vor die Kamera';
  Timer? _scanTimer; // Der Timer für die Fotos
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopScanTimer();
    _cameraController?.dispose();
    _scannerService.dispose();
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;
    
    if (state == AppLifecycleState.inactive) {
      controller.dispose();
      _stopScanTimer();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }
  
  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;
      
      final camera = cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      
      // Wir brauchen hier keine spezielle ImageGroup mehr, da wir Fotos machen
      _cameraController = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );
      
      await _cameraController!.initialize();
      if (!mounted) return;
      
      setState(() {});
      _startScanLoop(); // Startet den Timer
      
    } catch (e) {
      print('Kamera Fehler: $e');
    }
  }
  
  // --- NEUE LOGIK: Timer statt Stream ---
  void _startScanLoop() {
    _isScanning = true;
    // Alle 1.5 Sekunden ein Foto machen
    _scanTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) async {
      if (!_isScanning || _isProcessing || _cameraController == null || !_cameraController!.value.isInitialized) return;
      
      _isProcessing = true;
      try {
        // Mache ein echtes Foto (funktioniert auf JEDEM Handy)
        final imageFile = await _cameraController!.takePicture();
        
        setState(() => _statusText = "Analysiere...");
        
        final card = await _scannerService.processFileImage(imageFile.path);
        
        if (card != null && mounted) {
          _stopScanTimer(); // Stop! Karte gefunden.
          setState(() {
            _detectedCard = card;
            _isScanning = false;
            _statusText = "Gefunden!";
          });
          _showCardDetails(card);
        } else {
           if(mounted) setState(() => _statusText = "Suche...");
        }
      } catch (e) {
        print("Scan Fehler: $e");
      } finally {
        _isProcessing = false;
      }
    });
  }

  void _stopScanTimer() {
    _scanTimer?.cancel();
    _scanTimer = null;
  }

  void _resumeScanning() {
    if (!mounted) return;
    setState(() {
      _detectedCard = null;
      _statusText = 'Suche Karte...';
    });
    _startScanLoop();
  }
  
  // --- UI CODE (Gleich geblieben) ---
  
  void _showCardDetails(PokemonCard card) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      enableDrag: true,
      builder: (context) => _CardDetailsSheet(
        card: card,
        onClose: () {
          Navigator.pop(context);
          _resumeScanning();
        },
        onAddToCollection: () async {
          Navigator.pop(context);
          await _addToCollection(card);
          _resumeScanning();
        },
      ),
    );
  }
  
  Future<void> _addToCollection(PokemonCard card) async {
    final supabase = SupabaseService();
    if (!supabase.isLoggedIn) {
       if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bitte einloggen!')));
       return;
    }
    try {
      await supabase.addCardToCollection(card: card);
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ ${card.name} gespeichert!'), backgroundColor: Colors.green));
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fehler: $e'), backgroundColor: Colors.red));
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          SizedBox.expand(child: CameraPreview(_cameraController!)),
          // Overlay (Dunkler Rahmen)
          ColorFiltered(
            colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.7), BlendMode.srcOut),
            child: Stack(
              children: [
                Container(decoration: const BoxDecoration(color: Colors.transparent)),
                Center(
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.75,
                    height: MediaQuery.of(context).size.width * 0.75 * 1.4,
                    decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ],
            ),
          ),
          // Zurück Button
          Positioned(top: 50, left: 20, 
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30), 
              onPressed: () => Navigator.pop(context)
            )
          ),
          // Status Text
          Positioned(bottom: 100, left: 0, right: 0, 
            child: Center(
              child: GlassmorphicContainer(
                width: 300, height: 60, borderRadius: 30, blur: 10, border: 2,
                linearGradient: LinearGradient(colors: [Colors.white.withOpacity(0.2), Colors.white.withOpacity(0.1)]),
                borderGradient: LinearGradient(colors: [Colors.white.withOpacity(0.5), Colors.white.withOpacity(0.2)]),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isScanning && !_statusText.contains("Gefunden")) 
                      const Padding(padding: EdgeInsets.only(right: 10), child: SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))),
                    Text(_statusText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                )
              )
            )
          )
        ],
      ),
    );
  }
}

// --- Bottom Sheet UI (Gleich geblieben, nur Copy-Paste für Vollständigkeit) ---
class _CardDetailsSheet extends StatelessWidget {
  final PokemonCard card;
  final VoidCallback onClose;
  final VoidCallback onAddToCollection;
  const _CardDetailsSheet({required this.card, required this.onClose, required this.onAddToCollection});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 600,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1F3A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          if (card.imageUrl != null) Image.network(card.imageUrl!, height: 300),
          const SizedBox(height: 20),
          Text(card.name, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
          Text("${card.setName} • ${card.number}", style: const TextStyle(color: Colors.grey, fontSize: 18)),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(onPressed: onClose, child: const Text("Weiter scannen")),
              ElevatedButton(
                onPressed: onAddToCollection, 
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: const Text("Speichern", style: TextStyle(color: Colors.white))
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}