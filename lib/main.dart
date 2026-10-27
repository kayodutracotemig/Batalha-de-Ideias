import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const BatalhaDeIdeiasApp());
}

class BatalhaDeIdeiasApp extends StatelessWidget {
  const BatalhaDeIdeiasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Batalha de Ideias',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const IdeiasPage(),
    );
  }
}

class IdeiasPage extends StatefulWidget {
  const IdeiasPage({super.key});

  @override
  State<IdeiasPage> createState() => _IdeiasPageState();
}

class _IdeiasPageState extends State<IdeiasPage> {
  final _titulo = TextEditingController();
  final _descricao = TextEditingController();
  final _autor = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final CollectionReference<Map<String, dynamic>> _ideias =
      FirebaseFirestore.instance.collection('ideias');
  bool _salvando = false;

  @override
  void dispose() {
    _titulo.dispose();
    _descricao.dispose();
    _autor.dispose();
    super.dispose();
  }

  Future<void> _cadastrar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _salvando = true);
    try {
      await _ideias.add({
        'titulo': _titulo.text.trim(),
        'descricao': _descricao.text.trim(),
        'autor': _autor.text.trim(),
        'votos': 0,
        'criadoEm': FieldValue.serverTimestamp(),
      });
      _titulo.clear();
      _descricao.clear();
      _autor.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ideia cadastrada com sucesso!')),
        );
      }
    } catch (e) {
      _mensagem('Não foi possível cadastrar. Confira a configuração do Firebase.');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _votar(String id) async {
    try {
      await _ideias.doc(id).update({'votos': FieldValue.increment(1)});
    } catch (_) {
      _mensagem('Não foi possível registrar o voto.');
    }
  }

  Future<void> _excluir(String id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir ideia?'),
        content: const Text('Esta ação removerá a ideia do banco de dados para todos os usuários.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Excluir')),
        ],
      ),
    );
    if (confirmar != true) return;
    try {
      await _ideias.doc(id).delete();
    } catch (_) {
      _mensagem('Não foi possível excluir a ideia.');
    }
  }

  void _mensagem(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  int _votos(Map<String, dynamic> data) {
    final value = data['votos'];
    return value is int ? value : (value as num?)?.toInt() ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('💡 Batalha de Ideias'),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _ideias.snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Erro ao carregar ideias. Verifique a conexão e as regras do Firestore.'),
                  ),
                );
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data?.docs.toList() ?? [];
              docs.sort((a, b) {
                final byVotes = _votos(b.data()).compareTo(_votos(a.data()));
                if (byVotes != 0) return byVotes;
                final at = a.data()['criadoEm'];
                final bt = b.data()['criadoEm'];
                if (at is Timestamp && bt is Timestamp) return bt.compareTo(at);
                return 0;
              });

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _formulario(),
                  const SizedBox(height: 20),
                  if (docs.isNotEmpty) _ranking(docs.first.data()),
                  const SizedBox(height: 12),
                  Text('Ideias cadastradas (${docs.length})',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  if (docs.isEmpty)
                    const Card(child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('Ainda não há ideias. Cadastre a primeira!'),
                    )),
                  ...docs.map((doc) {
                    final data = doc.data();
                    final titulo = (data['titulo'] ?? 'Sem título').toString();
                    final descricao = (data['descricao'] ?? '').toString();
                    final autor = (data['autor'] ?? 'Anônimo').toString();
                    final votos = _votos(data);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(titulo, style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 6),
                            Text(descricao),
                            const SizedBox(height: 10),
                            Text('Autor: $autor', style: const TextStyle(color: Colors.black54)),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Chip(avatar: const Icon(Icons.favorite, size: 18), label: Text('$votos votos')),
                                const Spacer(),
                                OutlinedButton.icon(
                                  onPressed: () => _votar(doc.id),
                                  icon: const Icon(Icons.how_to_vote),
                                  label: const Text('VOTAR'),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  tooltip: 'Excluir ideia',
                                  onPressed: () => _excluir(doc.id),
                                  icon: const Icon(Icons.delete_outline),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _formulario() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Cadastrar nova ideia', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titulo,
                decoration: const InputDecoration(labelText: 'Título', border: OutlineInputBorder()),
                validator: (v) => v == null || v.trim().isEmpty ? 'Informe o título.' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _descricao,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Descrição', border: OutlineInputBorder()),
                validator: (v) => v == null || v.trim().isEmpty ? 'Informe a descrição.' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _autor,
                decoration: const InputDecoration(labelText: 'Nome do autor', border: OutlineInputBorder()),
                validator: (v) => v == null || v.trim().isEmpty ? 'Informe o nome do autor.' : null,
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _salvando ? null : _cadastrar,
                icon: _salvando
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.add),
                label: Text(_salvando ? 'Salvando...' : 'Cadastrar ideia'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ranking(Map<String, dynamic> data) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: ListTile(
        leading: const Icon(Icons.emoji_events, size: 36),
        title: const Text('IDEIA MAIS VOTADA'),
        subtitle: Text((data['titulo'] ?? 'Sem título').toString()),
        trailing: Text('${_votos(data)} votos',
            style: Theme.of(context).textTheme.titleMedium),
      ),
    );
  }
}
