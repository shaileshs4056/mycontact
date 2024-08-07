import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:contact_number_demo/core/db/app_db.dart';
import 'package:contact_number_demo/data/model/contact/contact.dart';
import 'package:contact_number_demo/generated/assets.dart';
import 'package:contact_number_demo/router/app_router.dart';
import 'package:contact_number_demo/ui/home/add_contact_number.dart';
import 'package:contact_number_demo/util/media_picker.dart';
import 'package:contact_number_demo/values/colors.dart';
import 'package:contact_number_demo/values/extensions/widget_ext.dart';
import 'package:contact_number_demo/values/style.dart';
import 'package:contact_number_demo/values/validator.dart';
import 'package:contact_number_demo/widget/button_widget.dart';
import 'package:contact_number_demo/widget/media_picker_bottomsheet.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:permission_handler/permission_handler.dart';

@RoutePage()
class DeleteEditPage extends StatefulWidget {
  final int id;
  DeleteEditPage({super.key, required this.id});
  @override
  State<DeleteEditPage> createState() => _DeleteEditPageState();
}

class _DeleteEditPageState extends State<DeleteEditPage> {
  late GlobalKey<FormState> _formKey;

  late TextEditingController firstNameController;
  late TextEditingController lastNameController;
  late TextEditingController CompanyController;
  late FocusNode firstNameNode;
  late FocusNode lastNameNode;
  late FocusNode CompanyNode;
  late ValueNotifier<bool> showLoading;

  String? image;
  List<XFile?>? pickedFilesListStore = [];
  List<PlatformFile>? pickedDocuments;
  FilesType? type;
  int? count;
  XFile? _image;
  File? oldImage;
  final ImagePicker _picker = ImagePicker();

  Future getImageFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    setState(() {
      _image = image;
    });
  }

  late ContactListModel originalContact;
  void initState() {
    _formKey = GlobalKey<FormState>();
    super.initState();
    final contact = appDB.contacts[widget.id]; // Retrieve contact by index
    firstNameController = TextEditingController(text: contact.firstname);
    lastNameController = TextEditingController(text: contact.lastname);
    CompanyController = TextEditingController(text: contact.company);
    oldImage = File(contact.image!);

    firstNameNode = FocusNode();
    lastNameNode = FocusNode();
    CompanyNode = FocusNode();
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    CompanyController.dispose();
    firstNameNode.dispose();
    lastNameNode.dispose();
    CompanyNode.dispose();
    super.dispose();
  }

  void clearForm() {
    firstNameController.clear();
    lastNameController.clear();
    CompanyController.clear();
  }

  @override
  Widget build(BuildContext context) {
    print(oldImage!.path);
    return Scaffold(
      backgroundColor: AppColor.mercury,
      appBar: AppBar(
        automaticallyImplyLeading: true,
        leadingWidth: 60.w,
        backgroundColor: AppColor.mercury,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: InkWell(
          onTap: () {
            appRouter.replaceAll([ShowContactListRoute()]);
          },
          child: Text(
            "Cancel",
            style: textBold.copyWith(color: AppColor.blueDiamond),
          ).wrapPaddingOnly(top: 15.h, left: 5.w),
        ),
        title: Text(
          "New Contact",
          style: textRegular.copyWith(color: AppColor.black),
        ),
        centerTitle: true,
        actions: [
          InkWell(
            onTap: () async {
              if (_formKey.currentState?.validate() ?? false) {
                // Get the index from widget.id (assuming widget.id represents the index)
                final index = widget.id;

                // Retrieve the current contacts list
                final contacts = await appDB.contacts;

                // Get the existing contact at the index
                final existingContact = contacts[index];

                // Update the fields directly
                final updatedContact = existingContact.copyWith(
                  firstname: firstNameController.text,
                  lastname: lastNameController.text,
                  company: CompanyController.text,
                  image: _image!.path,
                );

                // Update the contact in Hive
                await appDB.updateContactAtIndex(index, updatedContact);

                // Clear the form and navigate
                clearForm();
                context.router.replaceAll([ShowContactListRoute()]);
              }
            },
            child: Text(
              "Edit",
              style: textRegular.copyWith(color: AppColor.blueDiamond),
            ).wrapPaddingOnly(top: 15.h, right: 15.w),
          )
        ],
      ),
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(vertical: 20.h),
              width: 1.sw,
              color: AppColor.mercury,
              child: Column(
                children: [
                  InkWell(
                    onTap: () async {},
                    child: CircleAvatar(
                        radius: 90.r,
                        backgroundColor: AppColor.grey,
                        backgroundImage: oldImage == null
                            ? FileImage((File(_image!.path)))
                            : FileImage(File(oldImage!.path))),
                  ),
                  10.verticalSpace,
                  ElevatedButton(
                    style: ButtonStyle(
                        backgroundColor:
                            WidgetStateProperty.all(AppColor.white)),
                    onPressed: () async {
                      bool hasPermission = await requestCameraPermissions();
                      if (hasPermission) {
                        getImageFromGallery();
                      }
                    },
                    child: Text(
                      'Edit Image',
                      style: textMedium.copyWith(color: AppColor.black),
                    ),
                  ),

                  // Container(
                  //   decoration: BoxDecoration(
                  //     color: AppColor.white,
                  //     borderRadius: BorderRadius.circular(20.r),
                  //   ),
                  //   padding:
                  //       EdgeInsets.symmetric(horizontal: 25.w, vertical: 8.h),
                  //   child: Text(
                  //     "Add Photo",
                  //     style: textBold.copyWith(
                  //       color: AppColor.black,
                  //     ),
                  //   ),
                  // )
                ],
              ),
            ),
            Container(
              color: AppColor.white,
              child: Column(
                children: [getSignInForm()],
              ),
            ),
            20.verticalSpace,
            // buildCustomContainer(icon: Icons.add, text: "add Phone"),
            // 30.verticalSpace,
            // buildCustomContainer(icon: Icons.add, text: "add email"),
            // 30.verticalSpace,
            // buildCustomContainer(icon: Icons.add, text: "add pronounce"),
            // 30.verticalSpace,
            // buildCustomContainerWithTextAndIcon(
            //     icon: Icons.arrow_forward_ios_outlined,
            //     leadingText: "Ringtone",
            //     trailingText: "Dedault"),
            // 30.verticalSpace,
            // buildCustomContainerWithTextAndIcon(
            //     icon: Icons.arrow_forward_ios_outlined,
            //     leadingText: "Text Tone",
            //     trailingText: "Dedault"),

            AppButton(
              "Delete",
              () {
                if (_formKey.currentState?.validate() ?? false) {
                  // Edit existing contact
                  showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Lottie.network(
                                'https://assets7.lottiefiles.com/packages/lf20_fcfjwiyb.json',
                                width: 100,
                                height: 100,
                                repeat: false,
                              ),
                              SizedBox(height: 20),
                              Text(
                                "Data deleted successfully",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 20),
                            ],
                          ),
                          actions: [
                            ElevatedButton(
                              onPressed: () {
                                appRouter.pop();
                                // contactList.removeAt(widget.id);
                                // appRouter.replaceAll([ShowContactListRoute()]);
                              },
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                              ),
                              child: Text('OK'),
                            ),
                          ],
                        );
                      });
                }
              },
              buttonColor: true,
            ).wrapPaddingSymmetric(horizontal: 15.w)
          ],
        ),
      ),
    );
  }

  Future<bool> requestCameraPermissions() async {
    Map<Permission, PermissionStatus> permissions = {};
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      permissions = await [
        Permission.camera,
        Permission.videos,
        if (androidInfo.version.sdkInt > 32)
          Permission.photos
        else
          Permission.storage,
      ].request();
    } else {
      permissions = await [
        Permission.camera,
        Permission.storage,
        Permission.videos,
      ].request();
    }

    final PermissionStatus? cameraStatus = permissions[Permission.camera];
    final PermissionStatus? storageStatus = permissions[Permission.storage];
    final PermissionStatus? videoStatus = permissions[Permission.videos];

    debugPrint(
      "permission status : camera $cameraStatus storage $storageStatus video $videoStatus ",
    );

    if ((cameraStatus?.isGranted == true || cameraStatus?.isLimited == true) &&
        (videoStatus?.isGranted == true ||
            videoStatus?.isLimited == true ||
            storageStatus?.isGranted == true ||
            storageStatus?.isLimited == true)) {
      debugPrint('Camera Permission: GRANTED');
      return true;
    }
    return false;
  }

  Future<File?> pickFile(FilesType type) async {
    setState(() {
      pickedFilesListStore = null;
      pickedDocuments = null;
      this.type = null;
    });
    switch (type) {
      case FilesType.image:
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (context) => MediaPickerSheet(
            pickFileType: PickedFileType.image,
            onSelectFile: (file, pickedFileType) {
              if (file != null) {
                if (mounted) {
                  setState(() {
                    count = count != null ? count! + 1 : 1;
                    pickedFilesListStore?.add(file);
                  });
                }
              }
            },
          ),
        );
        break;
      case FilesType.video:
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (context) => MediaPickerSheet(
            pickFileType: PickedFileType.video,
            onSelectFile: (file, pickedFileType) {
              debugPrint('Selected media type $pickedFileType');
              debugPrint('Selected file path ${file?.path}');
              if (file != null) {
                if (mounted) {
                  setState(() {
                    count = count != null ? count! + 1 : 1;
                    pickedFilesListStore?.add(file);
                  });
                }
              }
            },
          ),
        );
        break;
      case FilesType.documents:
        pickedDocuments =
            await DocumentPicker.pickDocument(fileType: FileType.any);
        break;
      case FilesType.audio:
        pickedDocuments = await DocumentPicker.pickDocument(
          fileType: FileType.audio,
          allowMultiple: true,
        );
        break;
    }
    if (pickedFilesListStore != null) {
      if (mounted) setState(() => count = pickedFilesListStore!.length);
    }
    if (pickedDocuments != null) {
      if (mounted) setState(() => count = pickedDocuments!.length);
    }
  }

  Widget buildCustomContainerWithTextAndIcon({
    required String leadingText,
    required String trailingText,
    required IconData icon,
    Color leadingTextColor = Colors.black,
    Color trailingTextColor = Colors.blue,
    Color backgroundColor = Colors.white,
    TextStyle? textStyle,
  }) {
    return Container(
      color: backgroundColor,
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          Text(
            leadingText,
            style: textStyle ??
                TextStyle(fontSize: 16.sp, color: leadingTextColor),
          ),
          SizedBox(width: 15.w),
          Text(
            trailingText,
            style: (textStyle ?? TextStyle(fontSize: 16.sp))
                .copyWith(color: trailingTextColor),
          ),
          Spacer(),
          Icon(
            icon,
            size: 15.h,
          ),
        ],
      ).wrapPaddingSymmetric(horizontal: 15.w),
    );
  }

  Widget buildCustomContainer({
    required String text,
    required IconData icon,
    Color iconColor = Colors.white,
    Color backgroundColor = Colors.green,
  }) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: backgroundColor.withOpacity(0.5),
            ),
            child: Icon(
              icon,
              size: 15.h,
              color: iconColor,
            ),
          ),
          SizedBox(width: 15.w),
          Text(
            text,
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.black,
            ), // You can use your textMedium style here
          ),
        ],
      ).wrapPaddingSymmetric(horizontal: 15.w),
    );
  }

  Widget getSignInForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: firstNameController,
            validator: nameValidator,
            focusNode: firstNameNode,
            decoration: InputDecoration(
              hintText: "First name",
            ),
          ),
          TextFormField(
            controller: lastNameController,
            validator: nameValidator,
            focusNode: lastNameNode,
            decoration: InputDecoration(
              hintText: "Last name",
            ),
          ),
          TextFormField(
            controller: CompanyController,
            focusNode: CompanyNode,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: "Company",
            ),
          ),
        ],
      ),
    ).wrapPaddingSymmetric(horizontal: 15.w);
  }
}

// To show the dialog
void showSuccessDialog(BuildContext context, String message) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Text("bfcjsjb");
    },
  );
}
