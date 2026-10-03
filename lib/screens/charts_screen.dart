import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../theme/app_locale.dart';
import '../theme/app_colors.dart';

class ChartsScreen extends StatefulWidget {
  const ChartsScreen({super.key});

  @override
  State<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends State<ChartsScreen> {
  // Quelques raccourcis pratiques, mais on peut chercher N'IMPORTE QUEL
  // actif proposé par TradingView via le champ de recherche ci-dessous.
  static const List<Map<String, String>> _shortcuts = [
    {'label': 'XAUUSD', 'tv': 'OANDA:XAUUSD'},
    {'label': 'US30', 'tv': 'OANDA:US30USD'},
    {'label': 'NAS100', 'tv': 'OANDA:NAS100USD'},
    {'label': 'EURUSD', 'tv': 'OANDA:EURUSD'},
    {'label': 'GBPUSD', 'tv': 'OANDA:GBPUSD'},
    {'label': 'BTCUSD', 'tv': 'COINBASE:BTCUSD'},
    {'label': 'AAPL', 'tv': 'NASDAQ:AAPL'},
  ];

  late String _currentTvSymbol;
  final TextEditingController _searchController = TextEditingController();
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _currentTvSymbol = _shortcuts.first['tv']!;
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0B0E14));
    _loadChart();
  }

  void _loadChart() {
    _controller.loadHtmlString(_buildHtml(_currentTvSymbol));
  }

  void _searchSymbol(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    setState(() => _currentTvSymbol = trimmed.toUpperCase());
    _loadChart();
  }

  String _buildHtml(String tvSymbol) {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    html, body { margin:0; padding:0; height:100%; background:#0B0E14; }
    .tradingview-widget-container { height:100%; width:100%; }
  </style>
</head>
<body>
  <div class="tradingview-widget-container">
    <div id="tv_chart" style="height:100%;width:100%;"></div>
  </div>
  <script src="https://s3.tradingview.com/tv.js"></script>
  <script>
    new TradingView.widget({
      "autosize": true,
      "symbol": "$tvSymbol",
      "interval": "15",
      "timezone": "Etc/UTC",
      "theme": "dark",
      "style": "1",
      "locale": "fr",
      "toolbar_bg": "#0B0E14",
      "enable_publishing": false,
      "hide_top_toolbar": false,
      "hide_legend": false,
      "container_id": "tv_chart"
    });
  </script>
</body>
</html>
''';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppLocale.instance,
      builder: (context, _) {
        final t = AppStrings.t;
        return Scaffold(
          backgroundColor: AppColors.bg,
          appBar: AppBar(
            backgroundColor: AppColors.bg,
            elevation: 0,
            foregroundColor: AppColors.textPrimary,
            title: Text(t('charts')),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Rechercher un actif (ex: TSLA, BTCUSD, NASDAQ:MSFT)',
                    hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                    prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.card,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  ),
                  onSubmitted: _searchSymbol,
                ),
              ),
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _shortcuts.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final symbol = _shortcuts[index];
                    final isSelected = _currentTvSymbol == symbol['tv'];
                    return ChoiceChip(
                      label: Text(symbol['label']!),
                      selected: isSelected,
                      onSelected: (_) {
                        setState(() => _currentTvSymbol = symbol['tv']!);
                        _searchController.clear();
                        _loadChart();
                      },
                      selectedColor: const Color(0xFF534AB7),
                      backgroundColor: AppColors.card,
                      labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.textSecondary),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Expanded(child: WebViewWidget(controller: _controller)),
            ],
          ),
        );
      },
    );
  }
}
