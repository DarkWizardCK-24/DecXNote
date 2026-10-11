import 'package:deck_note/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// What the app needs from an auth backend. The real one talks to Firebase;
/// tests and screenshots use an in-memory fake.
abstract class AuthService {
  /// Emits the signed-in user's Firebase uid, or null when signed out.
  Stream<String?> get authStateChanges;

  Future<UserModel?> signUp({
    required String name,
    required String email,
    required String password,
  });

  Future<UserModel?> signIn({required String email, required String password});

  Future<UserModel?> getUserData();

  Future<void> updateUserProfile({required String name, required String email});

  Future<void> signOut();
}

class FirebaseAuthService implements AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Stream<String?> get authStateChanges =>
      _auth.authStateChanges().map((user) => user?.uid);

  Future<String> _generateUserId() async {
    final counterDoc = _firestore.collection('counters').doc('userId');
    
    return await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(counterDoc);
      
      int newCount = 1;
      if (snapshot.exists) {
        newCount = (snapshot.data()?['count'] ?? 0) + 1;
      }
      
      transaction.set(counterDoc, {'count': newCount}, SetOptions(merge: true));
      
      return 'USER${newCount.toString().padLeft(6, '0')}';
    });
  }

  @override
  Future<UserModel?> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userId = await _generateUserId();
      
      final userModel = UserModel(
        userId: userId,
        name: name,
        email: email,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(userModel.toMap());

      await userCredential.user!.updateDisplayName(name);

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  @override
  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final doc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (doc.exists) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  @override
  Future<UserModel?> getUserData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> updateUserProfile({
    required String name,
    required String email,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      await user.updateDisplayName(name);
      
      // Only update email if it's different from current email
      if (user.email != email) {
        await user.verifyBeforeUpdateEmail(email);
      }

      await _firestore.collection('users').doc(user.uid).update({
        'name': name,
        'email': email,
      });
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'requires-recent-login':
        return 'Please log in again to update your profile.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}