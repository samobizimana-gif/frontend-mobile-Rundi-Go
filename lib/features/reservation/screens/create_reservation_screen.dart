import 'package:flutter/material.dart';
import 'package:rundi_go/features/authentification/services/auth_service.dart';
import 'package:rundi_go/features/map/models/place.dart';

import '../../../core/api_client.dart';
import '../../../core/error_helper.dart';
import '../../../models/menu_item.dart';
import '../../../services/reservation_service.dart';

class CreateReservationScreen extends StatefulWidget {
  final Place place;

  const CreateReservationScreen({super.key, required this.place});

  @override
  State<CreateReservationScreen> createState() =>
      _CreateReservationScreenState();
}

class _CreateReservationScreenState extends State<CreateReservationScreen> {
  final _nomController = TextEditingController();
  final _telController = TextEditingController();
  final _noteController = TextEditingController();

  DateTime _date = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _heure = const TimeOfDay(hour: 19, minute: 30);
  int _nbPersonnes = 2;

  bool _isLoading = true;
  String? _error;
  List<MenuItem> _menu = [];

  // 👉 Sélection des items : { itemId: quantity }
  final Map<int, int> _selectedItems = {};

  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _prefillFromUser();
    _loadMenu();
  }

  void _prefillFromUser() {
    final user = AuthService.instance.currentUser;
    if (user != null) {
      _nomController.text = user.fullName.isNotEmpty
          ? user.fullName
          : user.username;
      _telController.text = user.phone;
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _telController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadMenu() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final list = await ReservationService.instance.getMenu(widget.place.id);
      if (!mounted) return;
      setState(() {
        _menu = list;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    } on NetworkException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = "Erreur : $e";
        _isLoading = false;
      });
    }
  }

  // ==========================================
  // ACTIONS
  // ==========================================
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF1E88E5)),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickHeure() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _heure,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF1E88E5)),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _heure = picked);
  }

  void _submit() async {
    final nom = _nomController.text.trim();
    final tel = _telController.text.trim();

    if (nom.isEmpty || tel.isEmpty) {
      showApiError(context, "Veuillez remplir votre nom et téléphone");
      return;
    }

    setState(() => _submitting = true);

    try {
      final itemsData = _selectedItems.entries
    .map((e) => {
          'item_id': e.key,      // 👈 ATTENTION : item_id (pas item)
          'quantity': e.value,
        })
    .toList();

      await ReservationService.instance.createReservation(
        placeId: widget.place.id,
        clientNom: nom,
        telephone: tel,
        date: _date,
        heure: "${_heure.hour.toString().padLeft(2, '0')}:${_heure.minute.toString().padLeft(2, '0')}",
        nbPersonnes: _nbPersonnes,
        note: _noteController.text.trim(),
        itemsData: itemsData,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Réservation envoyée ✅"),
          backgroundColor: Color(0xFF4CAF50),
        ),
      );
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) showApiError(context, e);
    } on NetworkException catch (e) {
      if (mounted) showApiError(context, e);
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // ==========================================
  // BUILD
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        title: const Text("Réserver",
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF1E88E5)),
              )
            : _error != null
                ? buildErrorState(message: _error!, onRetry: _loadMenu)
                : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // LIEU
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05), blurRadius: 8),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.place, color: Color(0xFF1E88E5)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.place.nom,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold)),
                      Text(widget.place.ville,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // NOM CLIENT
          _label("Votre nom"),
          const SizedBox(height: 8),
          _field(
            controller: _nomController,
            icon: Icons.person_outline,
            hint: "Nom complet",
          ),
          const SizedBox(height: 15),

          // TEL
          _label("Téléphone"),
          const SizedBox(height: 8),
          _field(
            controller: _telController,
            icon: Icons.phone_outlined,
            hint: "+257 XX XX XX XX",
            keyboard: TextInputType.phone,
          ),
          const SizedBox(height: 15),

          // DATE + HEURE
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label("Date"),
                    const SizedBox(height: 8),
                    _pickerField(
                      icon: Icons.calendar_today,
                      text:
                          "${_date.day}/${_date.month}/${_date.year}",
                      onTap: _pickDate,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label("Heure"),
                    const SizedBox(height: 8),
                    _pickerField(
                      icon: Icons.access_time,
                      text:
                          "${_heure.hour.toString().padLeft(2, '0')}:${_heure.minute.toString().padLeft(2, '0')}",
                      onTap: _pickHeure,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),

          // NB PERSONNES
          _label("Nombre de personnes"),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05), blurRadius: 8),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.people_outline, color: Colors.grey),
                const SizedBox(width: 12),
                Expanded(
                  child: Text("$_nbPersonnes personne${_nbPersonnes > 1 ? 's' : ''}",
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500)),
                ),
                IconButton(
                  onPressed: _nbPersonnes > 1
                      ? () => setState(() => _nbPersonnes--)
                      : null,
                  icon: const Icon(Icons.remove_circle_outline),
                  color: const Color(0xFF1E88E5),
                ),
                Text("$_nbPersonnes",
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                IconButton(
                  onPressed: _nbPersonnes < 50
                      ? () => setState(() => _nbPersonnes++)
                      : null,
                  icon: const Icon(Icons.add_circle_outline),
                  color: const Color(0xFF1E88E5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),

          // NOTE
          _label("Note (optionnel)"),
          const SizedBox(height: 8),
          _field(
            controller: _noteController,
            icon: Icons.note_outlined,
            hint: "Une demande spéciale ?",
          ),

          // MENU
          if (_menu.isNotEmpty) ...[
            const SizedBox(height: 25),
            const Text("Sélectionnez vos plats",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ..._menu.where((m) => m.isAvailable).map((item) {
              final qty = _selectedItems[item.id] ?? 0;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: qty > 0
                        ? const Color(0xFF1E88E5)
                        : Colors.grey.shade200,
                    width: qty > 0 ? 1.5 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 6),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.nom,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold)),
                          if (item.prix != null) ...[
                            const SizedBox(height: 2),
                            Text(item.prix!,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF1E88E5),
                                    fontWeight: FontWeight.bold)),
                          ],
                        ],
                      ),
                    ),
                    // Boutons - / +
                    Row(
                      children: [
                        IconButton(
                          onPressed: qty > 0
                              ? () => setState(() {
                                    final newQty = qty - 1;
                                    if (newQty <= 0) {
                                      _selectedItems.remove(item.id);
                                    } else {
                                      _selectedItems[item.id] = newQty;
                                    }
                                  })
                              : null,
                          icon: const Icon(Icons.remove_circle_outline),
                          color: const Color(0xFF1E88E5),
                        ),
                        Text("$qty",
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.bold)),
                        IconButton(
                          onPressed: qty < 50
                              ? () => setState(() {
                                    _selectedItems[item.id] = qty + 1;
                                  })
                              : null,
                          icon: const Icon(Icons.add_circle_outline),
                          color: const Color(0xFF1E88E5),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],

          const SizedBox(height: 30),

          // BOUTON
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E88E5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Text("Envoyer la réservation",
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(
          fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87));

  Widget _field({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    TextInputType? keyboard,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        decoration: InputDecoration(
          border: InputBorder.none,
          prefixIcon: Icon(icon, color: Colors.grey),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 15, vertical: 18),
        ),
      ),
    );
  }

  Widget _pickerField({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      ),
    );
  }
}