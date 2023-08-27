import 'package:adda/pages/sign_in_page.dart';
import 'package:adda/providers/theme_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 20),
          Card(
            elevation: 4,
            shadowColor: Colors.blue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: Colors.black54,
            child: ListTile(
              leading: const Icon(FontAwesomeIcons.user,color: Colors.white,),
              title: Text('Account',style: Theme.of(context).textTheme.titleLarge!.copyWith(
                color: Colors.white,
              ),),

              onTap: () {},
            ),
          ),
          Card(
            elevation: 4,
            shadowColor: Colors.red,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: Colors.black54,
            child: ListTile(
              leading: const Icon(FontAwesomeIcons.star,color: Colors.white,),
              title: Text('Adda Khor',style: Theme.of(context).textTheme.titleLarge!.copyWith(
                color: Colors.white,
              ),),
              onTap: () {},
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          const Divider(
            color: Colors.grey,
          ),
          Card(
            child: ListTile(
              leading: Icon(FontAwesomeIcons.userGroup,color: Theme.of(context).colorScheme.inverseSurface,),
              title: Text('Friends',style: Theme.of(context).textTheme.titleLarge,),
              onTap: () {},
            ),
          ),
          ListTile(
            leading: Icon(FontAwesomeIcons.sun,color: Theme.of(context).colorScheme.inverseSurface,),
            title: Text('Theme',style: Theme.of(context).textTheme.titleLarge,),
            trailing: DropdownButton<ThemeMode>(
              value: themeProvider.themeMode,
              onChanged: (newValue) {
                if (newValue == null) return;
                themeProvider.setThemeMode(newValue);
              },
              items: ThemeMode.values.map<DropdownMenuItem<ThemeMode>>(
                    (ThemeMode mode) {
                  return DropdownMenuItem<ThemeMode>(
                    value: mode,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(mode.name,style: Theme.of(context).textTheme.bodyMedium,),
                    ),
                  );
                },
              ).toList(),
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          const Divider(
            color: Colors.grey,
          ),
          ListTile(
            leading: Icon(FontAwesomeIcons.info,color: Theme.of(context).colorScheme.inverseSurface,),
            title: Text('What\'s new',style: Theme.of(context).textTheme.titleLarge,),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(FontAwesomeIcons.arrowRightFromBracket,color: Colors.grey,),
            title: Text('Logout',style: Theme.of(context).textTheme.titleLarge!.copyWith(
              color: Colors.grey,
            ),),
            onTap: () {
              //Show dialog to user confirming they want to sign out
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        //Close dialog
                        Navigator.of(context).pop();
                      },
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () async {
                        //Sign out user
                        await FirebaseAuth.instance.signOut();
                        if (context.mounted) {
                          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context)=>const SignInPage()));
                        }
                      },
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}