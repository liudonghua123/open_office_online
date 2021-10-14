class Provider {
  String name;
  String url;
  bool enabled;
  String? icon;
  Provider(
      {required this.name, required this.url, required this.enabled, this.icon});

  Provider.fromJson(Map<String, dynamic> json)
      : name = json['name'],
        url = json['url'],
        enabled = json['enabled'],
        icon = json['icon'];

  Map<String, dynamic> toJson() => {
        'name': name,
        'url': url,
        'enabled': enabled,
        'icon': icon,
      };
}
