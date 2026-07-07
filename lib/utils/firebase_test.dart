import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class FirebaseTestScreen extends StatefulWidget {
  const FirebaseTestScreen({super.key});

  @override
  State<FirebaseTestScreen> createState() => _FirebaseTestScreenState();
}

class _FirebaseTestScreenState extends State<FirebaseTestScreen> {
  final List<Map<String, dynamic>> _testResults = [];
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    _runTests();
  }

  Future<void> _runTests() async {
    setState(() {
      _isTesting = true;
      _testResults.clear();
    });

    // Test 1: Firebase Core
    await _testFirebaseCore();

    // Test 2: Firebase Auth
    await _testFirebaseAuth();

    // Test 3: Firestore
    await _testFirestore();

    // Test 4: Firebase Storage
    await _testFirebaseStorage();

    // Test 5: Firebase Messaging
    await _testFirebaseMessaging();

    // Test 6: Firebase Analytics
    await _testFirebaseAnalytics();

    setState(() {
      _isTesting = false;
    });
  }

  Future<void> _testFirebaseCore() async {
    try {
      final app = Firebase.app();
      final options = app.options;
      
      _addResult(
        'Firebase Core',
        true,
        'Initialized successfully\n'
        'Project ID: ${options.projectId}\n'
        'App ID: ${options.appId}\n'
        'API Key: ${options.apiKey.substring(0, 10)}...',
      );
    } catch (e) {
      _addResult('Firebase Core', false, 'Error: $e');
    }
  }

  Future<void> _testFirebaseAuth() async {
    try {
      final auth = FirebaseAuth.instance;
      final currentUser = auth.currentUser;
      
      String message = currentUser != null
          ? 'User logged in\nUID: ${currentUser.uid}\nEmail: ${currentUser.email ?? "N/A"}'
          : 'No user logged in (Auth service working)';
      
      _addResult('Firebase Auth', true, message);
    } catch (e) {
      _addResult('Firebase Auth', false, 'Error: $e');
    }
  }

  Future<void> _testFirestore() async {
    try {
      final firestore = FirebaseFirestore.instance;
      
      // Try to read from a test collection
      final testDoc = firestore.collection('_firebase_test').doc('test');
      
      // Write test data
      await testDoc.set({
        'timestamp': FieldValue.serverTimestamp(),
        'test': 'Firebase connection test',
      });
      
      // Read test data
      final snapshot = await testDoc.get();
      
      if (snapshot.exists) {
        _addResult(
          'Cloud Firestore',
          true,
          'Read/Write successful\nData: ${snapshot.data()}',
        );
        
        // Clean up
        await testDoc.delete();
      } else {
        _addResult('Cloud Firestore', false, 'Document not found after write');
      }
    } catch (e) {
      _addResult('Cloud Firestore', false, 'Error: $e');
    }
  }

  Future<void> _testFirebaseStorage() async {
    try {
      final storage = FirebaseStorage.instance;
      final ref = storage.ref();
      
      // Try to list files in root (this tests connection)
      final listResult = await ref.list(const ListOptions(maxResults: 1));
      
      _addResult(
        'Firebase Storage',
        true,
        'Connected successfully\nBucket: ${storage.bucket}',
      );
    } catch (e) {
      _addResult('Firebase Storage', false, 'Error: $e');
    }
  }

  Future<void> _testFirebaseMessaging() async {
    try {
      final messaging = FirebaseMessaging.instance;
      
      // Request permission
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      
      // Get FCM token
      final token = await messaging.getToken();
      
      _addResult(
        'Firebase Messaging',
        true,
        'Permission: ${settings.authorizationStatus.name}\n'
        'FCM Token: ${token?.substring(0, 20)}...',
      );
    } catch (e) {
      _addResult('Firebase Messaging', false, 'Error: $e');
    }
  }

  Future<void> _testFirebaseAnalytics() async {
    try {
      final analytics = FirebaseAnalytics.instance;
      
      // Log a test event
      await analytics.logEvent(
        name: 'firebase_test',
        parameters: {
          'test_time': DateTime.now().toIso8601String(),
        },
      );
      
      _addResult(
        'Firebase Analytics',
        true,
        'Event logged successfully',
      );
    } catch (e) {
      _addResult('Firebase Analytics', false, 'Error: $e');
    }
  }

  void _addResult(String testName, bool success, String message) {
    setState(() {
      _testResults.add({
        'name': testName,
        'success': success,
        'message': message,
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final passedTests = _testResults.where((r) => r['success'] == true).length;
    final totalTests = _testResults.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Connection Test'),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Summary Card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: passedTests == totalTests && totalTests > 0
                    ? [Colors.green.shade400, Colors.green.shade600]
                    : [Colors.orange.shade400, Colors.orange.shade600],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  passedTests == totalTests && totalTests > 0
                      ? Icons.check_circle
                      : Icons.pending,
                  size: 48,
                  color: Colors.white,
                ),
                const SizedBox(height: 12),
                Text(
                  _isTesting ? 'Testing...' : 'Test Complete',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$passedTests / $totalTests tests passed',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Test Results List
          Expanded(
            child: _isTesting && _testResults.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF0F172A),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _testResults.length,
                    itemBuilder: (context, index) {
                      final result = _testResults[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: result['success']
                                ? Colors.green.shade200
                                : Colors.red.shade200,
                            width: 2,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    result['success']
                                        ? Icons.check_circle
                                        : Icons.error,
                                    color: result['success']
                                        ? Colors.green
                                        : Colors.red,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      result['name'],
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  result['message'],
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade800,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Retest Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isTesting ? null : _runTests,
                icon: const Icon(Icons.refresh),
                label: const Text('Run Tests Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
