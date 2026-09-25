import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rundi_go/features/social/service_manager.dart';

import '../../../core/api_client.dart';
import '../../../core/app_toast.dart';
import '../../../core/error_helper.dart';

class ManagerSubscriptionScreen extends StatefulWidget {
  const ManagerSubscriptionScreen({super.key});

  @override
  State<ManagerSubscriptionScreen> createState() =>
      _ManagerSubscriptionScreenState();
}

class _ManagerSubscriptionScreenState
    extends State<ManagerSubscriptionScreen> {
  // 👉 0 = Lumicash, 1 = Lightning
  int _method = 0;

  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _plans = [];
  int? _selectedPlanId;

  // 👉 État paiement
  bool _submitting = false;
  bool _otpSent = false;
  String? _orderId;
  String? _invoice;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _loadPlans() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final plans = await ManagerService.instance.getPlans();
      if (!mounted) return;
      setState(() {
        _plans = plans;
        if (plans.isNotEmpty && _selectedPlanId == null) {
          _selectedPlanId = _parseInt(plans.first['id']);
        }
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

  int _parseInt(dynamic v) {
    if (v is int) return v;
    return int.tryParse('$v') ?? 0;
  }

  double _parseDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse('$v') ?? 0;
  }

  String _formatMoney(dynamic v) {
    final n = _parseDouble(v).toInt();
    return n.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+$)'),
          (m) => '${m[1]} ',
        );
  }

  // ==========================================
  // 💳 DEMANDER OTP
  // ==========================================
  Future<void> _requestOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      AppToast.error(context, "Numéro Lumicash requis");
      return;
    }
    if (_selectedPlanId == null) {
      AppToast.error(context, "Choisissez un plan");
      return;
    }

    setState(() => _submitting = true);
    try {
      final res = await ManagerService.instance.requestOtp(
        planId: _selectedPlanId!,
        phone: phone,
      );

      if (!mounted) return;
      setState(() {
        _orderId = res['order_id']?.toString();
        _otpSent = true;
      });
      AppToast.success(context, "Code OTP envoyé par SMS");
    } on ApiException catch (e) {
      if (mounted) AppToast.error(context, e.message);
    } on NetworkException catch (e) {
      if (mounted) AppToast.error(context, e.message);
    } catch (e) {
      if (mounted) AppToast.error(context, "Erreur : $e");
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // ==========================================
  // ✅ EXÉCUTER OTP
  // ==========================================
  Future<void> _executeOtp() async {
    final phone = _phoneController.text.trim();
    final otp = _otpController.text.trim();

    if (otp.isEmpty) {
      AppToast.error(context, "Entrez le code OTP");
      return;
    }

    setState(() => _submitting = true);
    try {
      final res = await ManagerService.instance.executeOtp(
        orderId: _orderId ?? '',
        phone: phone,
        otp: otp,
      );

      if (!mounted) return;

      final success = res['success'] == true;
      if (success) {
        AppToast.success(context, "Abonnement activé ✅");
        Navigator.pop(context, true);
      } else {
        AppToast.error(context, "Paiement refusé");
      }
    } on ApiException catch (e) {
      if (mounted) AppToast.error(context, e.message);
    } on NetworkException catch (e) {
      if (mounted) AppToast.error(context, e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // ==========================================
  // ⚡ FACTURE LIGHTNING
  // ==========================================
  Future<void> _generateLightning() async {
    if (_selectedPlanId == null) {
      AppToast.error(context, "Choisissez un plan");
      return;
    }

    setState(() => _submitting = true);
    try {
      final res =
          await ManagerService.instance.lightning(planId: _selectedPlanId!);

      if (!mounted) return;
      final orderId = res['order_id']?.toString();
      final invoice = res['invoice']?['payment_request']?.toString();

      if (invoice != null) {
        setState(() {
          _orderId = orderId;
          _invoice = invoice;
        });
        _showLightningDialog(invoice);
        _pollPayment(orderId);
      } else {
        AppToast.error(context, "Facture non générée");
      }
    } on ApiException catch (e) {
      if (mounted) AppToast.error(context, e.message);
    } on NetworkException catch (e) {
      if (mounted) AppToast.error(context, e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // ==========================================
  // 🔄 POLLING
  // ==========================================
  Future<void> _pollPayment(String? orderId) async {
    if (orderId == null) return;

    for (int i = 0; i < 60; i++) {
      await Future.delayed(const Duration(seconds: 5));
      try {
        final res = await ManagerService.instance.getOrderStatus(orderId);
        final status = res['status']?.toString();
        if (status == 'paid') {
          if (!mounted) return;
          Navigator.pop(context, true);
          return;
        }
        if (status == 'failed') {
          if (!mounted) return;
          AppToast.error(context, "Paiement échoué");
          return;
        }
      } catch (_) {}
    }

    if (mounted) {
      AppToast.warning(context, "Paiement non confirmé (timeout)");
    }
  }

  void _showLightningDialog(String invoice) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.bolt, color: Color(0xFFF7931A)),
              SizedBox(width: 8),
              Text("Payer avec Lightning"),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Scannez ou copiez la facture dans votre wallet Lightning.",
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SelectableText(
                  invoice,
                  style: const TextStyle(
                      fontSize: 10, fontFamily: 'monospace'),
                  maxLines: 6,
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: invoice));
                  AppToast.success(context, "Copié");
                },
                icon: const Icon(Icons.copy, size: 16),
                label: const Text("Copier"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFF7931A),
                  side: const BorderSide(color: Color(0xFFF7931A)),
                ),
              ),
              const SizedBox(height: 10),
              const Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Color(0xFFF7931A)),
                    ),
                    SizedBox(width: 8),
                    Text("En attente du paiement...",
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Fermer"),
            ),
          ],
        );
      },
    );
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
        title: const Text("Abonnement gérant",
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF1E88E5)),
              )
            : _error != null
                ? buildErrorState(message: _error!, onRetry: _loadPlans)
                : _plans.isEmpty
                    ? const Center(
                        child: Text("Aucun plan disponible",
                            style: TextStyle(color: Colors.grey)))
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
          // Choix du plan
          const Text("Formule",
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05), blurRadius: 8),
              ],
            ),
            child: DropdownButtonHideUnderline(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: DropdownButton<int>(
                  value: _selectedPlanId,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down),
                  items: _plans.map((p) {
                    final id = _parseInt(p['id']);
                    final nom = p['nom']?.toString() ?? 'Plan';
                    final amount = _formatMoney(p['amount_bif']);
                    final days = p['duration_days'] ?? 30;
                    return DropdownMenuItem<int>(
                      value: id,
                      child: Text("$nom — $amount BIF / $days j",
                          style: const TextStyle(fontSize: 14)),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _selectedPlanId = v),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _buildPlanDescription(),
          const SizedBox(height: 25),

          // Choix méthode
          const Text("Méthode de paiement",
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _methodCard(
                  label: "Lumicash",
                  icon: Icons.phone_android,
                  active: _method == 0,
                  onTap: () => setState(() {
                    _method = 0;
                    _otpSent = false;
                  }),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _methodCard(
                  label: "Lightning",
                  icon: Icons.bolt,
                  active: _method == 1,
                  onTap: () => setState(() {
                    _method = 1;
                    _otpSent = false;
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),

          // Méthode Lumicash
          if (_method == 0 && !_otpSent) ...[
            const Text("Numéro Lumicash",
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _textField(
              controller: _phoneController,
              icon: Icons.phone,
              hint: "+257 XX XX XX XX",
              keyboard: TextInputType.phone,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _submitting ? null : _requestOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
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
                            color: Colors.white, strokeWidth: 2))
                    : const Text("1. Recevoir le code OTP",
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
          ],

          // Saisie OTP
          if (_method == 0 && _otpSent) ...[
            const Text("Code OTP reçu par SMS",
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _textField(
              controller: _otpController,
              icon: Icons.password,
              hint: "••••••",
              keyboard: TextInputType.number,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _submitting ? null : _executeOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
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
                            color: Colors.white, strokeWidth: 2))
                    : const Text("2. Confirmer le paiement",
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: TextButton(
                onPressed: _submitting ? null : _requestOtp,
                child: const Text("Renvoyer le code"),
              ),
            ),
          ],

          // Méthode Lightning
          if (_method == 1) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF7931A)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.bolt, color: Color(0xFFF7931A), size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Une facture Lightning va être générée. Vous la paierez depuis votre wallet Bitcoin.",
                      style: TextStyle(
                          fontSize: 12, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: _submitting ? null : _generateLightning,
                icon: const Icon(Icons.bolt),
                label: const Text("Générer la facture Lightning",
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF7931A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 20),
          const Text(
            "L'abonnement gérant est mensuel et multi-établissements. Vous pourrez publier vos lieux après paiement.",
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanDescription() {
    if (_selectedPlanId == null || _plans.isEmpty) {
      return const SizedBox.shrink();
    }
    final plan = _plans.firstWhere(
      (p) => _parseInt(p['id']) == _selectedPlanId,
      orElse: () => {},
    );
    final amount = _formatMoney(plan['amount_bif']);
    final days = plan['duration_days'] ?? 30;

    return Text(
      "Vous paierez $amount BIF pour $days jours, multi-établissements.",
      style: const TextStyle(fontSize: 12, color: Colors.grey),
    );
  }

  Widget _methodCard({
    required String label,
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: active
              ? const Color(0xFF4CAF50).withOpacity(0.15)
              : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color:
                active ? const Color(0xFF4CAF50) : Colors.grey.shade200,
            width: active ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                color: active ? const Color(0xFF4CAF50) : Colors.grey,
                size: 26),
            const SizedBox(height: 6),
            Text(label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      active ? FontWeight.bold : FontWeight.w500,
                  color: active
                      ? const Color(0xFF4CAF50)
                      : Colors.black87,
                )),
          ],
        ),
      ),
    );
  }

  Widget _textField({
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
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        decoration: InputDecoration(
          border: InputBorder.none,
          prefixIcon: Icon(icon, color: Colors.grey, size: 20),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 15, vertical: 18),
        ),
      ),
    );
  }
}