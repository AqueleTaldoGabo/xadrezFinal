import 'package:firebase_auth/firebase_auth.dart';
class AuthService {
 final _auth=FirebaseAuth.instance;
 Stream<User?> get authState=>_auth.authStateChanges();
 User? get user=>_auth.currentUser;
 Future<void> register(String name,String email,String password) async {
  final c=await _auth.createUserWithEmailAndPassword(email:email.trim(),password:password);
  await c.user?.updateDisplayName(name.trim());
 }
 Future<void> login(String email,String password)=>_auth.signInWithEmailAndPassword(email:email.trim(),password:password);
 Future<void> reset(String email)=>_auth.sendPasswordResetEmail(email:email.trim());
 Future<void> logout()=>_auth.signOut();
}
