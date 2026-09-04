class NavigationItemModel {
  const NavigationItemModel({
    required this.id,
    required this.name,
    required this.isMenu,
    required this.children,
    this.routeName,
  });

  final String id;
  final String name;
  final bool isMenu;
  final String? routeName;
  final List<NavigationItemModel> children;

  bool get canOpen => routeName != null && routeName!.isNotEmpty;

  NavigationItemModel copyWith({
    String? id,
    String? name,
    bool? isMenu,
    String? routeName,
    List<NavigationItemModel>? children,
  }) {
    return NavigationItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      isMenu: isMenu ?? this.isMenu,
      routeName: routeName ?? this.routeName,
      children: children ?? this.children,
    );
  }

  factory NavigationItemModel.fromJson(Map<String, dynamic> json) {
    final rawChildren = json['children'];
    final children = rawChildren is List
        ? rawChildren
              .whereType<Map>()
              .map(
                (child) => NavigationItemModel.fromJson(
                  Map<String, dynamic>.from(child),
                ),
              )
              .toList(growable: false)
        : const <NavigationItemModel>[];

    final route = json['route_name']?.toString().trim();
    return NavigationItemModel(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString().trim() ?? '',
      isMenu: json['isMenu'] == true,
      routeName: route == null || route.isEmpty ? null : route,
      children: children,
    );
  }

  static List<NavigationItemModel> listFromEnvelope(Map<String, dynamic> json) {
    final root = json['root'];
    if (root is! List) throw const FormatException('Missing navigation tree');
    return root
        .whereType<Map>()
        .map(
          (item) =>
              NavigationItemModel.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList(growable: false);
  }
}
