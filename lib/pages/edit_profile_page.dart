import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_practice/auth/auth_service.dart';
import 'package:flutter_application_practice/profile/profile_service.dart';
import 'package:flutter_application_practice/profile/profile_widgets.dart';
import 'package:flutter_application_practice/screens/signup_screen/signup_widget.dart';
import 'package:image_picker/image_picker.dart';

class EditProfilePage extends StatefulWidget {
  final ProfileData profile;
  const EditProfilePage({super.key, required this.profile});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  static const _maxNameLength = 40;
  static final _nameRegex = RegExp(r'^[\p{L} ]+$', unicode: true);

  final _service = ProfileService();
  late final _first = TextEditingController(text: widget.profile.firstName);
  late final _last = TextEditingController(text: widget.profile.lastName);
  late final _bio = TextEditingController(text: widget.profile.bio ?? '');

  Uint8List? _newImage;
  String _newImageType = 'image/jpeg';
  bool _removeImage = false;
  bool _saving = false;
  String? _firstError;
  String? _lastError;

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _bio.dispose();
    super.dispose();
  }

  String _clean(String v) => v.trim().replaceAll(RegExp(r'\s+'), ' ');

  String? _validateName(String v, String label) {
    if (v.isEmpty) return 'Please enter your $label name.';
    if (v.length > _maxNameLength) {
      return 'Maximum of $_maxNameLength characters only.';
    }
    if (!_nameRegex.hasMatch(v)) return 'Only letters and spaces are allowed.';
    return null;
  }

  Future<void> _pickImage() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      _newImage = bytes;
      _newImageType = file.mimeType ?? 'image/jpeg';
      _removeImage = false;
    });
  }

  Future<void> _save() async {
    final first = _clean(_first.text);
    final last = _clean(_last.text);
    final firstError = _validateName(first, 'first');
    final lastError = _validateName(last, 'last');
    if (firstError != null || lastError != null) {
      setState(() {
        _firstError = firstError;
        _lastError = lastError;
      });
      return;
    }

    setState(() => _saving = true);
    try {
      String? image = _removeImage ? null : widget.profile.profileImage;
      if (_newImage != null) {
        image = await _service.uploadAvatar(_newImage!, _newImageType);
      }
      await _service.updateProfile(
        firstName: first,
        lastName: last,
        bio: _bio.text.trim(),
        profileImage: image,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AuthService.friendlyError(e))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = _newImage != null ||
        (!_removeImage && (widget.profile.profileImage ?? '').isNotEmpty);

    return SignupStepScaffold(
      title: 'Edit Profile',
      heading: 'Edit your profile.',
      subheading: 'Update your photo, name, and bio.',
      continueLabel: _saving ? 'Saving...' : 'Save',
      continueEnabled: !_saving,
      onContinue: _save,
      child: Column(
        children: [
          Center(
            child: Stack(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: ProfileAvatar(
                    initial: widget.profile.initial,
                    imageUrl: _removeImage ? null : widget.profile.profileImage,
                    bytes: _newImage,
                    size: 96,
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                        color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.camera_alt, size: 18),
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                  onPressed: _pickImage, child: const Text('Change photo')),
              if (hasPhoto)
                TextButton(
                  onPressed: () => setState(() {
                    _newImage = null;
                    _removeImage = true;
                  }),
                  child: const Text('Remove photo'),
                ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _first,
            textCapitalization: TextCapitalization.words,
            inputFormatters: [LengthLimitingTextInputFormatter(_maxNameLength)],
            onChanged: (_) {
              if (_firstError != null) setState(() => _firstError = null);
            },
            decoration: signupInputDecoration('First name')
                .copyWith(errorText: _firstError),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _last,
            textCapitalization: TextCapitalization.words,
            inputFormatters: [LengthLimitingTextInputFormatter(_maxNameLength)],
            onChanged: (_) {
              if (_lastError != null) setState(() => _lastError = null);
            },
            decoration: signupInputDecoration('Last name')
                .copyWith(errorText: _lastError),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _bio,
            maxLines: 3,
            maxLength: 100,
            textCapitalization: TextCapitalization.sentences,
            decoration: signupInputDecoration('Bio'),
          ),
        ],
      ),
    );
  }
}
