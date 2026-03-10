class UpdateInfo {
  final String latestVersion;
  final int versionCode;
  final String apkUrl;
  final String releaseNotes;
  final bool mandatory;
  final String? minSupportedVersion;

  UpdateInfo({
    required this.latestVersion,
    required this.versionCode,
    required this.apkUrl,
    required this.releaseNotes,
    required this.mandatory,
    this.minSupportedVersion,
  });

  factory UpdateInfo.fromJson(Map<String, dynamic> json) {
    return UpdateInfo(
      latestVersion: json['latest_version'] ?? '1.0.0',
      versionCode: json['version_code'] ?? 1,
      apkUrl: json['apk_url'] ?? '',
      releaseNotes: json['release_notes'] ?? 'Actualización disponible',
      mandatory: json['mandatory'] ?? false,
      minSupportedVersion: json['min_supported_version'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latest_version': latestVersion,
      'version_code': versionCode,
      'apk_url': apkUrl,
      'release_notes': releaseNotes,
      'mandatory': mandatory,
      'min_supported_version': minSupportedVersion,
    };
  }

  @override
  String toString() {
    return 'UpdateInfo{latestVersion: $latestVersion, versionCode: $versionCode, mandatory: $mandatory}';
  }
}
