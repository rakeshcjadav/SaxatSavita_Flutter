import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:saxatsavita_flutter/auth/pages/google_sign_in_page.dart';
import '../styles.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    // Initialize any required resources here

    if (FirebaseAuth.instance.currentUser == null) {
      print("Not signed in");
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const GoogleSignInPage()),
        );
      });
    } else {
      print("Signed in as ${FirebaseAuth.instance.currentUser?.email}");
      print("User ID: ${FirebaseAuth.instance.currentUser?.uid}");
      print("Display Name: ${FirebaseAuth.instance.currentUser?.displayName}");
      print("Photo URL: ${FirebaseAuth.instance.currentUser?.photoURL}");
      print("Phone Number: ${FirebaseAuth.instance.currentUser?.phoneNumber}");
      print(
        "Email Verified: ${FirebaseAuth.instance.currentUser?.emailVerified}",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(AppLocalizations.of(context)!.sakshatSavita),
        surfaceTintColor: Colors.transparent,
        elevation: 20,
        actions: [
          IconButton(
            icon: const Icon(Icons.info, size: 24),
            tooltip: AppLocalizations.of(context)!.menu_three,
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.search, size: 24),
            tooltip: AppLocalizations.of(context)!.menu_five,
            onPressed: () {},
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              currentAccountPicture: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.inversePrimary,
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  backgroundImage: NetworkImage(
                    FirebaseAuth.instance.currentUser?.photoURL ??
                        'assets/res/sakshat_savita_logo.png',
                  ),
                ),
              ),
              accountName: Text(
                FirebaseAuth.instance.currentUser?.displayName ??
                    AppLocalizations.of(context)!.sakshatSavita,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
              ),
              accountEmail: Text(
                FirebaseAuth.instance.currentUser?.email ??
                    AppLocalizations.of(context)!.sakshatSavita,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.normal,
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
              ),
            ),

            ListTile(
              leading: const Icon(Icons.home),
              title: Text(AppLocalizations.of(context)!.menu_one),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.description),
              title: Text(AppLocalizations.of(context)!.menu_two),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.edit_document),
              title: Text(AppLocalizations.of(context)!.menu_four),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: Text(AppLocalizations.of(context)!.menu_six),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: Text(AppLocalizations.of(context)!.logout),
              onTap: () async {
                try {
                  // Show loading indicator
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder:
                        (context) =>
                            const Center(child: CircularProgressIndicator()),
                  );

                  // Sign out from Google
                  await GoogleSignIn.instance.signOut();
                  // Sign out from Firebase
                  await FirebaseAuth.instance.signOut();

                  if (mounted) {
                    // Pop the loading indicator
                    Navigator.pop(context);
                    // Navigate to sign in page
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const GoogleSignInPage(),
                      ),
                    );
                  }
                } catch (e) {
                  // Pop the loading indicator
                  if (mounted) {
                    Navigator.pop(context);
                    // Show error
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error signing out: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                  debugPrint('Sign out error: $e');
                }
              },
            ),
          ],
        ),
      ),
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          ClipRRect(
            child: Image(
              image: AssetImage('assets/res/z_jogi_swami_tallest.jpg'),
              fit: BoxFit.cover,
              width: double.infinity,
            ),
          ),
          Container(
            padding: EdgeInsets.only(bottom: 90),
            child: ElevatedButton.icon(
              onPressed: () {},
              iconAlignment: IconAlignment.start,
              icon: const Icon(Icons.menu_book, size: 30),
              style: ButtonStyle(
                padding: const WidgetStatePropertyAll(
                  EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                textStyle: const WidgetStatePropertyAll(
                  TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              label: Text("  " + AppLocalizations.of(context)!.menu_one),
            ),
          ),
          Container(
            padding: EdgeInsets.only(bottom: 45),
            child: Text(
              AppLocalizations.of(context)!.sampRakhjo,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.normal,
                color: Colors.orange.shade100,
                shadows: [
                  Shadow(
                    offset: Offset(1.0, 1.0),
                    blurRadius: 5.0,
                    color: Color.fromARGB(115, 0, 0, 0),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      //bottomNavigationBar: const Navigationbar(),
    );
  }
}
