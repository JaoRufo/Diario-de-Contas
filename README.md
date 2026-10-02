# Diário de Contas

Aplicativo Flutter para organizar despesas familiares por competência, pessoa e banco/cartão.

## Estrutura

```text
lib/
├── main.dart
├── models/expense.dart
├── providers/expenses_provider.dart
├── services/storage_service.dart
├── screens/home_screen.dart
├── screens/expense_form_screen.dart
└── utils/formatters.dart
```

## Executar

```bash
flutter pub get
flutter run
```

Dependências principais: `shared_preferences` para persistência local e `intl` para moeda/data em pt-BR.

Na tela inicial, use as setas ou toque no mês para trocar a competência. O formulário aceita valores separados por espaço, barra ou vírgula; os lançamentos ficam salvos localmente ao tocar em **Salvar lançamento**.
