import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ProfileContractorFullScreen extends StatefulWidget {
  const ProfileContractorFullScreen({super.key});

  @override
  State<ProfileContractorFullScreen> createState() =>
      _ProfileContractorFullScreenState();
}

class _ProfileContractorFullScreenState
    extends State<ProfileContractorFullScreen> {
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _nic = TextEditingController();
  final _personalContact = TextEditingController();
  final _company = TextEditingController();
  final _address = TextEditingController();
  final _companyEmail = TextEditingController();
  final _companyContact = TextEditingController();
  final _businessRegNo = TextEditingController();
  final _otherMethod = TextEditingController();

  String? _workRadius;
  final workRadiusOptions = ['5 km', '10 km', '20 km', '50 km', 'Anywhere'];

  File? _certImage;

  bool _loading = false;
  String? _error;

  final Map<String, bool> _checks = {
    'NIC Verification': false,
    'Police Clearance Report': false,
    'Proof of Address Verification': false,
    'Grama Niladhari Character Certificate': false,
    'Trade Qualification Certificates (Ex. NVQ)': false,
    'On-Site Skill Assessment': false,
    'Interview Screening Process': false,
    'Probation Period Monitoring': false,
    'Workplace Safety & Conduct Briefing': false,
    'Continual Performance Review': false,
    'Previous Employer Reference Checks': false,
    'Other': false,
  };

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) setState(() => _certImage = File(picked.path));
  }

  Future<String?> _uploadCert(String uid) async {
    if (_certImage == null) return null;

    final ref = FirebaseStorage.instance
        .ref()
        .child('business_certs/$uid/${DateTime.now().millisecondsSinceEpoch}.jpg');

    final task = await ref.putFile(_certImage!);
    return await task.ref.getDownloadURL();
  }

  Future<void> _register() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _error = "No authenticated user. Please login.");
      return;
    }

    if (_first.text.trim().isEmpty || _nic.text.trim().isEmpty) {
      setState(() => _error = "Please fill required fields.");
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final certUrl = await _uploadCert(user.uid);

      final selectedChecks = _checks.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList();

      if (_checks['Other'] == true && _otherMethod.text.trim().isNotEmpty) {
        selectedChecks.add("Other: ${_otherMethod.text.trim()}");
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'role': 'contractor',
        'first_name': _first.text.trim(),
        'last_name': _last.text.trim(),
        'nic': _nic.text.trim(),
        'personal_contact': _personalContact.text.trim(),
        'company_name': _company.text.trim(),
        'company_address': _address.text.trim(),
        'company_email': _companyEmail.text.trim(),
        'company_contact': _companyContact.text.trim(),
        'work_radius': _workRadius,
        'business_registration_no': _businessRegNo.text.trim(),
        'business_cert_url': certUrl,
        'verification_methods': selectedChecks,
        'verified': false,
        'registered_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, "/home");
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = "Failed to register contractor: $e";
      });
    }
  }

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _nic.dispose();
    _personalContact.dispose();
    _company.dispose();
    _address.dispose();
    _companyEmail.dispose();
    _companyContact.dispose();
    _businessRegNo.dispose();
    _otherMethod.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight =
        MediaQuery.of(context).size.height - kToolbarHeight - 20;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Contractor Profile & Business Registration"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: screenHeight),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TITLE
                  const Text("Personal Information",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),

                  TextField(
                      controller: _first,
                      decoration: const InputDecoration(labelText: "First Name")),
                  const SizedBox(height: 12),

                  TextField(
                      controller: _last,
                      decoration: const InputDecoration(labelText: "Last Name")),
                  const SizedBox(height: 12),

                  TextField(
                      controller: _nic,
                      decoration: const InputDecoration(labelText: "NIC No.")),
                  const SizedBox(height: 12),

                  TextField(
                      controller: _personalContact,
                      keyboardType: TextInputType.phone,
                      decoration:
                          const InputDecoration(labelText: "Personal Contact")),
                  const SizedBox(height: 18),

                  const Divider(),
                  const SizedBox(height: 10),

                  const Text("Company Information",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),

                  TextField(
                      controller: _company,
                      decoration:
                          const InputDecoration(labelText: "Company Name")),
                  const SizedBox(height: 12),

                  TextField(
                      controller: _address,
                      decoration: const InputDecoration(labelText: "Address")),
                  const SizedBox(height: 12),

                  TextField(
                      controller: _companyEmail,
                      keyboardType: TextInputType.emailAddress,
                      decoration:
                          const InputDecoration(labelText: "Company Email")),
                  const SizedBox(height: 12),

                  TextField(
                      controller: _companyContact,
                      keyboardType: TextInputType.phone,
                      decoration:
                          const InputDecoration(labelText: "Company Contact")),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    decoration:
                        const InputDecoration(labelText: "Work Radius"),
                    initialValue: _workRadius,
                    items: workRadiusOptions
                        .map((e) => DropdownMenuItem(
                              value: e,
                              child: Text(e),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _workRadius = v),
                  ),

                  const SizedBox(height: 18),
                  const Divider(),
                  const SizedBox(height: 10),

                  const Text("Business Registration",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),

                  TextField(
                      controller: _businessRegNo,
                      decoration: const InputDecoration(
                          labelText: "Business Registration No.")),
                  const SizedBox(height: 12),

                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 160,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black26),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _certImage == null
                          ? const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.add, size: 28),
                                  SizedBox(height: 8),
                                  Text("Upload Business Registration Certificate"),
                                ],
                              ),
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                _certImage!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 18),
                  const Divider(),
                  const SizedBox(height: 10),

                  const Text("Verification Methods",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),

                  ..._checks.keys.map((key) {
                    if (key == "Other") {
                      return Column(
                        children: [
                          CheckboxListTile(
                            value: _checks[key],
                            title: const Text("Other"),
                            onChanged: (v) =>
                                setState(() => _checks[key] = v ?? false),
                          ),
                          if (_checks[key] == true)
                            TextField(
                                controller: _otherMethod,
                                decoration:
                                    const InputDecoration(labelText: "Specify")),
                        ],
                      );
                    }

                    return CheckboxListTile(
                      value: _checks[key],
                      title: Text(key),
                      onChanged: (v) =>
                          setState(() => _checks[key] = v ?? false),
                    );
                  }),

                  const SizedBox(height: 14),

                  CheckboxListTile(
                    value: true,
                    onChanged: null,
                    title: const Text(
                        "I agree to FixIt's Terms & Conditions to register my firm."),
                  ),

                  const SizedBox(height: 15),

                  if (_error != null)
                    Text(_error!,
                        style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 15),

                  SizedBox(
                    width: double.infinity,
                    child: _loading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            onPressed: _register,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text("Register"),
                          ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
