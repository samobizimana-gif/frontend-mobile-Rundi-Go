import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rundi_go/widgets/qr_scanner_screen.dart';

import '../../../core/api_client.dart';
import '../../../core/app_toast.dart';
import '../../../core/error_helper.dart';
import '../../../models/exchange_order.dart';
import '../../../services/payment_service.dart';
import '../../../widgets/qr_display.dart';

class PayScreen extends StatefulWidget {
  const PayScreen({super.key});

  @override
  State<PayScreen> createState() => _PayScreenState();
}

class _PayScreenState extends State<PayScreen> {
  // 👉 0 = Lumicash → Lumicash
  //    1 = Lumicash → Sats
  //    2 = Sats → Lumicash
  //    3 = Sats → Sats
  int _direction = 0;

  // 👉 Contrôleurs
  final _sourcePhoneController = TextEditingController();
  final _destPhoneController = TextEditingController();
  final _destLightningController = TextEditingController();
  final _amountController = TextEditingController();
  final _otpController = TextEditingController();

  // 👉 Montant
  double _amount = 0;
  String _currency = 'BIF'; // BIF | sats

  // 👉 État paiement
  bool _submitting = false;
  bool _otpSent = false;
  String? _orderId;
  String? _invoice;

  // 👉 Taux (mock — à remplacer par backend)
  double _btcToFbu = 124000000.0;

  // ==========================================
  // 💱 SOURCE / DESTINATION SELON DIRECTION
  // ==========================================
  bool get _sourceIsLumicash => _direction == 0 || _direction == 1;
  bool get _destIsLumicash => _direction == 0 || _direction == 2;

  String get _sourceLabel =>
      _sourceIsLumicash ? "Lumicash" : "Bitcoin Lightning";
  String get _destLabel => _destIsLumicash ? "Lumicash" : "Bitcoin Lightning";

  @override
  void dispose() {
    _sourcePhoneController.dispose();
    _destPhoneController.dispose();
    _destLightningController.dispose();
    _amountController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  // ==========================================
  // CALCUL
  // ==========================================
  void _onAmountChanged(String v) {
    final input = double.tryParse(v.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0;
    setState(() => _amount = input);
  }

  String _formatBif(double v) {
    if (v <= 0) return '';
    return v
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]} ');
  }

  String _formatSats(double v) {
    if (v <= 0) return '';
    return v
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]} ');
  }

  double _parseAmount(String s) {
    if (s.isEmpty) return 0;
    return double.tryParse(s.replaceAll(' ', '').replaceAll(',', '.')) ?? 0;
  }

  // ==========================================
  // 💳 ENVOYER (Lumicash source)
  // ==========================================
  Future<void> _requestOtp() async {
    final sourcePhone = _sourcePhoneController.text.trim();
    final destPhone = _destPhoneController.text.trim();
    final destLightning = _destLightningController.text.trim();
    final amount = _parseAmount(_amountController.text);

    // Validations
    if (sourcePhone.isEmpty) {
      AppToast.error(context, "Votre numéro Lumicash est requis");
      return;
    }
    if (amount <= 0) {
      AppToast.error(context, "Montant invalide");
      return;
    }
    if (_destIsLumicash && destPhone.isEmpty) {
      AppToast.error(context, "Numéro du destinataire requis");
      return;
    }
    if (!_destIsLumicash && destLightning.isEmpty) {
      AppToast.error(context, "Adresse Lightning du destinataire requise");
      return;
    }

    setState(() => _submitting = true);
    try {
      // 👉 Appel au backend (endpoint générique exchange)
      final res = await PaymentService.instance.exchangeRequestOtp(
        phone: sourcePhone,
        amountBif: _sourceIsLumicash ? amount.round() : 0,
      );

      if (!mounted) return;
      setState(() {
        _orderId = res.orderId;
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
  // ✅ EXÉCUTER (Lumicash source)
  // ==========================================
  Future<void> _executeOtp() async {
    final otp = _otpController.text.trim();
    if (otp.isEmpty) {
      AppToast.error(context, "Entrez le code OTP");
      return;
    }

    setState(() => _submitting = true);
    try {
      final amount = _parseAmount(_amountController.text);
      final destPhone = _destPhoneController.text.trim();
      final destLightning = _destLightningController.text.trim();

      // 👉 Le backend reçoit toutes les infos et gère la conversion
      final ok = await PaymentService.instance.exchangeExecute(
        phone: _sourcePhoneController.text.trim(),
        amountBif: amount.round(),
        otp: otp,
        orderId: _orderId ?? '',
      );

      if (!mounted) return;
      if (ok) {
        AppToast.success(context, "Paiement réussi ✅");
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
  // ⚡ PAYER (Sats source) — facture Lightning
  // ==========================================
  Future<void> _generateLightning() async {
    final destPhone = _destPhoneController.text.trim();
    final destLightning = _destLightningController.text.trim();
    final amount = _parseAmount(_amountController.text);

    if (amount <= 0) {
      AppToast.error(context, "Montant invalide");
      return;
    }
    if (_destIsLumicash && destPhone.isEmpty) {
      AppToast.error(context, "Numéro du destinataire requis");
      return;
    }
    if (!_destIsLumicash && destLightning.isEmpty) {
      AppToast.error(context, "Adresse Lightning du destinataire requise");
      return;
    }

    setState(() => _submitting = true);
    try {
      final res = await PaymentService.instance.exchangeLightning(
        recipientPhone: destPhone,
        amountBif: amount.round(),
      );

      if (!mounted) return;
      setState(() {
        _orderId = res.orderId;
        _invoice = res.invoice.paymentRequest;
      });

      _pollPayment(res.orderId);
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

  Future<void> _pollPayment(String orderId) async {
    for (int i = 0; i < 60; i++) {
      await Future.delayed(const Duration(seconds: 5));
      try {
        final res = await PaymentService.instance.exchangeOrderStatus(orderId);
        if (res.isPaid) {
          if (!mounted) return;
          Navigator.pop(context, true);
          return;
        }
        if (res.isFailed) {
          if (!mounted) return;
          AppToast.error(context, "Paiement échoué");
          return;
        }
      } catch (_) {}
    }
    if (mounted) AppToast.warning(context, "Paiement non confirmé (timeout)");
  }

  void _copyInvoice() {
    if (_invoice == null) return;
    Clipboard.setData(ClipboardData(text: _invoice!));
    AppToast.success(context, "Facture copiée");
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
        title: const Text(
          "Payer",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Direction
              _buildDirectionTabs(),
              const SizedBox(height: 25),

              // Source
              _buildSourceSection(),
              const SizedBox(height: 20),

              // Montant
              _buildAmountSection(),
              const SizedBox(height: 20),

              // Destination
              _buildDestinationSection(),
              const SizedBox(height: 25),

              // OTP ou facture
              if (_otpSent) _buildOtpSection(),
              if (_invoice != null) _buildInvoiceSection(),

              const SizedBox(height: 15),

              // Bouton
              if (!_otpSent && _invoice == null) _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // TABS DIRECTION
  // ==========================================
  Widget _buildDirectionTabs() {
    final options = [
      {'label': 'Lumicash → Lumicash', 'value': 0},
      {'label': 'Lumicash → Sats', 'value': 1},
      {'label': 'Sats → Lumicash', 'value': 2},
      {'label': 'Sats → Sats', 'value': 3},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Type de paiement",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((opt) {
            final active = _direction == opt['value'];
            return GestureDetector(
              onTap: () => setState(() {
                _direction = opt['value'] as int;
                _otpSent = false;
                _invoice = null;
                _orderId = null;
                _otpController.clear();
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: active ? const Color(0xFF1E88E5) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: active
                        ? const Color(0xFF1E88E5)
                        : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  opt['label'] as String,
                  style: TextStyle(
                    color: active ? Colors.white : Colors.black87,
                    fontSize: 12,
                    fontWeight: active ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ==========================================
  // SOURCE
  // ==========================================
  Widget _buildSourceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _iconFor(_sourceIsLumicash),
            const SizedBox(width: 8),
            Text(
              "Vous payez avec : $_sourceLabel",
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_sourceIsLumicash)
          _textField(
            controller: _sourcePhoneController,
            icon: Icons.phone_android,
            hint: "Votre numéro Lumicash",
            keyboard: TextInputType.phone,
          )
        else
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
                    "Une facture Lightning va être générée. Vous la paierez avec votre wallet Bitcoin.",
                    style: TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ==========================================
  // MONTANT
  // ==========================================
  Widget _buildAmountSection() {
    final isSourceSats = !_sourceIsLumicash;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Montant",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
            ],
          ),
          child: Row(
            children: [
              Icon(
                isSourceSats ? Icons.bolt : Icons.attach_money,
                color: Colors.grey,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: _onAmountChanged,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    hintText: "0",
                    hintStyle: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade300,
                    ),
                    suffixText: isSourceSats ? "sats" : "FBu",
                    suffixStyle: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // DESTINATION
  // ==========================================
  Widget _buildDestinationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _iconFor(_destIsLumicash),
            const SizedBox(width: 8),
            Text(
              "Le destinataire reçoit : $_destLabel",
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_destIsLumicash)
          _textFieldWithScan(
            controller: _destPhoneController,
            icon: Icons.phone,
            hint: "Numéro Lumicash du destinataire",
            keyboard: TextInputType.phone,
            scanHint: "Scannez le QR code du destinataire",
            onScanResult: (value) {
              // 👉 Nettoyer (retirer espaces)
              final cleaned = value.replaceAll(RegExp(r'\s'), '');
              _destPhoneController.text = cleaned;
              AppToast.success(context, "Numéro scanné ✅");
            },
          )
        else
          _textFieldWithScan(
            controller: _destLightningController,
            icon: Icons.bolt,
            hint: "Adresse Lightning (ex: nom@wallet.com)",
            keyboard: TextInputType.emailAddress,
            scanHint: "Scannez le QR code Lightning du destinataire",
            onScanResult: (value) {
              // 👉 Si c'est un lien lightning:..., on extrait l'adresse
              String cleaned = value;
              if (cleaned.startsWith('lightning:')) {
                cleaned = cleaned.substring('lightning:'.length);
              }
              // Si c'est une facture bolt11, on la garde telle quelle
              _destLightningController.text = cleaned;
              AppToast.success(context, "QR scanné ✅");
            },
          ),
      ],
    );
  }

  // ==========================================
  // CHAMP AVEC BOUTON SCAN
  // ==========================================
  Widget _textFieldWithScan({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    TextInputType? keyboard,
    String? scanHint,
    required ValueChanged<String> onScanResult,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(icon, color: Colors.grey, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboard,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hint,
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                contentPadding: const EdgeInsets.symmetric(vertical: 18),
              ),
            ),
          ),
          // 👉 BOUTON SCAN
          GestureDetector(
            onTap: () async {
              final result = await Navigator.push<String>(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      QrScannerScreen(title: "Scanner", subtitle: scanHint),
                ),
              );
              if (result != null && result.isNotEmpty) {
                onScanResult(result);
              }
            },
            child: Container(
              margin: const EdgeInsets.all(6),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF1E88E5).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.qr_code_scanner,
                color: Color(0xFF1E88E5),
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // OTP
  // ==========================================
  Widget _buildOtpSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        const Text(
          "Code OTP reçu par SMS",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
            ],
          ),
          child: TextField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              letterSpacing: 8,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: "••••••",
              hintStyle: TextStyle(
                color: Colors.grey.shade400,
                letterSpacing: 8,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 18,
              ),
            ),
          ),
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
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    "Confirmer le paiement",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
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
    );
  }

  // ==========================================
  // FACTURE
  // ==========================================
  Widget _buildInvoiceSection() {
    return Column(
      children: [
        const SizedBox(height: 10),
        const Text(
          "Scannez cette facture",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Center(child: QrDisplay(data: _invoice!, size: 220)),
        const SizedBox(height: 15),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _copyInvoice,
            icon: const Icon(Icons.copy, size: 16),
            label: const Text("Copier la facture"),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFF7931A),
              side: const BorderSide(color: Color(0xFFF7931A)),
            ),
          ),
        ),
        const SizedBox(height: 15),
        const Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFFF7931A),
                ),
              ),
              SizedBox(width: 10),
              Text(
                "En attente du paiement...",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // BOUTON
  // ==========================================
  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _submitting
            ? null
            : _sourceIsLumicash
            ? _requestOtp
            : _generateLightning,
        style: ElevatedButton.styleFrom(
          backgroundColor: _sourceIsLumicash
              ? const Color(0xFF1E88E5)
              : const Color(0xFFF7931A),
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
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                _sourceIsLumicash
                    ? "Recevoir le code OTP"
                    : "Générer la facture Lightning",
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  // ==========================================
  // WIDGETS
  // ==========================================
  Widget _iconFor(bool isLumicash) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: isLumicash
            ? const Color(0xFF1E88E5).withOpacity(0.15)
            : const Color(0xFFF7931A).withOpacity(0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(
        isLumicash ? Icons.phone_android : Icons.bolt,
        color: isLumicash ? const Color(0xFF1E88E5) : const Color(0xFFF7931A),
        size: 20,
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
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 18,
          ),
        ),
      ),
    );
  }
}
