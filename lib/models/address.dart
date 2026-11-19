/// Dirección postal resultado de la geocodificación inversa.
class Address {
  const Address({
    required this.street,
    required this.colonia,
    required this.city,
    required this.state,
    required this.postalCode,
  });

  final String street;
  final String colonia;
  final String city;
  final String state;
  final String postalCode;

  /// Línea principal: la calle (o un texto de respaldo).
  String get line1 => street.isNotEmpty ? street : 'Calle sin nombre';

  /// Línea secundaria: colonia y ciudad.
  String get line2 =>
      [colonia, city].where((e) => e.isNotEmpty).join(', ');

  /// Ciudad, estado y código postal.
  String get region => [
        city,
        state,
        if (postalCode.isNotEmpty) 'C.P. $postalCode',
      ].where((e) => e.isNotEmpty).join(' · ');
}
