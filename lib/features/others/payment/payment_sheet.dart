import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/api_client.dart';
import '../../../core/app_toast.dart';
import '../../../models/payment.dart';
import '../../../services/payment_service.dart';
import '../../../widgets/qr_display.dart';

/// Type de paiement à effectuer.
enum PaymentTarget {
  reservation,
  exchange,
  managerSubscription,
}

class PaymentSheet extends StatefulWidget {
  final PaymentTarget target;
  final int referenceId; // id réservation (si reservation)
  final int amountBif;   // montant
  final String? defaultPhone;

  const PaymentSheet({
    super.key,
    required this.target,
    required this.referenceId,
    required this.amountBif,
    this.defaultPhone,
  });

  static Future<bool?> show(
    BuildContext context, {
    required PaymentTarget target,
    required int referenceId,
    required int amountBif,
    String? defaultPhone,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PaymentSheet(
        target: target,
        referenceId: referenceId,
        amountBif: amountBif,
        defaultPhone: defaultPhone,
      ),
    );
  }

  @override
  State<PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<PaymentSheet> {
  PaymentMethod _method = PaymentMethod.lumicash;

  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  bool _submitting = false;
  String? _orderId;
  String? _invoice;
  bool _otpSent = false;

  @override
  void initState() {
    super.initState();
    if (widget.defaultPhone != null && widget.defaultPhone!.isNotEmpty) {
      _phoneController.text = widget.defaultPhone!;
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  // ==========================================
  // 💳 LUMICASH — DEMANDER OTP
  // ==========================================
  Future<void> _requestOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      AppToast.error(context, "Numéro Lumicash requis");
      return;
    }

    setState(() => _submitting = true);
    try {
      final OtpRequestResponse res;
      if (widget.target == PaymentTarget.reservation) {
        res = await PaymentService.instance.requestReservationOtp(
          reservationId: widget.referenceId,
          phone: phone,
        );
      } else {
        // 👉 Pour les autres types : même endpoint générique
        res = await PaymentService.instance.requestReservationOtp(
          reservationId: widget.referenceId,
          phone: phone,
        );
      }

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
  // ✅ LUMICASH — EXÉCUTER OTP
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
      final ok = await PaymentService.instance.executeReservationPayment(
        reservationId: widget.referenceId,
        phone: phone,
        otp: otp,
      );

      if (!mounted) return;
      if (ok) {
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
  // ⚡ LIGHTNING — GÉNÉRER FACTURE
  // ==========================================
  Future<void> _generateLightning() async {
    setState(() => _submitting = true);
    try {
      final res = await PaymentService.instance
          .reservationLightning(widget.referenceId);

      if (!mounted) return;
      setState(() {
        _orderId = res.orderId;
        _invoice = res.invoice.paymentRequest;
      });

      // 👉 Lance le polling
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
    final result = await PaymentService.instance.pollStatus(
      fetcher: () => PaymentService.instance
          .reservationPaymentStatus(widget.referenceId),
      maxAttempts: 60,
    );

    if (!mounted) return;
    if (result != null && result.isPaid) {
      Navigator.pop(context, true);
    } else {
      AppToast.warning(context, "Paiement non confirmé (timeout)");
    }
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
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Poignée
                Center(
                  child: Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Titre
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE3F2FD),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.payment,
                          color: Color(0xFF1E88E5), size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Paiement",
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text(
                            "${_formatMoney(widget.amountBif)} BIF",
                            style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF1E88E5),
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Choix méthode
                if (!_otpSent && _invoice == null) ...[
                  const Text("Méthode de paiement",
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _methodCard(
                          method: PaymentMethod.lumicash,
                          icon: Icons.phone_android,
                          label: "Lumicash",
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _methodCard(
                          method: PaymentMethod.lightning,
                          icon: Icons.bolt,
                          label: "Bitcoin Lightning",
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],

                // ==========================================
                // LUMICASH
                // ==========================================
                if (_method == PaymentMethod.lumicash) ...[
                  if (!_otpSent) ...[
                    const Text("Votre numéro Lumicash",
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold)),
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
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _submitting ? null : _requestOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E88E5),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: _submitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Text("Recevoir le code OTP",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ] else ...[
                    const Text("Code OTP reçu par SMS",
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F7FA),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: TextField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 22,
                            letterSpacing: 8,
                            fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: "••••••",
                          hintStyle: TextStyle(
                              color: Colors.grey.shade400,
                              letterSpacing: 8),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 15, vertical: 18),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
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
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Text("Confirmer le paiement",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold)),
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
                ],

                // ==========================================
                // LIGHTNING
                // ==========================================
                if (_method == PaymentMethod.lightning) ...[
                  if (_invoice == null) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: const Color(0xFFF7931A)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.bolt,
                              color: Color(0xFFF7931A), size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Une facture Lightning va être générée. Scannez-la avec votre wallet Bitcoin.",
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
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed:
                            _submitting ? null : _generateLightning,
                        icon: const Icon(Icons.bolt),
                        label: const Text(
                            "Générer la facture Lightning",
                            style: TextStyle(
                                fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF7931A),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    const Text("Scannez cette facture",
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold)),
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
                          side: const BorderSide(
                              color: Color(0xFFF7931A)),
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
                                color: Color(0xFFF7931A)),
                          ),
                          SizedBox(width: 10),
                          Text("En attente du paiement...",
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _methodCard({
    required PaymentMethod method,
    required IconData icon,
    required String label,
  }) {
    final selected = _method == method;
    return GestureDetector(
      onTap: () => setState(() => _method = method),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF1E88E5).withOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: selected
                ? const Color(0xFF1E88E5)
                : Colors.grey.shade200,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                color:
                    selected ? const Color(0xFF1E88E5) : Colors.grey,
                size: 26),
            const SizedBox(height: 6),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      selected ? FontWeight.bold : FontWeight.w500,
                  color: selected
                      ? const Color(0xFF1E88E5)
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
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(15),
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

  String _formatMoney(int v) {
    return v.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+$)'),
          (m) => '${m[1]} ',
        );
  }
}