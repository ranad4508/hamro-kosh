/// Shared form-field validators for auth and data-entry forms.
abstract final class Validators {
  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final _phonePattern = RegExp(r'^\+?[0-9]{7,15}$');

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    if (!_emailPattern.hasMatch(value.trim())) return 'Enter a valid email';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Use at least 8 characters';
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value != original) return 'Passwords do not match';
    return null;
  }

  static String? required(String? value, {String field = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '$field is required';
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Phone is required';
    if (!_phonePattern.hasMatch(value.trim())) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  static String? positiveAmount(String? value) {
    if (value == null || value.trim().isEmpty) return 'Amount is required';
    final parsed = num.tryParse(value.trim());
    if (parsed == null || parsed <= 0) return 'Enter a valid amount';
    return null;
  }
}
