import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class SpacePhotoPicker extends StatefulWidget {
  final void Function(List<File>) onChanged;

  const SpacePhotoPicker({
    super.key,
    required this.onChanged,
  });

  @override
  State<SpacePhotoPicker> createState() => _SpacePhotoPickerState();
}

class _SpacePhotoPickerState extends State<SpacePhotoPicker> {
  final List<File> _photos = [];

  Future<void> _pickImages() async {
    final images = await ImagePicker().pickMultiImage(imageQuality: 80);
    if (images.isEmpty) return;

    setState(() {
      _photos.addAll(images.map((x) => File(x.path)));
    });

    widget.onChanged(_photos);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 54,
          child: OutlinedButton.icon(
            onPressed: _pickImages,
            icon: const Icon(Icons.photo_library_rounded),
            label: const Text('Add Lot Photos'),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _photos.map((photo) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.file(
                photo,
                width: 90,
                height: 90,
                fit: BoxFit.cover,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
