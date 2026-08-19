import 'user_role.dart';

/// Usuário autenticado do Dash2Board, já resolvido com papel e tenant.
///
/// Combina três fontes:
/// * `FirebaseAuth.currentUser` (uid, e-mail, verificação);
/// * custom claims do ID token (`role`, `tenantId`) - fonte confiável;
/// * documento `/tenants/{tenantId}/members/{uid}` (nome, cargo, avatar).
class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    required this.role,
    required this.tenantId,
    this.displayName,
    this.jobTitle,
    this.businessUnit,
    this.photoUrl,
    this.emailVerified = false,
    this.mfaEnrolled = false,
    this.lastSignInAt,
  });

  /// Usuário anônimo/desconhecido - útil como valor inicial e em testes.
  factory AppUser.empty() => const AppUser(
        uid: '',
        email: '',
        role: UserRole.pending,
        tenantId: '',
      );

  /// Constrói a partir do documento de membro do tenant.
  ///
  /// [claims] são os custom claims do ID token; eles têm precedência sobre o
  /// documento, porque só o backend consegue assiná-los.
  factory AppUser.fromFirestore({
    required String uid,
    required String email,
    required Map<String, Object?> claims,
    Map<String, Object?> memberDoc = const <String, Object?>{},
    bool emailVerified = false,
    bool mfaEnrolled = false,
    DateTime? lastSignInAt,
  }) {
    return AppUser(
      uid: uid,
      email: email,
      role: UserRole.fromWire(claims['role'] ?? memberDoc['role']),
      tenantId: (claims['tenantId'] ?? memberDoc['tenantId'] ?? '') as String,
      displayName: memberDoc['displayName'] as String?,
      jobTitle: memberDoc['jobTitle'] as String?,
      businessUnit: memberDoc['businessUnit'] as String?,
      photoUrl: memberDoc['photoUrl'] as String?,
      emailVerified: emailVerified,
      mfaEnrolled: mfaEnrolled,
      lastSignInAt: lastSignInAt,
    );
  }

  final String uid;
  final String email;
  final UserRole role;
  final String tenantId;
  final String? displayName;
  final String? jobTitle;
  final String? businessUnit;
  final String? photoUrl;
  final bool emailVerified;
  final bool mfaEnrolled;
  final DateTime? lastSignInAt;

  bool get isAuthenticated => uid.isNotEmpty;

  bool get hasTenant => tenantId.isNotEmpty;

  /// Pode entrar em um dashboard? Exige papel provisionado e tenant válido.
  bool get canEnterDashboard =>
      isAuthenticated && hasTenant && role.isProvisioned;

  /// Primeiro nome, para a saudação da tela de boas-vindas.
  String get firstName {
    final String source = (displayName ?? '').trim();
    if (source.isEmpty) {
      final int at = email.indexOf('@');
      final String local = at > 0 ? email.substring(0, at) : email;
      if (local.isEmpty) {
        return 'Executivo';
      }
      final String cleaned = local.split(RegExp(r'[._-]')).first;
      return cleaned.isEmpty
          ? 'Executivo'
          : cleaned[0].toUpperCase() + cleaned.substring(1);
    }
    return source.split(' ').first;
  }

  /// Iniciais para o avatar circular.
  String get initials {
    final String source = (displayName ?? email).trim();
    if (source.isEmpty) {
      return 'EL';
    }
    final List<String> parts =
        source.split(RegExp(r'\s+')).where((String p) => p.isNotEmpty).toList();
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  AppUser copyWith({
    String? uid,
    String? email,
    UserRole? role,
    String? tenantId,
    String? displayName,
    String? jobTitle,
    String? businessUnit,
    String? photoUrl,
    bool? emailVerified,
    bool? mfaEnrolled,
    DateTime? lastSignInAt,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      role: role ?? this.role,
      tenantId: tenantId ?? this.tenantId,
      displayName: displayName ?? this.displayName,
      jobTitle: jobTitle ?? this.jobTitle,
      businessUnit: businessUnit ?? this.businessUnit,
      photoUrl: photoUrl ?? this.photoUrl,
      emailVerified: emailVerified ?? this.emailVerified,
      mfaEnrolled: mfaEnrolled ?? this.mfaEnrolled,
      lastSignInAt: lastSignInAt ?? this.lastSignInAt,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AppUser &&
        other.uid == uid &&
        other.email == email &&
        other.role == role &&
        other.tenantId == tenantId &&
        other.displayName == displayName &&
        other.jobTitle == jobTitle &&
        other.businessUnit == businessUnit &&
        other.photoUrl == photoUrl &&
        other.emailVerified == emailVerified &&
        other.mfaEnrolled == mfaEnrolled &&
        other.lastSignInAt == lastSignInAt;
  }

  @override
  int get hashCode => Object.hash(
        uid,
        email,
        role,
        tenantId,
        displayName,
        jobTitle,
        businessUnit,
        photoUrl,
        emailVerified,
        mfaEnrolled,
        lastSignInAt,
      );

  @override
  String toString() =>
      'AppUser(uid: $uid, role: ${role.wireValue}, tenantId: $tenantId)';
}
