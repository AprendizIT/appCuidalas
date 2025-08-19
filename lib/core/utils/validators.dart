class Validators {
  static String? required(String? v, {String field = 'Campo'}) {
    if (v == null || v.trim().isEmpty) return '$field es obligatorio';
    return null;
  }

  static String? idNumber(String? v) {
    if (v == null || v.trim().isEmpty) return 'Cédula es obligatoria';
    final cleaned = v.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.length < 6) return 'Cédula inválida';
    return null;
  }

  static String? email(String? v) {
    if (v == null || v.isEmpty) return null;
    final re = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!re.hasMatch(v)) return 'Email inválido';
    return null;
  }
}
