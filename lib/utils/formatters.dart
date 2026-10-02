const _monthNames = <String>[
  'janeiro',
  'fevereiro',
  'março',
  'abril',
  'maio',
  'junho',
  'julho',
  'agosto',
  'setembro',
  'outubro',
  'novembro',
  'dezembro',
];

String money(double value) {
  final signal = value < 0 ? '-' : '';
  final fixed = value.abs().toStringAsFixed(2).split('.');
  final integer = fixed[0].replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => '.',
  );
  return 'R\$ $signal$integer,${fixed[1]}';
}

String monthLabel(DateTime value) {
  final month = _monthNames[value.month - 1];
  return '${month[0].toUpperCase()}${month.substring(1)} ${value.year}';
}
