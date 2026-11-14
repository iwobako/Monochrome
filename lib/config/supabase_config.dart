class SupabaseConfig {
  // Ambil kedua nilai ini dari Supabase Dashboard > Project Settings > API Keys.
  // Gunakan Project URL dan Publishable key (sb_publishable_...).
  // Jangan pernah memasukkan service_role/secret key ke aplikasi Flutter.
  static const String url = 'CHANGE_THIS_TO_YOUR_SUPABASE_URL';
  static const String publishableKey = 'CHANGE_THIS_TO_YOUR_PUBLISHABLE_KEY';

  static bool get isConfigured =>
      url.startsWith('https://') &&
      !url.contains('YOUR_SUPABASE') &&
      publishableKey.isNotEmpty &&
      !publishableKey.contains('YOUR_SUPABASE');
}
