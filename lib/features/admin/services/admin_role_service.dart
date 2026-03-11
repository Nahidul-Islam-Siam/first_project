import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminRoleService {
  AdminRoleService._();

  static final AdminRoleService instance = AdminRoleService._();

  FirebaseFirestore get _db => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  Future<void> ensureUserProfile(User? user) async {
    if (user == null) return;
    final docRef = _users.doc(user.uid);
    final snapshot = await docRef.get();

    final profilePatch = <String, dynamic>{
      'uid': user.uid,
      'email': user.email,
      'display_name': user.displayName,
      'photo_url': user.photoURL,
      'updated_at': FieldValue.serverTimestamp(),
      'last_sign_in_at': FieldValue.serverTimestamp(),
    };

    if (!snapshot.exists) {
      profilePatch['role'] = 'user';
      profilePatch['created_at'] = FieldValue.serverTimestamp();
    }

    await docRef.set(profilePatch, SetOptions(merge: true));
  }

  Future<bool> isCurrentUserAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final snapshot = await _users.doc(user.uid).get();
    return _isAdminFromMap(snapshot.data());
  }

  Stream<bool> watchCurrentUserAdmin() {
    final user = _auth.currentUser;
    if (user == null) return Stream<bool>.value(false);
    return _users.doc(user.uid).snapshots().map((snapshot) {
      return _isAdminFromMap(snapshot.data());
    });
  }

  bool _isAdminFromMap(Map<String, dynamic>? data) {
    if (data == null) return false;

    final role = (data['role'] ?? '').toString().trim().toLowerCase();
    if (role == 'admin' || role == 'super_admin' || role == 'superadmin') {
      return true;
    }

    final isAdmin = data['is_admin'];
    if (isAdmin is bool) return isAdmin;

    final roles = data['roles'];
    if (roles is Iterable) {
      return roles
          .map((value) => value.toString().trim().toLowerCase())
          .contains('admin');
    }

    return false;
  }
}
