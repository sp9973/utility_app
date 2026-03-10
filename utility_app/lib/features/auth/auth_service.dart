import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserModel?> getUserModel(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromJson(doc.data()!, uid);
  }

  Future<UserModel> signUp({
    required String email,
    required String password,
    required String role,
    String? name,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    final uid = cred.user!.uid;
    final userModel = UserModel(
      uid: uid,
      email: email,
      role: role,
      name: name,
      createdAt: DateTime.now(),
    );
    await _firestore.collection('users').doc(uid).set({
      ...userModel.toJson(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return userModel;
  }

  Future<UserModel> signIn(
      {required String email, required String password}) async {
    final cred = await _auth.signInWithEmailAndPassword(
        email: email, password: password);
    final uid = cred.user!.uid;
    final user = await getUserModel(uid);
    if (user == null) throw Exception('User record not found.');
    return user;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
