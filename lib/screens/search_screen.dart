import 'package:flutter/material.dart';

import '../models/city.dart';
import '../services/app_exception.dart';
import '../services/cptec_service.dart';
import '../services/storage_service.dart';
import 'forecast_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, required this.service, required this.storage});

  final CptecService service;
  final StorageService storage;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();

  List<City> _recent = [];
  List<City>? _results; // null = ainda não pesquisou
  bool _loading = false;
  String? _error;
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();
    _loadRecent();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadRecent() async {
    final recent = await widget.storage.loadRecentCities();
    if (mounted) setState(() => _recent = recent);
  }

  Future<void> _search() async {
    final query = _controller.text.trim();
    FocusScope.of(context).unfocus();
    if (query.length < 2) {
      setState(() {
        _results = null;
        _error = 'Digite pelo menos 2 letras do nome da cidade.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _lastQuery = query;
    });
    try {
      final cities = await widget.service.searchCities(query);
      if (!mounted) return;
      setState(() {
        _results = cities;
        _loading = false;
      });
    } on AppException catch (e) {
      _fail(e.message);
    } catch (_) {
      _fail('Ocorreu um erro inesperado ao pesquisar.');
    }
  }

  void _fail(String message) {
    if (!mounted) return;
    setState(() {
      _results = null;
      _error = message;
      _loading = false;
    });
  }

  Future<void> _open(City city) async {
    await widget.storage.addRecentCity(city);
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ForecastScreen(
        city: city,
        service: widget.service,
        storage: widget.storage,
      ),
    ));
    _loadRecent();
  }

  Future<void> _clearRecent() async {
    await widget.storage.clearRecentCities();
    _loadRecent();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Previsão do Tempo')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                labelText: 'Nome da cidade',
                hintText: 'Ex.: Campinas',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  tooltip: 'Pesquisar',
                  icon: const Icon(Icons.search),
                  onPressed: _loading ? null : _search,
                ),
              ),
            ),
          ),
          if (_loading) const LinearProgressIndicator(),
          Expanded(child: _content()),
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text('Fonte dos dados: CPTEC/INPE',
                style: TextStyle(fontSize: 12, color: Colors.black54)),
          ),
        ],
      ),
    );
  }

  Widget _content() {
    if (_loading && _results == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _Info(
        icon: Icons.error_outline,
        text: _error!,
        action: _lastQuery.isEmpty || _error!.startsWith('Digite')
            ? null
            : TextButton.icon(
                onPressed: _search,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
              ),
      );
    }

    final results = _results;
    if (results != null) {
      if (results.isEmpty) {
        return _Info(
          icon: Icons.search_off,
          text: 'Nenhuma cidade encontrada para “$_lastQuery”.',
        );
      }
      return ListView.separated(
        itemCount: results.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) => ListTile(
          leading: const Icon(Icons.location_city),
          title: Text(results[i].name),
          subtitle: Text(results[i].uf),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _open(results[i]),
        ),
      );
    }

    if (_recent.isEmpty) {
      return const _Info(
        icon: Icons.wb_sunny_outlined,
        text: 'Pesquise uma cidade para ver a previsão dos próximos dias.',
      );
    }

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 8, 0),
          child: Row(
            children: [
              const Expanded(
                child: Text('Consultadas recentemente',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
              TextButton(onPressed: _clearRecent, child: const Text('Limpar')),
            ],
          ),
        ),
        for (final c in _recent)
          ListTile(
            leading: const Icon(Icons.history),
            title: Text(c.name),
            subtitle: Text(c.uf),
            onTap: () => _open(c),
          ),
      ],
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.icon, required this.text, this.action});

  final IconData icon;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 56, color: Colors.black45),
              const SizedBox(height: 12),
              Text(text, textAlign: TextAlign.center),
              if (action != null) ...[const SizedBox(height: 12), action!],
            ],
          ),
        ),
      );
}
