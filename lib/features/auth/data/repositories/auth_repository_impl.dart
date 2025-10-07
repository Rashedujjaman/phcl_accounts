// Standard library imports
import 'dart:io';

// Firebase packages
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

// Domain layer imports
import 'package:phcl_accounts/features/auth/domain/repositories/auth_repository.dart';
import 'package:phcl_accounts/features/auth/domain/entities/user_entry.dart';

// Core utilities
import 'package:phcl_accounts/core/errors/firebase_auth_failure.dart';

/// Implementation of [AuthRepository] using Firebase services.
///
/// This repository handles all authentication-related operations including:
/// - User sign in/sign out
/// - User registration with role-based access control
/// - User profile management
/// - Account status validation (active/inactive users)
/// - Profile image upload and management
///
/// The implementation uses Firebase Authentication for user management,
/// Cloud Firestore for user data storage, and Firebase Storage for profile images.
class AuthRepositoryImpl implements AuthRepository {
  // Private Firebase service instances
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  /// Creates an instance of [AuthRepositoryImpl] with required Firebase services.
  ///
  /// Parameters:
  /// - [firebaseAuth]: Firebase Authentication instance for user authentication
  /// - [firestore]: Cloud Firestore instance for user data persistence
  /// - [storage]: Firebase Storage instance for file uploads
  AuthRepositoryImpl({
    required FirebaseAuth firebaseAuth,
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
  }) : _firebaseAuth = firebaseAuth,
       _firestore = firestore,
       _storage = storage;

  /// Signs in a user with email and password.
  ///
  /// Performs pre-authentication validation to check if:
  /// 1. User account exists in Firestore
  /// 2. User account is active (not deactivated by admin)
  ///
  /// Parameters:
  /// - [email]: User's email address
  /// - [password]: User's password
  ///
  /// Returns:
  /// - [User?]: Firebase User object if sign-in successful, null otherwise
  ///
  /// Throws:
  /// - [FirebaseAuthFailure]: If user not found, account deactivated, or authentication fails
  @override
  Future<User?> signIn(String email, String password) async {
    try {
      // Pre-authentication check: Verify user exists and is active
      final user = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      // Check if user account exists in Firestore
      if (user.docs.isEmpty) {
        throw const FirebaseAuthFailure('User account not found.');
      }

      // Extract user data and check account status
      final userData = user.docs.first.data();
      final isActive = userData['isActive'] as bool? ?? false;

      // Prevent sign-in for deactivated accounts
      if (!isActive) {
        throw const FirebaseAuthFailure(
          'Your account has been deactivated. Please contact an administrator for details.',
        );
      }

      // Proceed with Firebase Authentication if user is active
      final result = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return result.user;
    } on FirebaseAuthException catch (e) {
      // Convert Firebase-specific errors to domain-specific failures
      throw FirebaseAuthFailure.fromCode(e.code);
    } catch (e) {
      // Preserve custom error messages from our validation checks
      if (e is FirebaseAuthFailure) {
        rethrow;
      }
      // Fallback for unexpected errors
      throw const FirebaseAuthFailure();
    }
  }

  /// Signs out the currently authenticated user.
  ///
  /// Clears the user's authentication session and removes any stored credentials.
  ///
  /// Throws:
  /// - [FirebaseAuthFailure]: If sign-out operation fails
  @override
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } on FirebaseAuthException catch (e) {
      // Convert Firebase-specific errors to domain-specific failures
      throw FirebaseAuthFailure.fromCode(e.code);
    } catch (_) {
      // Fallback for any unexpected errors during sign-out
      throw const FirebaseAuthFailure();
    }
  }

  /// Registers a new user account with role-based access control.
  ///
  /// This method creates a new user account without affecting the current admin session.
  /// It uses a secondary Firebase app instance to prevent automatic sign-in of the new user.
  ///
  /// Parameters:
  /// - [firstName]: User's first name
  /// - [lastName]: User's last name
  /// - [contactNo]: User's contact number
  /// - [role]: User's role (admin, user, guest)
  /// - [email]: User's email address (must be unique)
  /// - [password]: User's password
  ///
  /// Process:
  /// 1. Preserves current admin session
  /// 2. Creates secondary Firebase app for new user creation
  /// 3. Creates Firebase Auth account
  /// 4. Stores user data in Firestore with role and status
  /// 5. Cleans up secondary app while maintaining admin session
  ///
  /// Throws:
  /// - [FirebaseAuthFailure]: If registration fails or email already exists
  @override
  Future<void> signUp(
    String firstName,
    String lastName,
    String contactNo,
    String role,
    String email,
    String password,
  ) async {
    try {
      // Preserve current admin session - store current user info
      final currentUser = _firebaseAuth.currentUser;
      final currentUserId = currentUser?.uid;

      // Initialize secondary Firebase app for user creation to avoid auto sign-in
      FirebaseApp? secondaryApp;
      FirebaseAuth? secondaryAuth;

      try {
        // Attempt to get existing secondary app or create new one
        try {
          secondaryApp = Firebase.app('UserCreationApp');
        } catch (e) {
          // Secondary app doesn't exist, create it with same configuration
          secondaryApp = await Firebase.initializeApp(
            name: 'UserCreationApp',
            options: Firebase.app().options,
          );
        }

        // Create Firebase Auth instance for the secondary app
        secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

        // Create new user account using secondary auth (preserves current session)
        UserCredential userCredential = await secondaryAuth
            .createUserWithEmailAndPassword(email: email, password: password);

        final newUserId = userCredential.user!.uid;

        // Create comprehensive user document in Firestore
        UserEntity user = UserEntity(
          firstName: firstName,
          lastName: lastName,
          contactNo: contactNo,
          role: role, // Role-based access control
          email: email,
          imageUrl: '', // Empty initially, can be updated later
          isActive: true, // New users are active by default
          createdBy:
              currentUserId ?? newUserId, // Track who created the account
          createdAt: DateTime.now(),
          uid: newUserId,
        );

        // Store user data in Firestore with proper structure
        await _firestore.collection('users').doc(user.uid).set(user.toMap());

        // Sign out from secondary auth to prevent auto sign-in
        await secondaryAuth.signOut();

        // NOTE: Current admin session remains intact and unaffected!
      } finally {
        // Clean up: Delete secondary Firebase app to free resources
        if (secondaryApp != null) {
          try {
            await secondaryApp.delete();
          } catch (e) {
            // Ignore cleanup errors to prevent masking the main operation result
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      // Handle Firebase Authentication specific errors (e.g., email-already-in-use)
      throw FirebaseAuthFailure.fromCode(e.code);
    } catch (_) {
      // Fallback for any unexpected errors during user registration
      throw const FirebaseAuthFailure();
    }
  }

  /// Checks if a user is currently signed in.
  ///
  /// Returns:
  /// - [bool]: true if user is authenticated, false otherwise
  ///
  /// This is a synchronous check of the current authentication state
  /// and does not validate the user's account status in Firestore.
  @override
  Future<bool> isSignedIn() async {
    return _firebaseAuth.currentUser != null;
  }

  /// Retrieves the current authenticated user's complete profile data.
  ///
  /// Performs real-time validation of user account status and automatically
  /// signs out users whose accounts have been deactivated by administrators.
  ///
  /// Returns:
  /// - [UserEntity]: Complete user profile with role, status, and metadata
  ///
  /// Process:
  /// 1. Verifies Firebase Auth session exists
  /// 2. Fetches user data from Firestore
  /// 3. Validates account is still active
  /// 4. Auto-signs out if account deactivated
  ///
  /// Throws:
  /// - [FirebaseAuthFailure]: If not authenticated, user not found, or account deactivated
  @override
  Future<UserEntity> getCurrentUser() async {
    try {
      // Check if user is authenticated with Firebase Auth
      User? user = _firebaseAuth.currentUser;
      if (user == null) {
        throw const FirebaseAuthFailure();
      }

      // Fetch complete user profile from Firestore
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      // Verify user document exists in database
      if (!doc.exists) {
        throw const FirebaseAuthFailure('User account not found.');
      }

      // Parse user data and create entity
      final userData = doc.data() as Map<String, dynamic>;
      final userEntity = UserEntity.fromMap(doc.id, userData);

      // Real-time account status validation
      if (userEntity.isActive != true) {
        // User has been deactivated by admin - force sign out
        await _firebaseAuth.signOut();
        throw const FirebaseAuthFailure(
          'Your account has been deactivated. Please contact an administrator.',
        );
      }

      return userEntity;
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthFailure.fromCode(e.code);
    } catch (e) {
      // Check if it's already a FirebaseAuthFailure to preserve our custom messages
      if (e is FirebaseAuthFailure) {
        rethrow;
      }
      throw FirebaseAuthFailure.fromCode(e.toString());
    }
  }

  /// Updates user profile information with optional field-level updates.
  ///
  /// Provides partial update capability for user profiles, allowing selective
  /// modification of name, contact info, and profile image while preserving other data.
  /// Automatically handles image upload and URL generation for profile pictures.
  ///
  /// Parameters:
  /// - [userId]: Target user's document ID in Firestore
  /// - [firstName]: Optional new first name
  /// - [lastName]: Optional new last name
  /// - [contactNo]: Optional new contact number
  /// - [profileImage]: Optional new profile image file
  ///
  /// Returns:
  /// - [UserEntity]: Updated user profile with fresh data
  ///
  /// Process:
  /// 1. Builds update map with only provided fields
  /// 2. Uploads profile image if provided and gets download URL
  /// 3. Adds server timestamp for update tracking
  /// 4. Performs atomic Firestore update
  /// 5. Fetches and returns updated user data
  ///
  /// Throws:
  /// - [FirebaseStorageFailure]: If image upload fails
  /// - [FirebaseFirestoreFailure]: If database update fails
  @override
  Future<UserEntity> updateUserProfile({
    required String userId,
    String? firstName,
    String? lastName,
    String? contactNo,
    File? profileImage,
  }) async {
    try {
      // Build update map with only provided fields
      Map<String, dynamic> updateData = {};

      if (firstName != null) updateData['firstName'] = firstName;
      if (lastName != null) updateData['lastName'] = lastName;
      if (contactNo != null) updateData['contactNo'] = contactNo;

      // Handle profile image upload if provided
      if (profileImage != null) {
        final imageUrl = await _uploadProfileImage(userId, profileImage);
        updateData['imageUrl'] = imageUrl;
      }

      // Add server timestamp for audit trail
      updateData['updatedAt'] = FieldValue.serverTimestamp();

      // Perform atomic update operation
      await _firestore.collection('users').doc(userId).update(updateData);

      // Return updated user with fresh data
      return await getCurrentUser();
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthFailure.fromCode(e.code);
    } catch (e) {
      throw FirebaseAuthFailure.fromCode(e.toString());
    }
  }

  /// Private helper method for uploading profile images to Firebase Storage.
  ///
  /// Handles secure image upload with standardized naming and error handling.
  /// Images are stored in organized directory structure for easy management.
  ///
  /// Parameters:
  /// - [userId]: User ID for organizing storage path
  /// - [imageFile]: Local image file to upload
  ///
  /// Returns:
  /// - [String]: Public download URL for the uploaded image
  ///
  /// Process:
  /// 1. Creates storage reference with user-specific path
  /// 2. Uploads file to Firebase Storage
  /// 3. Generates and returns public download URL
  ///
  /// Throws:
  /// - [FirebaseAuthFailure]: If upload fails or storage unavailable
  Future<String> _uploadProfileImage(String userId, File imageFile) async {
    try {
      // Create storage reference with organized path structure
      final ref = _storage.ref().child('profile_images').child('$userId.jpg');

      // Upload file and wait for completion
      final uploadTask = await ref.putFile(imageFile);

      // Get and return public download URL
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      throw FirebaseAuthFailure('Failed to upload profile image: $e');
    }
  }
}
