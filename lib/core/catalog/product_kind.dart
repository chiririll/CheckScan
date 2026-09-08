enum ProductKind {
  good,
  service;

  static ProductKind parse(String? raw) => raw == service.name ? service : good;
}
