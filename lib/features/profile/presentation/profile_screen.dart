import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:axion/core/theme/app_theme.dart';
import 'package:axion/core/constants/app_constants.dart';
import 'package:axion/core/widgets/gradient_background.dart';
import 'package:axion/features/interview/models/interview_models.dart';
import 'package:axion/features/profile/providers/profile_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);

    if (profile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        automaticallyImplyLeading: true,
        actions: [
          TextButton.icon(
            onPressed: () => _showEditModal(context, profile),
            icon: const Icon(Icons.edit_rounded, size: 16),
            label: const Text('Editar'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: GradientBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 32),

              // Avatar
              _Avatar(profile: profile),
              const SizedBox(height: 16),
              Text(
                profile.displayName ?? 'Usuário',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${profile.preferredArea?.label ?? 'N/A'} • ${profile.seniorityLevel?.label ?? 'N/A'}',
                style: const TextStyle(fontSize: 14, color: AppColors.textTertiary),
              ),
              const SizedBox(height: 48),

              // Sign out
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () => _confirmSignOut(context, ref),
                  icon: const Icon(Icons.logout_rounded, color: AppColors.error),
                  label: const Text(
                    'Sair do App',
                    style: TextStyle(
                        color: AppColors.error, fontWeight: FontWeight.w600),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                          color: AppColors.error.withValues(alpha: 0.2)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditModal(BuildContext context, UserProfile profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditProfileSheet(profile: profile),
    );
  }

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair do App'),
        content: const Text('Tem certeza que deseja sair da sua conta?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(userProfileProvider.notifier).signOut();
            },
            child: const Text('Sair',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

// ─── Avatar ──────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final UserProfile profile;
  const _Avatar({required this.profile});

  @override
  Widget build(BuildContext context) {
    final initial = profile.displayName?.isNotEmpty == true
        ? profile.displayName![0].toUpperCase()
        : profile.email.isNotEmpty
            ? profile.email[0].toUpperCase()
            : '?';

    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: profile.photoUrl == null
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.accent, AppColors.accentDark],
              )
            : null,
        image: profile.photoUrl != null
            ? DecorationImage(
                image: FileImage(File(profile.photoUrl!)),
                fit: BoxFit.cover,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.4),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: profile.photoUrl == null
          ? Center(
              child: Text(
                initial,
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            )
          : null,
    ).animate().scale(duration: 400.ms, curve: Curves.elasticOut);
  }
}

// ─── Edit Profile Bottom Sheet ────────────────────────────────────────────────

class _EditProfileSheet extends ConsumerStatefulWidget {
  final UserProfile profile;
  const _EditProfileSheet({required this.profile});

  @override
  ConsumerState<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  late final TextEditingController _nameController;
  late InterviewArea? _selectedArea;
  late SeniorityLevel? _selectedLevel;
  String? _selectedPhotoUrl;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.profile.displayName ?? '');
    _nameController.addListener(() => setState(() {}));
    _selectedArea = widget.profile.preferredArea;
    _selectedLevel = widget.profile.seniorityLevel;
    _selectedPhotoUrl = widget.profile.photoUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _isValid =>
      _nameController.text.trim().length >= 2 &&
      _selectedArea != null &&
      _selectedLevel != null;

  void _save() {
    if (!_isValid) return;
    final profile = ref.read(userProfileProvider);
    if (profile != null) {
      ref.read(userProfileProvider.notifier).updateProfile(
            profile.copyWith(
              displayName: _nameController.text.trim(),
              preferredArea: _selectedArea,
              seniorityLevel: _selectedLevel,
              photoUrl: _selectedPhotoUrl,
            ),
          );
    }
    Navigator.pop(context);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _selectedPhotoUrl = image.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.62,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                const Text(
                  'Editar Perfil',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: AppColors.textTertiary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.border),

          // Scrollable fields
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Photo selection
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.surfaceLight,
                            border: Border.all(color: AppColors.border, width: 2),
                            image: _selectedPhotoUrl != null
                                ? DecorationImage(
                                    image: FileImage(File(_selectedPhotoUrl!)),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: _selectedPhotoUrl == null
                              ? const Icon(Icons.person_rounded,
                                  size: 50, color: AppColors.textTertiary)
                              : null,
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: AppColors.accent,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt_rounded,
                                  size: 18, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Nome
                  const Text('Nome',
                      style: TextStyle(
                          fontSize: 13, color: AppColors.textTertiary)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                        hintText: 'Como podemos te chamar?'),
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),

                  const SizedBox(height: 24),

                  // Área
                  const Text('Área Preferida',
                      style: TextStyle(
                          fontSize: 13, color: AppColors.textTertiary)),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<InterviewArea>(
                        value: _selectedArea,
                        isExpanded: true,
                        dropdownColor: AppColors.surfaceLight,
                        style: const TextStyle(
                            color: AppColors.textPrimary, fontSize: 15),
                        icon: const Icon(Icons.expand_more_rounded,
                            color: AppColors.textTertiary),
                        items: InterviewArea.values
                            .map((area) => DropdownMenuItem(
                                  value: area,
                                  child: Text(
                                      '${area.emoji}  ${area.label}'),
                                ))
                            .toList(),
                        onChanged: (area) =>
                            setState(() => _selectedArea = area),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Senioridade
                  const Text('Senioridade',
                      style: TextStyle(
                          fontSize: 13, color: AppColors.textTertiary)),
                  const SizedBox(height: 8),
                  Column(
                    children: SeniorityLevel.values
                        .map((level) => _LevelTile(
                              level: level,
                              isSelected: _selectedLevel == level,
                              onTap: () =>
                                  setState(() => _selectedLevel = level),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
          ),

          // Save button
          Padding(
            padding: EdgeInsets.fromLTRB(24, 8, 24, bottomPadding + 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isValid ? _save : null,
                child: const Text('Salvar'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Level Tile (compact) ─────────────────────────────────────────────────────

class _LevelTile extends StatelessWidget {
  final SeniorityLevel level;
  final bool isSelected;
  final VoidCallback onTap;

  const _LevelTile({
    required this.level,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accent.withValues(alpha: 0.1)
              : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    level.label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppColors.accent
                          : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    level.description,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textTertiary),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected
                  ? Icons.check_circle_rounded
                  : Icons.circle_outlined,
              color: isSelected ? AppColors.accent : AppColors.border,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
