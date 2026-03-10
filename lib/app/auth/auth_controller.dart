  // --- MÉTODO REGISTRO ACTUALIZADO ---
  Future<String?> register({
    required String username,
    required String firstName,
    required String lastName,
    required String email,
    required String birthDateIso,
    required String password,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      String cleanUsername = username.trim().toLowerCase();

      // VALIDACIÓN: Verificamos si el usuario ya existe antes de crear la cuenta
      final docUsername = await _firestore
          .collection('users')
          .where('username', isEqualTo: cleanUsername)
          .limit(1)
          .get();

      if (docUsername.docs.isNotEmpty) {
        return "Este nombre de usuario ya está en uso.";
      }
      
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(), 
        password: password
      );
      
      await credential.user!.sendEmailVerification();
      
      final now = DateTime.now();
      final profile = UserProfile(
        uid: credential.user!.uid,
        username: cleanUsername,
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        email: email.trim(),
        birthDateIso: birthDateIso,
        createdAt: now,
        updatedAt: now,
        lastReset: now,
        subscriptionPlan: 'free',
        scansRemaining: 3, 
      );
      
      await _firestore.collection('users').doc(profile.uid).set(profile.toJson());
      await signOut();
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- MÉTODO LOGIN ACTUALIZADO (SOLO USUARIO) ---
  Future<String?> login({required String username, required String password}) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      String input = username.trim().toLowerCase();
      String emailToUse;
      
      // Buscamos el email asociado a ese nombre de usuario en Firestore
      final query = await _firestore
          .collection('users')
          .where('username', isEqualTo: input)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        return 'El nombre de usuario no existe.';
      }
      
      // Extraemos el email real para dárselo a Firebase Auth
      emailToUse = query.docs.first.data()['email'] as String;
      
      final credential = await _auth.signInWithEmailAndPassword(
        email: emailToUse, 
        password: password
      );
      
      if (!credential.user!.emailVerified) {
        await signOut();
        return 'Por favor, verifica tu correo electrónico antes de ingresar.';
      }
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') return 'Contraseña incorrecta.';
      return 'Error de acceso.';
    } catch (e) {
      return 'Error en el servidor.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }