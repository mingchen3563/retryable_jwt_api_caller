class DynamicTokens {
  final String idToken;
  final String accessToken;
  final String refreshToken;
  final String sub;

  DynamicTokens({
    required this.idToken,
    required this.accessToken,
    required this.refreshToken,
    required this.sub,
  });

  Map<String, dynamic> toJson() => {
        'idToken': idToken,
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'sub': sub,
      };

  factory DynamicTokens.fromJson(Map<String, dynamic> json) => DynamicTokens(
        idToken: json['idToken'] as String,
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
        sub: json['sub'] as String,
      );
}
