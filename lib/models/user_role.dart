enum UserRole {
  superAdmin(level: 3),
  manager(level: 2),
  cashier(level: 1);

  final int level;
  const UserRole({required this.level});

  bool hasPermission(UserRole requiredRole) => level >= requiredRole.level;
}
