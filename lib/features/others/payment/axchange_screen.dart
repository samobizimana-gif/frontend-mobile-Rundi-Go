import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rundi_go/features/authentification/services/auth_service.dart';

import '../../../core/api_client.dart';
import '../../../core/app_toast.dart';
import '../../../core/error_helper.dart';
import '../../../services/bitlibera_service.dart';

class ExchangeScreen extends StatefulWidget {
  const ExchangeScreen({super.key});

  @override
  State<ExchangeScreen> createState() => _ExchangeScreenState();
}

class _ExchangeScreenState extends State<ExchangeScreen> {
  // 👉 0 = FBu → Sats, 1 = Sats → FBu
  int _direction = 0;

  final _giveController = TextEditingController();
  final _receiveController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  // 👉 Taux (chargé du backend)
  double _btcToFbu = 0;
  bool _isLoadingRate = true;

  static const double _satsPerBtc = 100000000.0;
  static const double _feePercent = 2.0;

  double _feeAmount = 0;
  bool _submitting = false;

  bool _otpSent = false;
  String? _orderId;
  String? _invoice;

  bool get _isFbuToSats => _direction == 0;

  @override
  void initState() {
    super.initState();
    _loadRate();
    final user = AuthService.instance.currentUser;
    if (user != null && user.phone.isNotEmpty) {
      _phoneController.text = user.phone;
    }
  }

  @override
  void dispose() {
    _giveController.dispose();
    _receiveController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  // ==========================================
  // 📊 CHARGER LE TAUX
  // ==========================================
  Future<void> _loadRate({bool force = false}) async {
    setState(() => _isLoadingRate = true);
    try {
      final rate = await BitliberaService.instance.getRate(forceRefresh: force);
      if (!mounted) return;
      setState(() {
        _btcToFbu = rate;
        _isLoadingRate = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingRate = false);
      AppToast.error(context, "Impossible de charger le taux");
    }
  }

  // ==========================================
  // 🧮 CALCUL
  // ==========================================
  void _onGiveChanged(String value) {
    final input = double.tryParse(value.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0;

    if (_isFbuToSats) {
      final btc = input / _btcToFbu;
      final grossSats = btc * _satsPerBtc;
      _feeAmount = grossSats * (_feePercent / 100);
      final net = grossSats - _feeAmount;
      _receiveController.text = net > 0 ? _formatSats(net) : '';
    } else {
      final btc = input / _satsPerBtc;
      final grossFbu = btc * _btcToFbu;
      _feeAmount = grossFbu * (_feePercent / 100);
      final net = grossFbu - _feeAmount;
      _receiveController.text = net > 0 ? _formatFbu(net) : '';
    }
    setState(() {});
  }

  void _onReceiveChanged(String value) {
    final input = double.tryParse(value.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0;

    if (_isFbuToSats) {
      final fbu = (input / _satsPerBtc) * _btcToFbu / (1 - _feePercent / 100);
      _giveController.text = fbu > 0 ? _formatFbu(fbu) : '';
      _feeAmount = input * (_feePercent / 100);
    } else {
      final sats = (input / _btcToFbu) * _satsPerBtc / (1 - _feePercent / 100);
      _giveController.text = sats > 0 ? _formatSats(sats) : '';
      _feeAmount = input * (_feePercent / 100);
    }
    setState(() {});
  }

  String _formatFbu(double v) {
    if (v.isNaN || v.isInfinite || v <= 0) return '';
    return v.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+$)'),
          (m) => '${m[1]} ',
        );
  }

  String _formatSats(double v) {
    if (v.isNaN || v.isInfinite || v <= 0) return '';
    return v.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+$)'),
          (m) => '${m[1]} ',
        );
  }

  double _parseAmount(String s) {
    if (s.isEmpty) return 0;
    return double.tryParse(s.replaceAll(' ', '').replaceAll(',', '.')) ?? 0;
  }

  void _swap() {
    setState(() {
      _direction = _direction == 0 ? 1 : 0;
      _giveController.clear();
      _receiveController.clear();
      _feeAmount = 0;
      _otpSent = false;
      _orderId = null;
      _invoice = null;
    });
  }

  void _switchDirection(int dir) {
    if (_direction == dir) return;
    setState(() {
      _direction = dir;
      _giveController.clear();
      _receiveController.clear();
      _feeAmount = 0;
      _otpSent = false;
      _orderId = null;
      _invoice = null;
    });
  }

  // ==========================================
  // 💱 ENVOI
  // ==========================================
  Future<void> _submit() async {
    final giveAmount = _parseAmount(_giveController.text);
    final receiveAmount = _parseAmount(_receiveController.text);
    final phone = _phoneController.text.trim();

    if (giveAmount <= 0 || receiveAmount <= 0) {
      AppToast.error(context, "Montant invalide");
      return;
    }
    if (phone.isEmpty) {
      AppToast.error(context, "Numéro Lumicash requis");
      return;
    }

    setState(() => _submitting = true);

    try {
      if (_isFbuToSats) {
        // 👉 FBu → Sats : demande OTP
        final res = await BitliberaService.instance.requestOtpFbuToSats(
          phone: phone,
          amountBif: giveAmount.round(),
        );

        if (!mounted) return;
        setState(() {
          _orderId = res['order_id']?.toString();
          _otpSent = true;
        });
        AppToast.success(context, "Code OTP envoyé par SMS");
      } else {
        // 👉 Sats → FBu : génère facture Lightning
        final res = await BitliberaService.instance
            .createLightningInvoiceSatsToFbu(
          amountSats: giveAmount.round(),
          recipientPhone: phone,
        );

        if (!mounted) return;
        final orderId = res['order_id']?.toString();
        final invoice = res['invoice']?['payment_request']?.toString() ??
            res['payment_request']?.toString();

        if (invoice != null) {
          setState(() {
            _orderId = orderId;
            _invoice = invoice;
          });
          _showLightningDialog(invoice);
          _pollPayment(orderId);
        } else {
          AppToast.error(context, "Impossible de générer la facture");
        }
      }
    } on ApiException catch (e) {
      if (mounted) showApiError(context, e);
    } on NetworkException catch (e) {
      if (mounted) showApiError(context, e);
    } catch (e) {
      if (mounted) AppToast.error(context, "Erreur : $e");
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // ==========================================
  // 📲 CONFIRMATION OTP (FBu → Sats)
  // ==========================================
  Future<void> _executeOtp() async {
    final otp = _otpController.text.trim();
    if (otp.isEmpty) {
      AppToast.error(context, "Entrez le code OTP");
      return;
    }

    setState(() => _submitting = true);
    try {
      await BitliberaService.instance.executeOtpFbuToSats(
        phone: _phoneController.text.trim(),
        amountBif: _parseAmount(_giveController.text).round(),
        otp: otp,
        orderId: _orderId ?? '',
      );

      if (!mounted) return;
      AppToast.success(context, "Échange réussi ✅ Sats en route");

      _giveController.clear();
      _receiveController.clear();
      _otpController.clear();
      setState(() {
        _otpSent = false;
        _orderId = null;
        _feeAmount = 0;
      });
    } on ApiException catch (e) {
      if (mounted) showApiError(context, e);
    } on NetworkException catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // ==========================================
  // 🔄 POLLING PAIEMENT LIGHTNING
  // ==========================================
  Future<void> _pollPayment(String? orderId) async {
    if (orderId == null) return;

    final result = await BitliberaService.instance.pollStatus(orderId);

    if (!mounted) return;
    if (result != null && result['status'] == 'paid') {
      AppToast.success(context, "Paiement reçu ✅ FBu envoyés sur Lumicash");
      _giveController.clear();
      _receiveController.clear();
      setState(() {
        _orderId = null;
        _invoice = null;
        _feeAmount = 0;
      });
    } else {
      AppToast.warning(context, "Paiement non confirmé (timeout)");
    }
  }

  // ==========================================
  // ⚡ DIALOG FACTURE
  // ==========================================
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Scannez ou copiez cette facture dans votre wallet Bitcoin Lightning.",
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 8),
              const Text(
                "Une fois payée, l'équivalent FBu arrivera automatiquement sur votre compte Lumicash.",
                style: TextStyle(fontSize: 12, color: Colors.grey),
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
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: invoice));
                  AppToast.success(context, "Facture copiée");
                },
                icon: const Icon(Icons.copy, size: 16),
                label: const Text("Copier la facture"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFF7931A),
                  side: const BorderSide(color: Color(0xFFF7931A)),
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
        title: const Text("Échange",
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoadingRate
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF1E88E5)),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tabs
                    Row(
                      children: [
                        Expanded(
                          child: _tabButton(
                            label: "FBu → Sats",
                            active: _direction == 0,
                            onTap: () => _switchDirection(0),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _tabButton(
                            label: "Sats → FBu",
                            active: _direction == 1,
                            onTap: () => _switchDirection(1),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),

                    // VOUS DONNEZ
                    _inputCard(
                      title: "Vous donnez",
                      controller: _giveController,
                      isFbu: _isFbuToSats,
                      onChanged: _onGiveChanged,
                    ),

                    // SWAP
                    Center(
                      child: Transform.translate(
                        offset: const Offset(0, -8),
                        child: GestureDetector(
                          onTap: _swap,
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: const Color(0xFF1E88E5), width: 2),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 8),
                              ],
                            ),
                            child: const Icon(Icons.swap_vert,
                                color: Color(0xFF1E88E5), size: 22),
                          ),
                        ),
                      ),
                    ),

                    // VOUS RECEVEZ
                    _inputCard(
                      title: "Vous recevez",
                      controller: _receiveController,
                      isFbu: !_isFbuToSats,
                      onChanged: _onReceiveChanged,
                    ),

                    const SizedBox(height: 15),

                    // Frais
                    if (_feeAmount > 0)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8E1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline,
                                size: 16, color: Color(0xFFF7931A)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _isFbuToSats
                                    ? "Frais (${_feePercent.toStringAsFixed(0)}%) : ${_formatSats(_feeAmount)} sats"
                                    : "Frais (${_feePercent.toStringAsFixed(0)}%) : ${_formatFbu(_feeAmount)} FBu",
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.black87),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 20),

                    // 👉 NUMÉRO LUMICASH
                    const Text("Votre numéro Lumicash",
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87)),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8),
                        ],
                      ),
                      child: TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          prefixIcon: Icon(Icons.phone_android,
                              color: Colors.grey, size: 20),
                          hintText: "+257 XX XX XX XX",
                          hintStyle: TextStyle(
                              color: Colors.grey, fontSize: 14),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 15, vertical: 18),
                        ),
                      ),
                    ),

                    // 👉 OTP si FBu → Sats
                    if (_otpSent && _isFbuToSats) ...[
                      const SizedBox(height: 15),
                      const Text("Code OTP reçu par SMS",
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87)),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8),
                          ],
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
                    ],

                    const SizedBox(height: 25),

                    // Taux
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.trending_up,
                              size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          const Text("Taux :",
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "1 BTC = ${_formatFbu(_btcToFbu)} FBu",
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _loadRate(force: true),
                            child: const Icon(Icons.refresh,
                                size: 16, color: Color(0xFF1E88E5)),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Bouton
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _submitting
                            ? null
                            : _otpSent
                                ? _executeOtp
                                : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _otpSent
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFF00C853),
                          disabledBackgroundColor: const Color(0xFF00C853)
                              .withOpacity(0.5),
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
                            : Text(
                                _otpSent
                                    ? "Confirmer avec OTP"
                                    : _isFbuToSats
                                        ? "Échanger FBu → Sats"
                                        : "Générer la facture Lightning",
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
      ),
    );
  }

  // ==========================================
  // WIDGETS
  // ==========================================
  Widget _tabButton({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 45,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? const Color(0xFF1E88E5) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                active ? const Color(0xFF1E88E5) : Colors.grey.shade200,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : Colors.black87,
            fontWeight: active ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _inputCard({
    required String title,
    required TextEditingController controller,
    required bool isFbu,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),
          Row(
            children: [
              isFbu ? _fbuFlag() : _btcIcon(),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9., ]')),
                  ],
                  onChanged: onChanged,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    hintText: "0",
                    hintStyle: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade300),
                    suffixText: isFbu ? "FBu" : "sats",
                    suffixStyle: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _btcIcon() {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        color: Color(0xFFF7931A),
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Text("₿",
            style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _fbuFlag() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: ClipOval(
        child: Image.network(
          'https://flagcdn.com/w80/bi.png',
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: const Color(0xFFCE1126),
            child: const Icon(Icons.flag, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}