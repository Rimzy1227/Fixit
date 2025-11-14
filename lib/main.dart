import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

// --- Screens ---
import 'screens/welcome_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/forgot_password.dart';
import 'screens/auth/register_select.dart';
import 'screens/auth/register_client.dart';
import 'screens/auth/register_contractor.dart';
import 'screens/auth/register_provider.dart';
import 'screens/auth/otp_verification_screen.dart';
import 'screens/profile/profile_client_screen.dart';
import 'screens/profile/profile_contractor_full_screen.dart';
import 'screens/admin/create_admin_account_screen.dart';
import 'screens/admin/admin_settings_screen.dart';
import 'screens/admin/contractor_approval_screen.dart';
import 'screens/contractor/add_provider_screen.dart';
import 'screens/provider/provider_home_screen.dart'; // <-- New import

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

// 🌎 MAIN APP
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FixIt App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Arial',
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.black, fontSize: 16),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.black54),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.black, width: 1.2),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
      home: const AuthWrapper(),
      routes: {
        '/welcome': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/forgot_password': (context) => const ForgotPasswordScreen(),
        '/register_select': (context) => const RegisterSelectScreen(),
        '/register_client': (context) => const RegisterClientScreen(),
        '/register_contractor': (context) => const RegisterContractorScreen(),
        '/otp_verification': (context) => const OtpVerificationScreen(),
        '/profile_client': (context) => const ProfileClientScreen(),
        '/profile_contractor_full': (context) => const ProfileContractorFullScreen(),
        '/register_provider': (context) => const RegisterProviderScreen(),
        '/create_admin_account': (context) => const CreateAdminAccountScreen(),
        '/admin_settings': (context) => const AdminSettingsScreen(),
        '/contractor_approvals': (context) => const ContractorApprovalScreen(),
        '/add_provider': (context) => const AddProviderScreen(),
        '/home': (context) => const HomeScreen(),
        '/provider_home': (context) => const ProviderHomeScreen(), // <-- New route
      },
    );
  }
}

// 🔐 AUTH WRAPPER
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  Future<Widget> _determineNextScreen(User user) async {
    // Email not verified
    if (user.email != null && !user.emailVerified) {
      return const VerifyEmailScreen();
    }

    final uid = user.uid;

    // Check user role
    final clientDoc = await FirebaseFirestore.instance.collection('clients').doc(uid).get();
    final contractorDoc = await FirebaseFirestore.instance.collection('contractors').doc(uid).get();
    final providerDoc = await FirebaseFirestore.instance.collection('providers').doc(uid).get(); // <-- New

    if (clientDoc.exists) {
      return const HomeScreen();
    } else if (contractorDoc.exists) {
      return const HomeScreen();
    } else if (providerDoc.exists) {
      return const ProviderHomeScreen(); // <-- Providers go here
    } else {
      // Default to client profile if nothing found
      return const ProfileClientScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          final user = snapshot.data!;
          return FutureBuilder<Widget>(
            future: _determineNextScreen(user),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              return snap.data!;
            },
          );
        }

        // Not logged in
        return const WelcomeScreen();
      },
    );
  }
}

// 📧 VERIFY EMAIL SCREEN
class VerifyEmailScreen extends StatelessWidget {
  const VerifyEmailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Verify Email', style: TextStyle(color: Colors.white)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.email_outlined, size: 80, color: Colors.orange),
              const SizedBox(height: 20),
              const Text(
                'Please verify your email to continue.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  await user?.sendEmailVerification();
                  // ignore: use_build_context_synchronously
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Verification email sent!')),
                  );
                },
                child: const Text('Resend Verification Email'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  // ignore: use_build_context_synchronously
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: const Text('Logout'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 🏠 HOME SCREEN (Shared dashboard entry)
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('FixIt - Home', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              // ignore: use_build_context_synchronously
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.verified_user, size: 60, color: Colors.black),
              const SizedBox(height: 20),
              Text(
                user != null
                    ? '✅ Logged in as ${user.email ?? user.phoneNumber}'
                    : '⚠️ No user logged in',
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/admin_settings');
                },
                child: const Text('Go to Admin Settings'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
