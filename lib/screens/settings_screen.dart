import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../widgets/custom_button.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  static const routeName = '/settings';

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    // Pre-fill the field with the current global value.
    _nameController = TextEditingController(
      text: context.read<AppStateProvider>().profileName,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Appearance', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              // SwitchListTile bound directly to global state.
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Dark mode'),
                subtitle: const Text('Applies across the whole app'),
                value: appState.isDarkMode,
                onChanged: (_) => context.read<AppStateProvider>().toggleTheme(),
              ),
              const Divider(height: 32),
              Text('Profile', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Display name',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CustomButton(
                    label: 'Save name',
                    icon: Icons.save_outlined,
                    onPressed: () {
                      context.read<AppStateProvider>().setProfileName(_nameController.text);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Profile name updated')),
                      );
                    },
                  ),
                ],
              ),
              const Divider(height: 32),
              CustomButton(
                label: 'Reset progress',
                icon: Icons.refresh,
                outlined: true,
                onPressed: () => context.read<AppStateProvider>().resetProgress(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
