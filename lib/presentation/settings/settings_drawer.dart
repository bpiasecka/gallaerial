import 'package:flutter/material.dart';
import 'package:gallaerial/domain/entities/settings_model.dart';
import 'package:gallaerial/domain/useCases/settings/edit_settings_use_case%20copy.dart';
import 'package:gallaerial/main.dart';

class SettingsSideMenu extends StatefulWidget {
  final SettingsModel settings;

  const SettingsSideMenu({super.key, required this.settings});

  @override
  State<SettingsSideMenu> createState() => _SettingsSideMenuState();
}

class _SettingsSideMenuState extends State<SettingsSideMenu> {
  late bool showNames;
  late bool expandTags;

  @override
  void initState() {
    showNames = widget.settings.showNames;
    expandTags = widget.settings.expandTags;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 12.0),
      child: Text("Settings", style: Theme.of(context).textTheme.titleLarge),
    ), 
    const Divider(height: 12),
        SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              "Show video names",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            value: showNames,
            onChanged: (val) {
              setState(() => showNames = val);
              service<EditSettingsUsecase>().call(SettingsModel(showNames: val, expandTags: expandTags));
            }),
        SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              "Expand all label names",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            value: expandTags,
            onChanged: (val) {
              setState(() => expandTags = val);
              service<EditSettingsUsecase>().call(SettingsModel(showNames: showNames, expandTags: val));
            }),
            const Expanded(child: SizedBox(width: 1,),),
        TextButton(
            onPressed: () {
              showLicensePage(
                context: context,
                applicationName: 'Gallaerial',
                //applicationVersion: '1.0.0',
                //applicationLegalese: '© 2026 basia',
              );
            },
            child: const Text('View licences'))
      ]),
    );
  }
}
