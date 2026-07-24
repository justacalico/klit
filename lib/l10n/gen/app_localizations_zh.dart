// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsSectionAccounts => '账号';

  @override
  String get settingsSectionUser => '用户';

  @override
  String get settingsSectionAppearance => '外观';

  @override
  String get settingsSectionInteractions => '交互';

  @override
  String get settingsSectionSecurity => '安全';

  @override
  String get settingsSectionDevelopment => '开发';

  @override
  String get settingsLanguageTitle => '语言';

  @override
  String get settingsLanguageSystem => '系统默认';

  @override
  String get settingsLanguageEnglish => '英语';

  @override
  String get settingsLanguageSimplifiedChinese => '简体中文';

  @override
  String get aboutSectionTitle => '关于';

  @override
  String get aboutDevEnabled => '您现在是开发者了！';

  @override
  String get aboutVersionTitle => '版本';

  @override
  String get aboutWebsiteTitle => '网站';

  @override
  String get aboutFetchingUpdates => '正在获取更新...';

  @override
  String get aboutFailedCheckUpdates => '检查更新失败';

  @override
  String get aboutNewestVersion => '您已是最新版本';

  @override
  String aboutNewerVersionAvailable(Object version) {
    return '有新版本可用：$version';
  }

  @override
  String get aboutNewerVersionAvailablePrefix => '有新版本可用：';

  @override
  String get commonCancelUpper => '取消';

  @override
  String get commonDownloadUpper => '下载';

  @override
  String get commonLaterUpper => '稍后';

  @override
  String get commonCancel => '取消';

  @override
  String get commonDelete => '删除';

  @override
  String get commonSave => '保存';

  @override
  String get commonImportUpper => '导入';

  @override
  String get commonOkUpper => '确定';

  @override
  String get commonRestartNowUpper => '立即重启';

  @override
  String get aboutCheckForUpdate => '检查更新';

  @override
  String get aboutCheckingForUpdates => '正在检查更新...';

  @override
  String get feedsTitle => '订阅源';

  @override
  String get feedsNewFeedTitle => '新建订阅源';

  @override
  String get feedsEditFeedTitle => '编辑订阅源';

  @override
  String get feedsDeleteDialogTitle => '删除订阅源';

  @override
  String feedsDeleteDialogBody(Object name) {
    return '删除“$name”？';
  }

  @override
  String get feedsEmptyTitle => '暂无订阅源';

  @override
  String get feedsEmptyBody => '使用标签和图片或视频类型创建订阅源，一键浏览帖子';

  @override
  String get feedsCreateFeed => '创建订阅源';

  @override
  String get databaseExporting => '正在导出数据库...';

  @override
  String get databaseImporting => '正在导入数据库...';

  @override
  String get databaseExportDialogTitle => '导出数据库';

  @override
  String get databaseExportSuccess => '数据库导出成功';

  @override
  String get databaseExportFailed => '导出失败';

  @override
  String get databaseExportTitle => '导出';

  @override
  String get databaseExportSubtitle => '保存数据库的备份副本';

  @override
  String get databaseImportDialogTitle => '导入数据库';

  @override
  String databaseImportInvalidFile(Object error) {
    return '无效的数据库文件：$error';
  }

  @override
  String databaseImportFailed(Object error) {
    return '导入失败：$error';
  }

  @override
  String get databaseImportTitle => '导入';

  @override
  String get databaseImportSubtitle => '用导入的文件替换当前数据库';

  @override
  String get databaseImportWarningBody => '这将替换您当前的数据库。\\n所有数据将丢失。此操作不可撤销！';

  @override
  String get databaseRestartRequiredTitle => '需要重启';

  @override
  String get databaseRestartRequiredBody => '应用需要重启以应用更改。';

  @override
  String postUpdateSuccess(Object id) {
    return '已更新帖子 #$id';
  }

  @override
  String postUpdateFailed(Object id) {
    return '更新帖子 #$id 失败';
  }

  @override
  String tagPreviewLoadFailed(Object error) {
    return '加载标签预览失败：$error';
  }

  @override
  String get tooltipInfo => '信息';

  @override
  String get tooltipCopy => '复制';

  @override
  String get tooltipDelete => '删除';

  @override
  String get tooltipAbort => '中止';

  @override
  String get tooltipSelectAll => '全选';

  @override
  String get tooltipPrevious => '上一个';

  @override
  String get tooltipNext => '下一个';
}
