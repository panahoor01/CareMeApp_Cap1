import 'package:flutter/material.dart';

class EditBeauticianProfilePage extends StatefulWidget {
  const EditBeauticianProfilePage({super.key});

  @override
  State<EditBeauticianProfilePage> createState() =>
      _EditBeauticianProfilePageState();
}

class _EditBeauticianProfilePageState extends State<EditBeauticianProfilePage> {
  final TextEditingController _nameController =
      TextEditingController(text: 'Aliza Watts');
  final TextEditingController _specialtyController =
      TextEditingController(text: 'Hair');
  final TextEditingController _servicesController =
      TextEditingController(text: 'Hair, Nails');
  final TextEditingController _priceController =
      TextEditingController(text: '₱1500');

  @override
  void dispose() {
    _nameController.dispose();
    _specialtyController.dispose();
    _servicesController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Beautician Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTextField(label: 'Name', controller: _nameController),
            const SizedBox(height: 12),
            _buildTextField(
                label: 'Specialty', controller: _specialtyController),
            const SizedBox(height: 12),
            _buildTextField(
                label: 'Services (comma separated)',
                controller: _servicesController),
            const SizedBox(height: 12),
            _buildTextField(
                label: 'Starting Price', controller: _priceController),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Beautician profile saved.')),
                );
              },
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                backgroundColor: const Color(0xFF7BB8F0),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('Save Changes', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
      {required String label, required TextEditingController controller}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          ),
        ),
      ],
    );
  }
}
