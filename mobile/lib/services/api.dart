import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config.dart';

typedef Json = Map<String, dynamic>;

/// Thin data layer over Supabase. All security is enforced in the database
/// (Json Level Security + storage policies), so the same rules apply to web and app.
class Api {
  static SupabaseClient get db => Supabase.instance.client;
  static GoTrueClient get auth => db.auth;
  static String? get uid => auth.currentUser?.id;

  // ---------- profile ----------
  static Future<Json?> myProfile() async {
    if (uid == null) return null;
    return await db.from('profiles').select().eq('id', uid!).maybeSingle();
  }

  // ---------- catalogue ----------
  static Future<List<Json>> categories() => db.from('categories').select().order('position');

  static Future<List<Json>> courses({bool featured = false, String? categoryId}) {
    var q = db.from('courses').select().eq('is_published', true);
    if (featured) q = q.eq('is_featured', true);
    if (categoryId != null) q = q.eq('category_id', categoryId);
    return q.order('created_at', ascending: false);
  }

  static Future<List<Json>> sections(String courseId) =>
      db.from('course_sections').select().eq('course_id', courseId).order('position');
  static Future<List<Json>> lessons(String courseId) =>
      db.from('lessons').select().eq('course_id', courseId).order('position');

  static Future<List<Json>> testSeries() =>
      db.from('test_series').select().eq('is_published', true).order('created_at', ascending: false);
  static Future<List<Json>> tests(String seriesId) =>
      db.from('tests').select().eq('series_id', seriesId).order('position');

  static Future<List<Json>> ebooks() =>
      db.from('ebooks').select().eq('is_published', true).order('created_at', ascending: false);
  static Future<List<Json>> notes() =>
      db.from('notes').select().eq('is_published', true).order('created_at', ascending: false);
  static Future<List<Json>> liveClasses() => db
      .from('live_classes')
      .select()
      .gte('starts_at', DateTime.now().subtract(const Duration(hours: 3)).toUtc().toIso8601String())
      .order('starts_at');
  static Future<List<Json>> notifications() =>
      db.from('notifications').select().order('created_at', ascending: false).limit(30);

  // ---------- access & purchases ----------
  static Future<bool> hasAccess(String type, String id) async =>
      (await db.rpc('has_access', params: {'p_type': type, 'p_id': id})) == true;

  static Future<bool> owns(String type, String id) async {
    if (uid == null) return false;
    final r = await db.from('purchases').select('id').eq('user_id', uid!).eq('item_type', type).eq('item_id', id).maybeSingle();
    return r != null;
  }

  static Future<void> enrollFree(String type, String id) =>
      db.rpc('enroll_free', params: {'p_type': type, 'p_id': id});

  static Future<List<Json>> myPurchases() =>
      db.from('purchases').select().eq('user_id', uid!).order('created_at', ascending: false);

  static Future<List<Json>> byIds(String table, List<String> ids) async =>
      ids.isEmpty ? <Json>[] : await db.from(table).select().inFilter('id', ids);

  // ---------- media ----------
  static Future<Json?> lessonMedia(String lessonId) async {
    final r = await db.rpc('get_lesson_media', params: {'p_lesson': lessonId});
    if (r is List && r.isNotEmpty) return Map<String, dynamic>.from(r.first as Map);
    return null;
  }

  static Future<String> signedUrl(String path, {int seconds = 10800}) =>
      db.storage.from('content').createSignedUrl(path, seconds);

  static String publicUrl(String path) => db.storage.from('media').getPublicUrl(path);

  // ---------- progress ----------
  static Future<Set<String>> completedLessons() async {
    if (uid == null) return {};
    final r = await db.from('lesson_progress').select('lesson_id').eq('user_id', uid!);
    return r.map((e) => e['lesson_id'] as String).toSet();
  }

  static Future<void> setCompleted(String lessonId, bool done) async {
    if (done) {
      await db.from('lesson_progress').upsert({'user_id': uid, 'lesson_id': lessonId});
    } else {
      await db.from('lesson_progress').delete().eq('lesson_id', lessonId).eq('user_id', uid!);
    }
  }

  // ---------- tests ----------
  static Future<List<Json>> testQuestions(String testId) async {
    final r = await db.rpc('get_test_questions', params: {'p_test': testId});
    return List<Json>.from((r as List).map((e) => Map<String, dynamic>.from(e as Map)));
  }

  static Future<Json> submitTest(String testId, Map<String, int> answers) async {
    final r = await db.rpc('submit_test', params: {'p_test': testId, 'p_answers': answers});
    return Map<String, dynamic>.from(r as Map);
  }

  static Future<List<Json>> myAttempts() => db
      .from('test_attempts')
      .select('*, tests(title)')
      .eq('user_id', uid!)
      .order('created_at', ascending: false)
      .limit(10);

  // ---------- payments (via the website's API) ----------
  static Future<Json> createOrder(String type, String id, {String? coupon}) async {
    final res = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/api/razorpay/order'),
      headers: _authHeaders(),
      body: jsonEncode({'itemType': type, 'itemId': id, if (coupon != null && coupon.isNotEmpty) 'coupon': coupon}),
    );
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200) throw Exception(body['error'] ?? 'Payment could not start');
    return body;
  }

  static Future<void> verifyPayment({required String orderId, required String paymentId, required String signature}) async {
    final res = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/api/razorpay/verify'),
      headers: _authHeaders(),
      body: jsonEncode({'razorpay_order_id': orderId, 'razorpay_payment_id': paymentId, 'razorpay_signature': signature}),
    );
    if (res.statusCode != 200) throw Exception('Payment verification failed. Payment ID: $paymentId');
  }

  static Map<String, String> _authHeaders() => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${auth.currentSession?.accessToken ?? ''}',
      };

  // ---------- admin helpers ----------
  static Future<Json> adminStats() async => Map<String, dynamic>.from(await db.rpc('admin_stats') as Map);

  /// Uploads a local file. bucket 'media' is public, 'content' is private.
  static Future<String> upload(String bucket, String folder, File file) async {
    final name = file.path.split(Platform.pathSeparator).last.toLowerCase().replaceAll(RegExp(r'[^a-z0-9.]+'), '-');
    final path = '$folder/${DateTime.now().millisecondsSinceEpoch}-$name';
    await db.storage.from(bucket).upload(path, file);
    return path;
  }
}
