import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // -------------------------
  // CLIENT REGISTRATION
  // -------------------------
  Future<UserCredential> registerClient({
    required String email,
    required String password,
    required String name,
    required String phone,
    required Map<String, String> emergencyContact,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = cred.user!.uid;

      await _db.collection('users').doc(uid).set({
        'role': 'client',
        'name': name,
        'email': email,
        'phone': phone,
        'emergencyContact': emergencyContact,
        'approved': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await cred.user?.sendEmailVerification();
      return cred;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Failed to register client');
    }
  }

  // -------------------------
  // CONTRACTOR REGISTRATION
  // -------------------------
  Future<UserCredential> registerContractor({
    required String email,
    required String password,
    required String businessName,
    required Map<String, String> businessInfo,
    required List<String> verificationDocPaths,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = cred.user!.uid;

      await _db.collection('users').doc(uid).set({
        'role': 'contractor',
        'email': email,
        'name': businessName,
        'phone': businessInfo['phone'] ?? '',
        'approved': false, // requires admin approval
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _db.collection('contractors').doc(uid).set({
        'businessName': businessName,
        'address': businessInfo['address'] ?? '',
        'registrationNumber': businessInfo['regNo'] ?? '',
        'verificationDocs': verificationDocPaths,
        'status': 'pending',
        'createdBy': uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await cred.user?.sendEmailVerification();
      return cred;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Failed to register contractor');
    }
  }

  // -------------------------
  // LOGIN
  // -------------------------
  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = cred.user!.uid;
      final userDoc = await _db.collection('users').doc(uid).get();

      if (userDoc.exists) {
        final role = userDoc.data()?['role'];
        final approved = userDoc.data()?['approved'] ?? false;

        if (role == 'contractor' && approved != true) {
          await _auth.signOut();
          throw FirebaseAuthException(
            code: 'contractor-not-approved',
            message: 'Your contractor account is awaiting admin approval.',
          );
        }
      } else {
        throw FirebaseAuthException(
          code: 'user-data-missing',
          message: 'User profile not found in database.',
        );
      }

      return cred;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Login failed');
    }
  }

  // -------------------------
  // LOGOUT
  // -------------------------
  Future<void> logout() async {
    await _auth.signOut();
  }
}
