import 'dart:io';
import 'package:auto_route/auto_route.dart';
import 'package:contact_number_demo/ui/auth/store/auth_store.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import '../../core/db/app_db.dart';
import '../../data/model/contact/contact.dart';
import 'package:contact_number_demo/router/app_router.dart';
import 'package:contact_number_demo/values/export.dart';
import 'package:contact_number_demo/values/extensions/widget_ext.dart';
import 'package:contact_number_demo/widget/app_text_filed.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

Map<String, List<ContactListModel>> groupContactsByLetter(
    List<ContactListModel> contacts) {
  final Map<String, List<ContactListModel>> groupedContacts = {};

  for (var contact in contacts) {
    final firstLetter = contact.firstname!.isNotEmpty
        ? contact.firstname![0].toUpperCase()
        : '#';
    if (!groupedContacts.containsKey(firstLetter)) {
      groupedContacts[firstLetter] = [];
    }
    groupedContacts[firstLetter]!.add(contact);
  }

  // Optionally, sort the map by key (A to Z)
  final sortedKeys = groupedContacts.keys.toList()..sort();
  final sortedGroupedContacts = {
    for (var key in sortedKeys) key: groupedContacts[key]!
  };

  return sortedGroupedContacts;
}

@RoutePage()
class ShowContactListPage extends StatefulWidget {
  @override
  State<ShowContactListPage> createState() => _ShowContactListPageState();
}

late Map<String, List<ContactListModel>> groupedContacts;

class _ShowContactListPageState extends State<ShowContactListPage> {
  late TextEditingController searchController;
  late List<ContactListModel> _searchResult = [];

  Future<void> _loadContacts() async {
    final contacts = appDB.contacts;
    setState(() {
      groupedContacts = groupContactsByLetter(contacts);
    });
  }

  @override
  void initState() {
    searchController = TextEditingController();
    _loadContacts();
    _loadFavoriteContacts();
    super.initState();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  onSearchTextChanged(String? text) {
    setState(() {
      _searchResult.clear();
      if (text == null || text.isEmpty) {
        groupedContacts = groupContactsByLetter(appDB.contacts);
        return;
      }

      appDB.contacts.forEach((userDetail) {
        if (userDetail.firstname!.toLowerCase().contains(text.toLowerCase()) ||
            userDetail.lastname!.toLowerCase().contains(text.toLowerCase())) {
          _searchResult.add(userDetail);
        }
      });

      groupedContacts = groupContactsByLetter(_searchResult);
    });
  }

  void onLongPressContact(bool ischeck) {
    setState(() {
      _value = !ischeck;
    });
  }

  void isCheck(ContactListModel contact) {
    setState(() {
      if (authStore.selectedContacts.contains(contact)) {
        authStore.selectedContacts.remove(contact);
      } else {
        authStore.selectedContacts.add(contact);
      }
    });
  }

  void isfavorite(ContactListModel contact) {
    setState(() {
      if (authStore.selectedFavorite.contains(contact)) {
        authStore.selectedFavorite.remove(contact);
      } else {
        authStore.selectedFavorite.add(contact);
      }
    });
  }

  void toggleAllFavorites() {
    setState(() {
      if (authStore.selectedFavorite.length == appDB.contacts.length) {
        // If all contacts are already favorites, clear the selection
        authStore.selectedFavorite.clear();
      } else {
        // Otherwise, add all contacts to the favorites
        authStore.selectedFavorite.addAll(appDB.contacts);
      }
    });
  }

  void selectAll() {
    setState(() {
      if (authStore.selectedContacts.length == appDB.contacts.length) {
        // If all contacts are already favorites, clear the selection
        authStore.selectedContacts.clear();
      } else {
        // Otherwise, add all contacts to the favorites
        authStore.selectedContacts.addAll(appDB.contacts);
      }
    });
  }

  Future<void> _deleteSelectedContacts() async {
    final contacts = appDB.contacts;
    contacts
        .removeWhere((contact) => authStore.selectedContacts.contains(contact));
    await appDB.setValue("contacts", contacts);
    setState(() {
      authStore.selectedFavorite.clear();
      groupedContacts = groupContactsByLetter(contacts);
    });
  }

  Future<void> _addFavoriteSelectedContacts() async {
    final selectedContacts =
        authStore.selectedFavorite.toList(); // Convert to List if it's not

    // Add the list of selected contacts to favorites
    // await appDB.addFavorites(selectedContacts);

    // Clear selected contacts in MobX
    authStore.selectedFavorite.clear();

    // Refresh the favorite contacts list and the grouped contacts
    await _loadFavoriteContacts();
    await _loadContacts();
  }

  Future<List<ContactListModel>> getFavoriteContacts() async {
    final contacts = appDB.favorites;
    return contacts;
  }

  List<ContactListModel> _favoriteContacts = [];
  Future<void> _loadFavoriteContacts() async {
    final contacts = await getFavoriteContacts();
    setState(() {
      _favoriteContacts = contacts;
    });
  }

  bool _value = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: AppColor.white,
        appBar: AppBar(
          centerTitle: false,
          backgroundColor: AppColor.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          actions: [
            Row(
              children: [
                Visibility(
                  visible: _value,
                  child: InkWell(
                      onTap: () {
                        selectAll();
                      },
                      child: Text(
                        "Select all",
                        style: textRegular.copyWith(
                            color: AppColor.blueDiamond, fontSize: 15.spMin),
                      )).wrapPaddingOnly(right: 15.w),
                ),
                Visibility(
                  visible: _value,
                  child: InkWell(
                    onTap: () {
                      _deleteSelectedContacts();
                    },
                    child: Icon(
                      Icons.delete_outline_outlined,
                      color: AppColor.blueDiamond,
                    ),
                  ).wrapPaddingOnly(right: 15.w),
                ),
                Visibility(
                  visible: _value,
                  child: InkWell(
                    onTap: () {
                      _addFavoriteSelectedContacts();
                    },
                    child: Icon(
                      Icons.favorite_border_outlined,
                      color: AppColor.blueDiamond,
                    ),
                  ).wrapPaddingOnly(right: 15.w),
                ),
                InkWell(
                  onTap: () {
                    appRouter.replaceAll([AddContactNumberRoute()]);
                  },
                  child: Icon(
                    Icons.add,
                    color: AppColor.blueDiamond,
                  ),
                ).wrapPaddingOnly(right: 15.w),
              ],
            ),
          ],
        ),
        body: Observer(builder: (_) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    "Contacts",
                    style: textBold.copyWith(fontSize: 25.spMin),
                  ),
                  10.0.verticalSpace,
                  AppTextField(
                    controller: searchController,
                    contentPadding: EdgeInsets.all(10),
                    label: "",
                    hint: "Search",
                    onChanged: onSearchTextChanged,
                    validators: passwordValidator,
                    keyboardType: TextInputType.visiblePassword,
                    keyboardAction: TextInputAction.done,
                    maxLength: 15,
                    filled: true,
                    suffixIcon: Align(
                      alignment: Alignment.centerRight,
                      heightFactor: 1.0,
                      widthFactor: 1.0,
                      child: GestureDetector(
                        onTap: () => Future.delayed(Duration.zero, () {}),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Icon(
                            Icons.keyboard_voice_rounded,
                            color: AppColor.grey,
                          ),
                        ),
                      ),
                    ),
                    prefixIcon: IconButton(
                      onPressed: null,
                      icon: Icon(
                        Icons.search_outlined,
                        size: 25,
                      ),
                    ),
                  ),
                ],
              ).wrapPaddingSymmetric(horizontal: 15.w),
              20.verticalSpace,
              Flexible(fit: FlexFit.loose, child: _buildFavoriteContactsList()),
              20.verticalSpace,
              Expanded(child: _buildContactList()),
            ],
          );
        }));
  }

  Widget _buildFavoriteContactsList() {
    if (_favoriteContacts.isEmpty) {
      return Center(
        child: Text('No favorite contacts'),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: _favoriteContacts.length,
      itemBuilder: (context, index) {
        final contact = _favoriteContacts[index];
        return ListTile(
          trailing: Container(
              padding: EdgeInsets.only(right: 25),
              child: Icon(Icons.favorite, size: 20.0, color: Colors.red)),
          title: Text(contact.firstname
              .toString()), // Adjust according to your ContactListModel
          subtitle: Text(contact.lastname
              .toString()), // Adjust according to your ContactListModel
        );
      },
    );
  }

  /// contact section
  ///
  Widget _buildContactSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 15.h),
          child: Text(
            "Favorite",
            style: textBold.copyWith(color: AppColor.black, fontSize: 15.spMin),
          ),
        ),
        Divider(
          color: AppColor.black,
          height: 0,
        ),
        Flexible(child: _buildFavoriteContactsList()),
        Divider(
          color: AppColor.black,
          height: 0,
        ),
        Padding(
          padding: EdgeInsets.only(left: 15.w, top: 15.h),
          child: Text(
            "Contacts",
            style: textBold.copyWith(color: AppColor.black, fontSize: 16.spMin),
          ),
        ),
      ],
    );
  }

  /// contact list view

  Widget _buildContactList() {
    return Observer(builder: (_) {
      return ListView.builder(
        scrollDirection: Axis.vertical,
        shrinkWrap: true,
        itemCount: groupedContacts.length,
        itemBuilder: (context, index) {
          final letter = groupedContacts.keys.elementAt(index);
          final contactList = groupedContacts[letter]!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Display the letter as a section header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Text(
                  letter,
                  style: textRegular.copyWith(color: AppColor.grey),
                ),
              ),
              // Display the contacts for this letter
              ...contactList.map((contact) {
                bool isSelected = _value;
                bool _isfavorite = authStore.selectedFavorite.contains(contact);

                return GestureDetector(
                  onLongPress: () {
                    onLongPressContact(_value);
                  },
                  onTap: () {
                    appRouter.replaceAll([DeleteEditRoute(id: contact.id!)]);
                  },
                  child: Column(
                    children: [
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.file(
                              File(contact.image!),
                              height: 50,
                              width: 50,
                              fit: BoxFit.cover,
                            ),
                          ),
                          SizedBox(width: 10),
                          Text(
                            "${contact.firstname} ",
                            style: textMedium.copyWith(color: AppColor.grey),
                          ),
                          Text(contact.lastname!, style: textMedium),
                          Spacer(),
                          if (isSelected)
                            InkWell(
                              onTap: () {
                                isfavorite(contact);
                              },
                              child: Container(
                                child: _isfavorite
                                    ? Icon(Icons.favorite,
                                        size: 20.0, color: Colors.red)
                                    : Icon(Icons.favorite,
                                        size: 20.0, color: Colors.grey),
                              ),
                            ),
                          SizedBox(width: 10),
                          if (isSelected)
                            Observer(builder: (_) {
                              var isChecked =
                                  authStore.selectedContacts.contains(contact);

                              return GestureDetector(
                                onTap: () {
                                  authStore.isChecked(contact);
                                  setState(() {});
                                },
                                child: Container(
                                  height: 20,
                                  width: 20,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      width: 1,
                                      color: AppColor.blueDiamond,
                                    ),
                                    shape: BoxShape.circle,
                                    color: isChecked
                                        ? Colors.blue
                                        : AppColor.transparent,
                                  ),
                                  child: isChecked
                                      ? Icon(Icons.check,
                                          size: 15.0, color: Colors.white)
                                      : null,
                                ),
                              );
                            }),
                        ],
                      ).wrapPaddingSymmetric(vertical: 8),
                      Divider(),
                    ],
                  ),
                );
              }).toList(),
            ],
          ).wrapPaddingSymmetric(horizontal: 15.w);
        },
      );
    });
  }
}
