/// The fund's own payment account details (`design_spec.md` §6) — every
/// contribution and loan repayment is paid into these accounts, never a
/// member's own account. Stored as a single `settings/fund_account`
/// document so the Give screen, admin settings, and the admin-created
/// payment-verification screens all read the same source of truth.
///
/// Every method (eSewa, Khalti, bank transfer, mobile banking) is
/// independently optional, each with an optional QR-code image — a member
/// only ever sees the methods an admin has actually filled in (see
/// [configuredMethods]), never an empty/unconfigured one.
class FundAccount {
  const FundAccount({
    required this.accountName,
    this.esewaId,
    this.esewaQrUrl,
    this.khaltiId,
    this.khaltiQrUrl,
    this.bankName,
    this.bankAccountNumber,
    this.mobileBankingName,
    this.mobileBankingNumber,
    this.mobileBankingQrUrl,
  });

  final String accountName;

  final String? esewaId;
  final String? esewaQrUrl;

  final String? khaltiId;
  final String? khaltiQrUrl;

  final String? bankName;
  final String? bankAccountNumber;

  /// e.g. "NIC Asia Mobile Banking" — distinct from a plain bank transfer
  /// since it's typically a phone-number-linked wallet, not an account
  /// number.
  final String? mobileBankingName;
  final String? mobileBankingNumber;
  final String? mobileBankingQrUrl;

  static const defaults = FundAccount(accountName: 'Hamro Kosh');

  bool get hasEsewa => esewaId != null && esewaId!.isNotEmpty;
  bool get hasKhalti => khaltiId != null && khaltiId!.isNotEmpty;
  bool get hasBank => bankAccountNumber != null && bankAccountNumber!.isNotEmpty;
  bool get hasMobileBanking =>
      mobileBankingNumber != null && mobileBankingNumber!.isNotEmpty;

  bool get isConfigured => hasEsewa || hasKhalti || hasBank || hasMobileBanking;

  factory FundAccount.fromFirestore(Map<String, dynamic> data) {
    return FundAccount(
      accountName: data['accountName'] as String? ?? defaults.accountName,
      esewaId: data['esewaId'] as String?,
      esewaQrUrl: data['esewaQrUrl'] as String?,
      khaltiId: data['khaltiId'] as String?,
      khaltiQrUrl: data['khaltiQrUrl'] as String?,
      bankName: data['bankName'] as String?,
      bankAccountNumber: data['bankAccountNumber'] as String?,
      mobileBankingName: data['mobileBankingName'] as String?,
      mobileBankingNumber: data['mobileBankingNumber'] as String?,
      mobileBankingQrUrl: data['mobileBankingQrUrl'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'accountName': accountName,
    'esewaId': esewaId,
    'esewaQrUrl': esewaQrUrl,
    'khaltiId': khaltiId,
    'khaltiQrUrl': khaltiQrUrl,
    'bankName': bankName,
    'bankAccountNumber': bankAccountNumber,
    'mobileBankingName': mobileBankingName,
    'mobileBankingNumber': mobileBankingNumber,
    'mobileBankingQrUrl': mobileBankingQrUrl,
  };
}
