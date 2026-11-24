import 'package:auto_route/auto_route.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/i18n/strings.g.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/network/sync/comic_sync_core.dart';
import 'package:zephyr/network/sync/sync_service.dart';
import 'package:zephyr/page/comic_follow/cubit/comic_follow_cubit.dart';
import 'package:zephyr/page/setting/common/setting_ui.dart';
import 'package:zephyr/page/setting/global/widgets.dart';
import 'package:zephyr/util/event/event.dart';
import 'package:zephyr/widgets/fluent_dropdown.dart';
import 'package:zephyr/widgets/toast.dart';

/// 自定义同步密钥的最小长度；空串仍表示使用默认密钥。
const int _syncKeyMinLength = 8;

@RoutePage()
class SyncSettingPage extends StatefulWidget {
  const SyncSettingPage({super.key});

  @override
  State<SyncSettingPage> createState() => _SyncSettingPageState();
}

class _SyncSettingPageState extends State<SyncSettingPage> {
  bool _uploading = false;
  bool _downloading = false;

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<GlobalSettingCubit>();
    final state = cubit.state;
    final configuredSync = isSyncServiceConfigured(state);

    return SettingPageShell(
      title: t.settings.sync,
      child: ListView(
        children: [
          settingSectionTitle(
            context,
            t.settings.sync,
            icon: Icons.sync_outlined,
          ),
          _syncServiceType(state, cubit),
          _encryptionKey(state, cubit),
          webdavSync(context, state.syncSetting.syncServiceType),
          if (configuredSync) _autoSync(state, cubit),
          if (configuredSync && state.syncSetting.autoSync)
            _syncInterval(state, cubit),
          if (configuredSync && state.syncSetting.autoSync)
            _syncNotify(state, cubit),
          if (configuredSync) _syncSettings(state, cubit),
          if (configuredSync) _syncPlugins(state, cubit),
          if (configuredSync) ...[
            const SizedBox(height: 8),
            const Divider(height: 1, thickness: 0.3),
            settingSectionTitle(context, t.settings.manualSyncSection),
            _buildManualSyncTile(
              icon: Icons.upload_outlined,
              title: t.settings.uploadToCloud,
              subtitle: t.settings.uploadToCloudSubtitle,
              actionLabel: t.settings.manualUpload,
              busy: _uploading,
              onPressed: _manualUpload,
            ),
            _buildManualSyncTile(
              icon: Icons.download_outlined,
              title: t.settings.downloadFromCloud,
              subtitle: t.settings.downloadFromCloudSubtitle,
              actionLabel: t.settings.manualDownload,
              busy: _downloading,
              onPressed: _manualDownload,
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _manualUpload() async {
    final cubit = context.read<GlobalSettingCubit>();
    setState(() => _uploading = true);
    try {
      try {
        await manualUploadToCloud(
          state: cubit.state,
          globalSettingCubit: cubit,
          comicFollowCubit: context.read<ComicFollowCubit>(),
        );
      } on SyncDecryptionException {
        final confirmed = await _confirmOverwriteCloud();
        if (!mounted || confirmed != true) {
          return;
        }
        await manualUploadToCloud(
          state: cubit.state,
          globalSettingCubit: cubit,
          comicFollowCubit: context.read<ComicFollowCubit>(),
          forceOverwrite: true,
        );
      }
      if (mounted) showSuccessToast(t.settings.manualUploadSuccess);
    } catch (e, s) {
      logger.e('手动上传失败', error: e, stackTrace: s);
      if (mounted) {
        if (e is SyncDecryptionException) {
          showErrorToast(
            t.settings.syncKeyErrorCannotDecrypt,
            title: t.settings.syncKeyErrorTitle,
          );
        } else {
          showErrorToast('${t.settings.manualSyncFailed}: $e');
        }
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<bool?> _confirmOverwriteCloud() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.settings.syncKeyErrorTitle),
        content: Text(t.settings.syncKeyOverwriteConfirm),
        actions: [
          TextButton(
            child: Text(t.common.cancel),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: Text(t.settings.syncKeyContinueUpload),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
  }

  Future<void> _manualDownload() async {
    final cubit = context.read<GlobalSettingCubit>();
    setState(() => _downloading = true);
    try {
      await manualDownloadFromCloud(
        state: cubit.state,
        globalSettingCubit: cubit,
        comicFollowCubit: context.read<ComicFollowCubit>(),
      );
      if (mounted) showSuccessToast(t.settings.manualDownloadSuccess);
    } catch (e, s) {
      logger.e('手动下载失败', error: e, stackTrace: s);
      if (mounted) {
        if (e is SyncDecryptionException) {
          showErrorToast(
            t.settings.syncKeyErrorCannotDecrypt,
            title: t.settings.syncKeyErrorTitle,
          );
        } else {
          showErrorToast('${t.settings.manualSyncFailed}: $e');
        }
      }
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  Widget _buildManualSyncTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String actionLabel,
    required bool busy,
    required VoidCallback onPressed,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: busy
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : FilledButton.tonal(onPressed: onPressed, child: Text(actionLabel)),
    );
  }

  Widget _encryptionKey(GlobalSettingState state, GlobalSettingCubit cubit) {
    final key = state.syncSetting.encryptionKey;
    return ListTile(
      leading: const Icon(Icons.key_outlined),
      title: Text(t.settings.customEncryptionKey),
      subtitle: Text(
        key.isEmpty
            ? t.settings.customEncryptionKeyDefault
            : t.settings.customEncryptionKeySet,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _editEncryptionKey(state.syncSetting, cubit),
    );
  }

  Future<void> _editEncryptionKey(
    SyncSettingState syncSetting,
    GlobalSettingCubit cubit,
  ) async {
    var input = syncSetting.encryptionKey;
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.settings.customEncryptionKey),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Form(
              key: formKey,
              child: TextFormField(
                initialValue: input,
                autofocus: true,
                enableSuggestions: false,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: t.settings.customEncryptionKeyHint,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (value) => input = value,
                validator: (value) {
                  final raw = value ?? '';
                  // 旧密钥可能不满足新规则；原样不改时直接放行。
                  if (raw == syncSetting.encryptionKey) return null;
                  if (raw.isEmpty) return null;
                  if (raw.contains(RegExp(r'\s'))) {
                    return t.settings.customEncryptionKeyNoSpaces;
                  }
                  if (raw.length < _syncKeyMinLength) {
                    return t.settings.customEncryptionKeyTooShort(
                      min: _syncKeyMinLength,
                    );
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 12),
            Text(
              t.settings.customEncryptionKeySubtitle,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text(t.common.cancel),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text(t.common.ok),
            onPressed: () {
              if (formKey.currentState?.validate() != true) return;
              Navigator.pop(context, input);
            },
          ),
        ],
      ),
    );
    if (result == null || result == syncSetting.encryptionKey) {
      return;
    }
    cubit.updateSyncSetting(
      (current) => current.copyWith(encryptionKey: result),
    );
    showSuccessToast(t.settings.customEncryptionKeyChanged);
  }

  Widget _syncServiceType(GlobalSettingState state, GlobalSettingCubit cubit) {
    final syncServiceItems = <SyncServiceType, String>{
      SyncServiceType.none: t.settings.syncServiceNone,
      SyncServiceType.webdav: t.settings.syncServiceWebdav,
      SyncServiceType.s3: t.settings.syncServiceS3,
    };

    return ListTile(
      leading: const Icon(Icons.storage_outlined),
      title: Text(t.settings.syncService),
      subtitle: Text(t.settings.syncServiceSubtitle),
      trailing: FluentDropdown<SyncServiceType>(
        value: state.syncSetting.syncServiceType,
        displayValue: syncServiceItems[state.syncSetting.syncServiceType]!,
        items: syncServiceItems,
        onChanged: (SyncServiceType value) {
          if (value == state.syncSetting.syncServiceType) return;
          cubit.updateSyncSetting(
            (current) => current.copyWith(
              syncServiceType: value,
              syncSettings: value == SyncServiceType.none
                  ? false
                  : current.syncSettings,
            ),
          );
        },
      ),
    );
  }

  Widget _autoSync(GlobalSettingState state, GlobalSettingCubit cubit) {
    return SwitchListTile(
      secondary: const Icon(Icons.cloud_sync_outlined),
      title: Text(t.settings.autoSync),
      subtitle: Text(t.settings.autoSyncSubtitle),
      thumbIcon: kSettingSwitchThumbIcon,
      value: state.syncSetting.autoSync,
      onChanged: (bool value) {
        cubit.updateSyncSetting((current) => current.copyWith(autoSync: value));
        if (value) {
          eventBus.fire(NoticeSync());
        }
      },
    );
  }

  Widget _syncInterval(GlobalSettingState state, GlobalSettingCubit cubit) {
    final syncSetting = state.syncSetting;
    return ListTile(
      leading: const Icon(Icons.timer_outlined),
      title: Text(t.settings.syncInterval),
      subtitle: Text(t.settings.syncIntervalSubtitle),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${syncSetting.syncInterval} ${syncSetting.syncIntervalUnit.label}',
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: () => _editSyncInterval(syncSetting, cubit),
    );
  }

  Future<void> _editSyncInterval(
    SyncSettingState syncSetting,
    GlobalSettingCubit cubit,
  ) async {
    var input = syncSetting.syncInterval.toString();
    var unit = syncSetting.syncIntervalUnit;
    String? errorText;

    final result = await showDialog<({int value, SyncIntervalUnit unit})>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(t.settings.syncInterval),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: input,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                ],
                onChanged: (value) => input = value.trim(),
                decoration: InputDecoration(
                  labelText: t.settings.syncIntervalValue,
                  errorText: errorText,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(t.settings.syncIntervalUnitLabel),
                  const Spacer(),
                  FluentDropdown<SyncIntervalUnit>(
                    value: unit,
                    displayValue: unit.label,
                    items: <SyncIntervalUnit, String>{
                      SyncIntervalUnit.second:
                          t.settings.syncIntervalUnitSecond,
                      SyncIntervalUnit.minute:
                          t.settings.syncIntervalUnitMinute,
                      SyncIntervalUnit.hour: t.settings.syncIntervalUnitHour,
                    },
                    onChanged: (value) {
                      setDialogState(() => unit = value);
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text(t.common.cancel),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: Text(t.common.ok),
              onPressed: () {
                final value = int.tryParse(input);
                if (value == null || value <= 0) {
                  setDialogState(
                    () => errorText = t.settings.syncIntervalInvalid,
                  );
                  return;
                }
                Navigator.pop(context, (value: value, unit: unit));
              },
            ),
          ],
        ),
      ),
    );

    if (result == null) {
      return;
    }
    if (result.value == syncSetting.syncInterval &&
        result.unit == syncSetting.syncIntervalUnit) {
      return;
    }
    cubit.updateSyncSetting(
      (current) => current.copyWith(
        syncInterval: result.value,
        syncIntervalUnit: result.unit,
      ),
    );
    showSuccessToast(t.common.settingSaved);
  }

  Widget _syncNotify(GlobalSettingState state, GlobalSettingCubit cubit) {
    return SwitchListTile(
      secondary: const Icon(Icons.notifications_active_outlined),
      title: Text(t.settings.syncNotify),
      subtitle: Text(t.settings.syncNotifySubtitle),
      thumbIcon: kSettingSwitchThumbIcon,
      value: state.syncSetting.syncNotify,
      onChanged: (bool value) {
        cubit.updateSyncSetting(
          (current) => current.copyWith(syncNotify: value),
        );
      },
    );
  }

  Widget _syncSettings(GlobalSettingState state, GlobalSettingCubit cubit) {
    return SwitchListTile(
      secondary: const Icon(Icons.tune_outlined),
      title: Text(t.settings.syncSettings),
      subtitle: Text(t.settings.syncSettingsSubtitle),
      thumbIcon: kSettingSwitchThumbIcon,
      value: state.syncSetting.syncSettings,
      onChanged: (bool value) {
        cubit.updateSyncSetting(
          (current) => current.copyWith(syncSettings: value),
        );
      },
    );
  }

  Widget _syncPlugins(GlobalSettingState state, GlobalSettingCubit cubit) {
    return SwitchListTile(
      secondary: const Icon(Icons.extension_outlined),
      title: Text(t.settings.syncPlugins),
      subtitle: Text(t.settings.syncPluginsSubtitle),
      thumbIcon: kSettingSwitchThumbIcon,
      value: state.syncSetting.syncPlugins,
      onChanged: (bool value) {
        cubit.updateSyncSetting(
          (current) => current.copyWith(syncPlugins: value),
        );
      },
    );
  }
}
