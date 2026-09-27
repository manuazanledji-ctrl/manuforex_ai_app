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
  static const List<Map<String, String>> _symbols = [
    {'label': 'XAUUSD', 'tv': 'OANDA:XAUUSD'},
    {'label': 'US30', 'tv': 'OANDA:US30USD'},
    {'label': 'NAS100', 'tv': 'OANDA:NAS100USD'},
    {'label': 'EURUSD', 'tv': 'OANDA:EURUSD'},
    {'label': 'GBPUSD', 'tv': 'OANDA:GBPUSD'},
  ];

  late String _selectedTvSymbol;
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _selectedTvSymbol = _symbols.first['tv']!;
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0B0E14));
    _loadChart();
  }

  void _loadChart() {
    _controller.loadHtmlString(_buildHtml(_selectedTvSymbol));
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
              SizedBox(
                height: 52,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: _symbols.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final symbol = _symbols[index];
                    final isSelected = _selectedTvSymbol == symbol['tv'];
                    return ChoiceChip(
                      label: Text(symbol['label']!),
                      selected: isSelected,
                      onSelected: (_) {
                        setState(() => _selectedTvSymbol = symbol['tv']!);
                        _loadChart();
                      },
                      selectedColor: const Color(0xFF534AB7),
                      backgroundColor: AppColors.card,
                      labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.textSecondary),
                    );
                  },
                ),
              ),
              Expanded(child: WebViewWidget(controller: _controller)),
            ],
          ),
        );
      },
    );
  }
}
