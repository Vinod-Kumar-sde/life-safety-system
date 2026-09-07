import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  List<Map<String, String>> contacts = [];

  @override
  void initState() {
    super.initState();
    loadContacts();
  }

  Future<void> loadContacts() async {
    final prefs = await SharedPreferences.getInstance();

    final savedContacts = prefs.getStringList('emergency_contacts');

    if (savedContacts != null) {
      setState(() {
        contacts = savedContacts
            .map(
              (contact) => Map<String, String>.from(
                jsonDecode(contact),
              ),
            )
            .toList();
      });
    }
  }

  Future<void> saveContacts() async {
    final prefs = await SharedPreferences.getInstance();

    final data = contacts
        .map((contact) => jsonEncode(contact))
        .toList();

    await prefs.setStringList(
      'emergency_contacts',
      data,
    );
  }

  void addContact() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Emergency Contact'),

          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  prefixIcon: Icon(Icons.person),
                ),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
            ],
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),

            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty ||
                    phoneController.text.trim().isEmpty) {
                  return;
                }

                setState(() {
                  contacts.add({
                    'name': nameController.text.trim(),
                    'phone': phoneController.text.trim(),
                  });
                });

                await saveContacts();

                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> removeContact(int index) async {
    setState(() {
      contacts.removeAt(index);
    });

    await saveContacts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Contacts'),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: addContact,
        child: const Icon(Icons.add),
      ),

      body: contacts.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.contact_phone_outlined,
                    size: 70,
                  ),

                  SizedBox(height: 15),

                  Text(
                    'No emergency contacts',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 8),

                  Text(
                    'Add someone you trust.',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: contacts.length,
              itemBuilder: (context, index) {
                final contact = contacts[index];

                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.person),
                    ),

                    title: Text(
                      contact['name']!,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    subtitle: Text(
                      contact['phone']!,
                    ),

                    trailing: IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                      ),
                      onPressed: () {
                        removeContact(index);
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}