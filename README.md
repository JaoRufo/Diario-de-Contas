# Diário de Contas

Aplicativo Flutter para organizar despesas familiares por mês, pessoa e conta/cartão, com armazenamento local e backup manual no Firebase Firestore.

## Funcionalidades

### Lançamentos financeiros

- Seleção da competência por mês, usando as setas ou o seletor de calendário.
- Cadastro, edição e exclusão de lançamentos.
- Cada lançamento possui `id`, `person`, `account`, `amounts` e `month`.
- O campo de valores aceita parcelas separadas por espaço, barra ou vírgula.
- O total do lançamento é calculado a partir dos valores das parcelas.
- A tela inicial apresenta o total e a quantidade de lançamentos da competência selecionada, agrupados por pessoa.
- Os dados continuam disponíveis sem login e sem conexão com a internet.

### Armazenamento local

Os dados financeiros são persistidos pelo `SharedPreferences`, através de `lib/services/storage_service.dart`. A chave atual é:

```text
diario_de_contas_expenses
```

O valor da chave é uma string JSON contendo uma lista de objetos. Cada objeto mantém o formato do modelo `Expense`:

```json
[
  {
    "id": "identificador-do-lancamento",
    "person": "Pessoa",
    "account": "Conta ou cartão",
    "amounts": [120.5, 80.0],
    "month": "2026-10"
  }
]
```

O aplicativo não apaga, migra, substitui nem sincroniza automaticamente esses dados. O Firebase é uma camada adicional de autenticação e backup explícito.

### Relatórios PDF

O ícone superior de PDF oferece os relatórios da competência atual e as opções de seleção disponíveis. É possível:

- baixar o PDF do mês com todos os lançamentos;
- selecionar pessoas específicas e gerar um único PDF unificado;
- manter as contas separadas dentro do arquivo unificado, identificando cada pessoa;
- selecionar competências anteriores para gerar relatórios;
- baixar apenas as pessoas escolhidas, sem incluir as demais.

O nome do arquivo selecionado inclui a competência e as pessoas escolhidas, por exemplo:

```text
despesas-selecionadas-outubro-2026-joao.pdf
despesas-selecionadas-outubro-2026-mae-vo.pdf
```

A ação de baixar PDF foi centralizada no ícone superior. O menu de três pontos de cada pessoa mantém somente a opção **Editar**.

### Firebase e login Google

O Firebase Core é inicializado antes de `runApp` em `lib/main.dart`, usando `DefaultFirebaseOptions.currentPlatform` de `lib/firebase_options.dart`.

O menu de conta da tela principal usa `lib/services/auth_service.dart` e permite:

- entrar com a conta Google configurada no Firebase Authentication;
- visualizar nome, e-mail e foto de perfil;
- usar um avatar circular com ícone de usuário como fallback;
- sair da conta;
- disponibilizar o UID autenticado para os serviços Firebase futuros.

O login não é obrigatório para consultar ou editar os lançamentos locais.

### Backup manual no Firestore

O backup é acionado explicitamente pelo menu da conta, na opção **Fazer backup na nuvem**. Ele não é executado automaticamente.

Durante o backup, o aplicativo abre um carregamento visual modal com a mensagem **Fazendo backup na nuvem...**. Esse carregamento não pode ser fechado pelo usuário e só desaparece quando o processo termina, inclusive em caso de erro, conflito ou falha parcial.

O fluxo implementado em `lib/services/firestore_backup_service.dart` funciona assim:

1. exige uma sessão Google autenticada;
2. lê os lançamentos locais usando o `StorageService` existente;
3. grava cada lançamento em `users/{uid}/expenses/{expenseId}`;
4. usa o `id` local como ID do documento, tornando a operação idempotente;
5. verifica documentos existentes antes de gravar;
6. considera como já enviado um documento existente com os mesmos dados;
7. informa conflito quando existe o mesmo ID com conteúdo diferente, sem sobrescrever silenciosamente;
8. valida os dados após cada gravação;
9. apresenta um resumo de enviados, já existentes, conflitos e falhas;
10. preserva os dados locais em todas as situações.

Não existe sincronização bidirecional automática nesta versão. O Firestore não substitui o `SharedPreferences` e nenhuma operação de leitura ou escrita na nuvem é feita sem a ação de backup.

## Segurança do Firestore

O arquivo local `firestore.rules` restringe os lançamentos ao usuário dono do caminho:

```text
users/{uid}/expenses/{expenseId}
```

As regras exigem usuário autenticado, conferem `request.auth.uid == uid` e validam os campos `id`, `person`, `account`, `amounts` e `month`. Não há regra pública.

O `firebase.json` aponta para esse arquivo. Antes de publicar, confira no Firebase Console se existem regras remotas adicionais que precisam ser preservadas. O arquivo foi preparado para a coleção de despesas; outras coleções legítimas devem ser incorporadas conscientemente às regras antes do deploy.

## Configuração necessária

### Dependências

As dependências principais estão declaradas no `pubspec.yaml`:

- `shared_preferences`: armazenamento local;
- `intl`: moeda e datas;
- `pdf` e `printing`: geração e compartilhamento de relatórios;
- `firebase_core`: inicialização do Firebase;
- `firebase_auth`: autenticação;
- `google_sign_in`: login Google;
- `cloud_firestore`: backup manual dos lançamentos.

### Firebase Console e Android

Para o login Google funcionar em um aparelho Android:

1. habilite o provedor Google em **Firebase Console → Authentication → Sign-in method**;
2. confirme o aplicativo Android com o package `com.example.diario_de_contas`;
3. cadastre o SHA-1 correspondente ao tipo de assinatura usado;
4. baixe ou atualize `android/app/google-services.json` quando o Firebase solicitar;
5. use no aparelho uma conta permitida pelo projeto Firebase.

Para obter o SHA-1 de debug no Windows PowerShell:

```powershell
Set-Location android
.\gradlew.bat signingReport
Set-Location ..
```

Copie o SHA-1 da variante `debug` para o cadastro do app Android no Firebase Console. Para distribuição, cadastre também o SHA-1 da assinatura de release correspondente.

## Comandos de desenvolvimento

Na raiz do projeto:

```powershell
flutter pub get
flutter run
```

Verificações estáticas e compilação Android de debug:

```powershell
flutter analyze
flutter build apk --debug
```

Para publicar as regras do Firestore, com o Firebase CLI instalado e autenticado:

```powershell
firebase login
firebase use diario-de-contas-app
firebase deploy --only firestore:rules --project diario-de-contas-app
```

O comando de deploy usa a associação em `firebase.json`. Se o projeto ainda não estiver associado localmente, use `firebase use --add` e selecione `diario-de-contas-app`. Revise as regras antes do deploy quando houver regras remotas fora deste repositório.

## Como testar

### Login e logout

1. execute `flutter pub get`;
2. instale o app em um dispositivo Android configurado com o SHA-1 correto;
3. abra o menu de conta e selecione **Entrar com Google**;
4. confirme que nome, e-mail e foto aparecem no menu;
5. selecione **Sair** e confirme que o menu volta a oferecer o login;
6. confirme que os lançamentos locais continuam acessíveis sem login.

### Backup

1. faça login com Google;
2. crie ou mantenha alguns lançamentos locais;
3. abra o menu da conta e selecione **Fazer backup na nuvem**;
4. confirme o carregamento modal durante o processo;
5. aguarde a mensagem final com o resumo;
6. repita o backup e confirme que os mesmos IDs são tratados como já existentes;
7. verifique os documentos em `users/{uid}/expenses` no Firestore;
8. teste um conflito somente em ambiente controlado, sem apagar os dados locais.

O login e o backup de ponta a ponta dependem de Firebase real, rede, credenciais Google, SHA-1 e regras publicadas. `flutter analyze` e `flutter build apk --debug` verificam o código e a compilação, mas não substituem esse teste em dispositivo.

## Estrutura relevante

```text
lib/
├── main.dart
├── firebase_options.dart
├── models/expense.dart
├── providers/expenses_provider.dart
├── screens/home_screen.dart
├── screens/expense_form_screen.dart
├── services/auth_service.dart
├── services/firestore_backup_service.dart
├── services/storage_service.dart
└── utils/formatters.dart

firestore.rules
firebase.json
```

## Segurança da configuração Firebase

`lib/firebase_options.dart` e `android/app/google-services.json` são arquivos gerados pelo FlutterFire/Firebase e estão ignorados pelo Git. Eles devem existir apenas no ambiente local ou ser fornecidos pelo processo seguro de configuração do projeto.

Para configurar um clone novo, com o FlutterFire CLI autenticado:

```powershell
flutterfire configure --project=diario-de-contas-app
```

Depois, baixe o `google-services.json` do app Android no Firebase Console e salve-o em `android/app/google-services.json`.

As chaves `AIza...` são chaves client-side do Firebase, não tokens de servidor. Ainda assim, as chaves que apareceram no histórico público devem ser tratadas como comprometidas: restrinja-as por API e aplicativo no Google Cloud Console e, preferencialmente, crie novas chaves para Android, Web/Desktop e iOS. A rotação não é substituída pela remoção dos arquivos do Git.
