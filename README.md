# Batalha de Ideias — Flutter + Cloud Firestore

Projeto da atividade com cadastro, listagem em tempo real, votação, exclusão e ranking da ideia mais votada. Os dados ficam na coleção `ideias`, com os campos `titulo`, `descricao`, `autor` e `votos`.

## Antes de executar

É necessário ter Flutter e Firebase configurados. O arquivo `lib/firebase_options.dart` é gerado para o seu próprio projeto Firebase; ele não pode ser compartilhado pronto porque contém a configuração específica do projeto.

### Passo a passo

1. Extraia o ZIP.
2. Instale o Flutter e verifique no terminal:
   ```bash
   flutter doctor
   ```
3. Instale o Firebase CLI e faça login:
   ```bash
   firebase login
   ```
4. Instale o FlutterFire CLI:
   ```bash
   dart pub global activate flutterfire_cli
   ```
   Se o comando `flutterfire` não for reconhecido no Windows, adicione a pasta do executável Pub Cache ao PATH ou execute pelo caminho mostrado pelo Dart.
5. No console do Firebase, crie um projeto e adicione um aplicativo. No menu **Build > Firestore Database**, crie um banco Cloud Firestore.
6. Abra o terminal dentro da pasta do projeto e execute:
   ```bash
   flutter pub get
   flutterfire configure
   ```
   Selecione seu projeto Firebase e as plataformas que deseja usar. Esse comando gera `lib/firebase_options.dart`.
7. No Firebase Console, abra **Firestore Database > Rules** e configure regras apropriadas para o seu ambiente. Para teste escolar, pode-se usar o modo de teste temporariamente, mas não publique regras abertas em produção. Sem autenticação, regras seguras exigem que você implemente login antes de permitir leitura/escrita.
8. Execute no navegador:
   ```bash
   flutter run -d chrome
   ```
   Ou execute em um dispositivo configurado.
9. Teste em dois navegadores/dispositivos conectados ao mesmo projeto Firebase: cadastre uma ideia em um e confirme que aparece no outro; vote no segundo e confirme que o contador atualiza no primeiro.

## Funcionalidades implementadas

- Cadastro de título, descrição e autor; toda ideia começa com `votos: 0`.
- Atualização em tempo real usando `snapshots()` do Firestore.
- Votação com `FieldValue.increment(1)`.
- Exclusão do documento correspondente.
- Ranking automático da ideia com mais votos.
- Interface responsiva para uso em navegador e dispositivos.

## Observação importante

O ZIP contém o código-fonte pronto, mas não é possível conectar a um Firebase sem as credenciais/configuração do seu próprio projeto. O passo `flutterfire configure` é obrigatório antes de executar.
