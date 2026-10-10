import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({
    super.key,
  });

  @override
  State<ContactsScreen> createState() =>
      _ContactsScreenState();
}

class _ContactsScreenState
    extends State<ContactsScreen> {
  List<Map<String, String>> contacts = [];

  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadContacts();
  }

  Future<void> loadContacts() async {
    final prefs =
        await SharedPreferences.getInstance();

    final saved =
        prefs.getStringList(
              'emergency_contacts',
            ) ??
            [];

    final loaded =
        <Map<String, String>>[];

    for (final item in saved) {
      try {
        final decoded = jsonDecode(item);

        loaded.add(
          Map<String, String>.from(
            decoded,
          ),
        );
      } catch (e) {
        // Ignore invalid entries.
      }
    }

    // Keep compatibility with older contacts.
    for (final contact in loaded) {
      contact['name'] =
          contact['name']?.trim() ?? '';

      contact['phone'] =
          contact['phone']?.trim() ?? '';

      contact['primary'] =
          contact['primary'] ?? 'false';
    }

    loaded.sort((a, b) {
      final aPrimary =
          a['primary'] == 'true';

      final bPrimary =
          b['primary'] == 'true';

      if (aPrimary && !bPrimary) {
        return -1;
      }

      if (!aPrimary && bPrimary) {
        return 1;
      }

      return 0;
    });

    if (!mounted) {
      return;
    }

    setState(() {
      contacts = loaded;
      loading = false;
    });
  }

  Future<void> saveContacts() async {
    final prefs =
        await SharedPreferences.getInstance();

    final saved =
        contacts.map((contact) {
      return jsonEncode(contact);
    }).toList();

    await prefs.setStringList(
      'emergency_contacts',
      saved,
    );
  }

  Future<void> addContact() async {
    await showContactDialog();
  }

  Future<void> editContact(
    int index,
  ) async {
    await showContactDialog(
      index: index,
    );
  }

  Future<void> showContactDialog({
    int? index,
  }) async {
    final editing =
        index != null;

    final existing =
        editing ? contacts[index!] : null;

    final nameController =
        TextEditingController(
      text: existing?['name'] ?? '',
    );

    final phoneController =
        TextEditingController(
      text: existing?['phone'] ?? '',
    );

    bool primary =
        existing?['primary'] == 'true';

    final formKey =
        GlobalKey<FormState>();

    final result =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            return AlertDialog(
              title: Text(
                editing
                    ? 'Edit Emergency Contact'
                    : 'Add Emergency Contact',
              ),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller:
                            nameController,
                        textCapitalization:
                            TextCapitalization
                                .words,
                        decoration:
                            const InputDecoration(
                          labelText: 'Name',
                          prefixIcon:
                              Icon(
                            Icons.person,
                          ),
                          border:
                              OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty) {
                            return 'Enter a name';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(
                        height: 14,
                      ),
                      TextFormField(
                        controller:
                            phoneController,
                        keyboardType:
                            TextInputType.phone,
                        decoration:
                            const InputDecoration(
                          labelText:
                              'Phone Number',
                          prefixIcon:
                              Icon(
                            Icons.phone,
                          ),
                          border:
                              OutlineInputBorder(),
                        ),
                        validator: (value) {
                          final phone =
                              value?.trim() ??
                                  '';

                          if (phone.isEmpty) {
                            return 'Enter a phone number';
                          }

                          if (phone.length <
                              7) {
                            return 'Enter a valid phone number';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      CheckboxListTile(
                        contentPadding:
                            EdgeInsets.zero,
                        value: primary,
                        onChanged:
                            (value) {
                          setDialogState(() {
                            primary =
                                value ?? false;
                          });
                        },
                        title: const Text(
                          'Primary emergency contact',
                        ),
                        subtitle:
                            const Text(
                          'Used as the first priority contact.',
                        ),
                        controlAffinity:
                            ListTileControlAffinity
                                .leading,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      false,
                    );
                  },
                  child:
                      const Text('CANCEL'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (!formKey
                        .currentState!
                        .validate()) {
                      return;
                    }

                    Navigator.pop(
                      context,
                      true,
                    );
                  },
                  child: Text(
                    editing
                        ? 'SAVE'
                        : 'ADD',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != true) {
      nameController.dispose();
      phoneController.dispose();
      return;
    }

    final name =
        nameController.text.trim();

    final phone =
        phoneController.text.trim();

    final newContact =
        <String, String>{
      'name': name,
      'phone': phone,
      'primary':
          primary.toString(),
    };

    if (primary) {
      for (final contact in contacts) {
        contact['primary'] = 'false';
      }
    }

    if (editing) {
      contacts[index!] = newContact;
    } else {
      contacts.add(newContact);
    }

    await saveContacts();

    nameController.dispose();
    phoneController.dispose();

    if (!mounted) {
      return;
    }

    setState(() {});

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          editing
              ? 'Contact updated'
              : 'Emergency contact added',
        ),
      ),
    );
  }

  Future<void> setPrimary(
    int index,
  ) async {
    for (int i = 0;
        i < contacts.length;
        i++) {
      contacts[i]['primary'] =
          i == index ? 'true' : 'false';
    }

    await saveContacts();

    if (!mounted) {
      return;
    }

    setState(() {});

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          'Primary emergency contact updated',
        ),
      ),
    );
  }

  Future<void> deleteContact(
    int index,
  ) async {
    final contact =
        contacts[index];

    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Delete Contact?',
          ),
          content: Text(
            'Remove ${contact['name'] ?? 'this contact'} from emergency contacts?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child:
                  const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child:
                  const Text('DELETE'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    contacts.removeAt(index);

    // If the primary contact was removed,
    // make the first remaining contact primary.
    if (contacts.isNotEmpty &&
        !contacts.any(
          (contact) =>
              contact['primary'] ==
              'true',
        )) {
      contacts[0]['primary'] = 'true';
    }

    await saveContacts();

    if (!mounted) {
      return;
    }

    setState(() {});

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          'Emergency contact deleted',
        ),
      ),
    );
  }

  Future<void> callContact(
    String phone,
  ) async {
    final uri =
        Uri.parse('tel:$phone');

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to open phone app.',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to make the call.',
          ),
        ),
      );
    }
  }

  Future<void> messageContact(
    String phone,
  ) async {
    final uri =
        Uri.parse('sms:$phone');

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to open messaging app.',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to open messaging app.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Emergency Contacts',
        ),
      ),
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: addContact,
        icon: const Icon(
          Icons.person_add,
        ),
        label: const Text(
          'Add Contact',
        ),
      ),
      body: loading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: loadContacts,
              child: contacts.isEmpty
                  ? _buildEmptyState()
                  : ListView(
                      physics:
                          const AlwaysScrollableScrollPhysics(),
                      padding:
                          const EdgeInsets.fromLTRB(
                        16,
                        16,
                        16,
                        100,
                      ),
                      children: [
                        _buildHeader(),
                        const SizedBox(
                          height: 16,
                        ),
                        ...List.generate(
                          contacts.length,
                          (index) {
                            return _buildContactCard(
                              index,
                              contacts[index],
                            );
                          },
                        ),
                      ],
                    ),
            ),
    );
  }

  Widget _buildHeader() {
    final primary =
        contacts.where(
      (contact) =>
          contact['primary'] ==
          'true',
    );

    return Container(
      padding:
          const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(18),
        gradient: LinearGradient(
          begin:
              Alignment.topLeft,
          end:
              Alignment.bottomRight,
          colors: [
            Theme.of(context)
                .colorScheme
                .primary
                .withOpacity(0.12),
            Theme.of(context)
                .colorScheme
                .primary
                .withOpacity(0.04),
          ],
        ),
        border: Border.all(
          color: Theme.of(context)
              .colorScheme
              .primary
              .withOpacity(0.15),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration:
                BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .primary
                  .withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.contacts,
              color: Theme.of(context)
                  .colorScheme
                  .primary,
              size: 27,
            ),
          ),
          const SizedBox(
            width: 14,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  '${contacts.length} Emergency Contact${contacts.length == 1 ? '' : 's'}',
                  style:
                      const TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
                Text(
                  primary.isEmpty
                      ? 'No primary contact selected'
                      : 'Primary: ${primary.first['name']}',
                  style: TextStyle(
                    color:
                        Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(
    int index,
    Map<String, String> contact,
  ) {
    final name =
        contact['name'] ?? 'Unknown';

    final phone =
        contact['phone'] ?? '';

    final isPrimary =
        contact['primary'] == 'true';

    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
      elevation:
          isPrimary ? 2 : 0,
      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(16),
        side: BorderSide(
          color: isPrimary
              ? Theme.of(context)
                  .colorScheme
                  .primary
                  .withOpacity(0.3)
              : Colors.grey.shade200,
        ),
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  child: Text(
                    name.isEmpty
                        ? '?'
                        : name[0]
                            .toUpperCase(),
                    style:
                        const TextStyle(
                      fontSize: 20,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(
                  width: 13,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              style:
                                  const TextStyle(
                                fontSize: 17,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ),
                          if (isPrimary) ...[
                            const SizedBox(
                              width: 7,
                            ),
                            Container(
                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                horizontal:
                                    7,
                                vertical: 3,
                              ),
                              decoration:
                                  BoxDecoration(
                                color: Theme.of(
                                  context,
                                )
                                    .colorScheme
                                    .primary
                                    .withOpacity(
                                      0.10,
                                    ),
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  6,
                                ),
                              ),
                              child:
                                  const Text(
                                'PRIMARY',
                                style:
                                    TextStyle(
                                  fontSize: 9,
                                  fontWeight:
                                      FontWeight
                                          .bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      Text(
                        phone,
                        style:
                            TextStyle(
                          color: Colors
                              .grey
                              .shade700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<
                    String>(
                  onSelected:
                      (value) {
                    if (value ==
                        'primary') {
                      setPrimary(
                        index,
                      );
                    } else if (value ==
                        'edit') {
                      editContact(
                        index,
                      );
                    } else if (value ==
                        'delete') {
                      deleteContact(
                        index,
                      );
                    }
                  },
                  itemBuilder:
                      (context) {
                    return [
                      if (!isPrimary)
                        const PopupMenuItem(
                          value:
                              'primary',
                          child: Row(
                            children: [
                              Icon(
                                Icons
                                    .star,
                              ),
                              SizedBox(
                                width: 10,
                              ),
                              Text(
                                'Set primary',
                              ),
                            ],
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit,
                            ),
                            SizedBox(
                              width: 10,
                            ),
                            Text(
                              'Edit',
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value:
                            'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons
                                  .delete,
                            ),
                            SizedBox(
                              width: 10,
                            ),
                            Text(
                              'Delete',
                            ),
                          ],
                        ),
                      ),
                    ];
                  },
                ),
              ],
            ),
            const SizedBox(
              height: 12,
            ),
            Row(
              children: [
                Expanded(
                  child:
                      OutlinedButton.icon(
                    onPressed:
                        phone.isEmpty
                            ? null
                            : () {
                                callContact(
                                  phone,
                                );
                              },
                    icon:
                        const Icon(
                      Icons.phone,
                      size: 18,
                    ),
                    label:
                        const Text(
                      'Call',
                    ),
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                Expanded(
                  child:
                      OutlinedButton.icon(
                    onPressed:
                        phone.isEmpty
                            ? null
                            : () {
                                messageContact(
                                  phone,
                                );
                              },
                    icon:
                        const Icon(
                      Icons.message,
                      size: 18,
                    ),
                    label:
                        const Text(
                      'Message',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics:
          const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(
          height: 100,
        ),
        Icon(
          Icons.contacts_outlined,
          size: 75,
          color: Colors.grey.shade400,
        ),
        const SizedBox(
          height: 18,
        ),
        const Center(
          child: Text(
            'No Emergency Contacts',
            style: TextStyle(
              fontSize: 20,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(
          height: 8,
        ),
        Center(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 40,
            ),
            child: Text(
              'Add trusted people who should receive your emergency alerts.',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                color:
                    Colors.grey.shade600,
                height: 1.4,
              ),
            ),
          ),
        ),
        const SizedBox(
          height: 22,
        ),
        Center(
          child: ElevatedButton.icon(
            onPressed:
                addContact,
            icon: const Icon(
              Icons.person_add,
            ),
            label: const Text(
              'Add Emergency Contact',
            ),
          ),
        ),
      ],
    );
  }
}