import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'app_config.dart';
import 'session_storage.dart';

typedef RecordMap = Map<String, dynamic>;
String newToken() =>
    base64UrlEncode(List<int>.generate(32, (_) => Random.secure().nextInt(256)))
        .replaceAll('=', '');
String tokenHash(String token) => sha256.convert(utf8.encode(token)).toString();
String? imageMime(Uint8List bytes) {
  if (bytes.length < 8 || bytes.length > 5242880) return null;
  if (List.generate(8, (i) => bytes[i]).join(',') ==
      '137,80,78,71,13,10,26,10') {
    return 'image/png';
  }
  if (bytes[0] == 255 && bytes[1] == 216 && bytes[2] == 255) {
    return 'image/jpeg';
  }
  return null;
}

class KinRepository {
  KinRepository(this.client);
  final SupabaseClient client;
  String get owner => client.auth.currentUser!.id;
  Future<List<RecordMap>> documents() async => List<RecordMap>.from(
    await client
        .from('documents')
        .select(
          'id,object_path,mime_type,status,prescription_date,clinic,reviewed_at,extraction_method,draft,created_at',
        )
        .order('created_at', ascending: false),
  );
  Future<RecordMap> upload(Uint8List bytes) async {
    final mime = imageMime(bytes);
    if (mime == null) {
      throw const FormatException(
        'Only JPEG or PNG images up to 5 MB are supported.',
      );
    }
    final id = const Uuid().v4();
    final path = '$owner/$id${mime == 'image/png' ? '.png' : '.jpg'}';
    await client.storage
        .from('prescriptions')
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: mime, upsert: false),
        );
    try {
      return await client
          .from('documents')
          .insert({'id': id, 'object_path': path, 'mime_type': mime})
          .select()
          .single();
    } catch (_) {
      await client.storage.from('prescriptions').remove([path]);
      rethrow;
    }
  }

  Future<Uint8List> original(String path) =>
      client.storage.from('prescriptions').download(path);
  Future<RecordMap> extract(String id) async {
    final response = await client.functions.invoke(
      'extract-prescription',
      body: {'document_id': id},
    );
    return Map<String, dynamic>.from(response.data['draft']);
  }

  Future<void> review(
    String id,
    String? date,
    String? clinic,
    List<RecordMap> medications,
  ) async {
    await client.rpc(
      'review_document',
      params: {
        'p_document_id': id,
        'p_date': date,
        'p_clinic': clinic,
        'p_medications': medications,
      },
    );
  }

  Future<RecordMap> search({
    String? medicine,
    DateTime? from,
    DateTime? to,
  }) async => Map<String, dynamic>.from(
    await client.rpc(
      'search_prescriptions',
      params: {
        'p_medicine': medicine,
        'p_from': from?.toIso8601String().substring(0, 10),
        'p_to': to?.toIso8601String().substring(0, 10),
      },
    ),
  );
  Future<List<RecordMap>> documentMedications(String id) async =>
      List<RecordMap>.from(
        await client.from('medications').select().eq('document_id', id),
      );
  Future<RecordMap?> summary() async =>
      await client.from('summaries').select().maybeSingle();
  Future<void> publish(
    String name,
    List<String> allergies,
    String notes,
    List<String> ids,
  ) async {
    await client.rpc(
      'publish_summary',
      params: {
        'p_name': name,
        'p_allergies': allergies,
        'p_notes': notes,
        'p_medication_ids': ids,
      },
    );
  }

  Future<List<RecordMap>> shares() async => List<RecordMap>.from(
    await client
        .from('shares')
        .select(
          'id,recipient_email,created_at,expires_at,accepted_at,revoked_at',
        )
        .order('created_at', ascending: false),
  );
  Future<RecordMap> share(String email) async {
    final token = newToken();
    final data = Map<String, dynamic>.from(
      await client.rpc(
        'create_share',
        params: {'p_email': email, 'p_token_hash': tokenHash(token)},
      ),
    );
    return {...data, 'url': '${AppConfig.recipientUrl}/s#$token'};
  }

  Future<void> revoke(String id) async =>
      await client.rpc('revoke_share', params: {'p_share_id': id});
  Future<RecordMap?> contacts() async => await client
      .from('contacts')
      .select('display_name,entries,token_hash')
      .maybeSingle();
  Future<String?> contactLink() async {
    final token = await secureStorage.read(key: 'kin.contact.$owner');
    if (token == null) return null;
    final data = await contacts();
    if (data?['token_hash'] != tokenHash(token)) return null;
    return '${AppConfig.recipientUrl}/e#$token';
  }

  Future<String> saveContacts(String name, List<RecordMap> entries) async {
    final token = newToken();
    await client.rpc(
      'save_contacts',
      params: {
        'p_name': name,
        'p_entries': entries,
        'p_token_hash': tokenHash(token),
      },
    );
    await secureStorage.write(key: 'kin.contact.$owner', value: token);
    return '${AppConfig.recipientUrl}/e#$token';
  }

  Future<void> revokeContacts(String name, List<RecordMap> entries) async {
    await client.rpc(
      'save_contacts',
      params: {'p_name': name, 'p_entries': entries, 'p_token_hash': null},
    );
    await secureStorage.delete(key: 'kin.contact.$owner');
  }

  Future<void> deleteDocument(RecordMap doc) async {
    await client.storage.from('prescriptions').remove([
      doc['object_path'] as String,
    ]);
    await client.rpc('delete_document', params: {'p_document_id': doc['id']});
  }
}
