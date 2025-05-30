import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../providers/theme_provider.dart';
import '../providers/language_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/auth_provider.dart';
import 'package:http/http.dart' as http;
import '../widgets/user_avatar_button.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ScrollController _scrollController = ScrollController();
  Timer? _timer;
  Timer? _scrollTimer;
  double _scrollPosition = 0;

  // Piyasa verileri
  List<Map<String, dynamic>> _marketData = [];
  Map<String, double> _lastPrices = {};
  Map<String, Color?> _flashColors = {};
  bool _isMarketLoading = true;
  String? _marketError;

  // Haberler
  List<Map<String, dynamic>> _news = [];
  bool _isNewsLoading = true;
  String? _newsError;

  final List<String> _popularSymbols = [
    'BTCUSDT', 'ETHUSDT', 'BNBUSDT', 'XRPUSDT', 'ADAUSDT', 'SOLUSDT'
  ];

  final Map<String, String> _coinIcons = {
    'BTCUSDT': 'https://cryptologos.cc/logos/bitcoin-btc-logo.png',
    'ETHUSDT': 'https://cryptologos.cc/logos/ethereum-eth-logo.png',
    'BNBUSDT': 'https://cryptologos.cc/logos/binance-coin-bnb-logo.png',
    'XRPUSDT': 'https://cryptologos.cc/logos/xrp-xrp-logo.png',
    'ADAUSDT': 'https://cryptologos.cc/logos/cardano-ada-logo.png',
    'SOLUSDT': 'https://cryptologos.cc/logos/solana-sol-logo.png',
  };

  final Map<String, String> _coinNames = {
    'BTCUSDT': 'Bitcoin',
    'ETHUSDT': 'Ethereum',
    'BNBUSDT': 'Binance Coin',
    'XRPUSDT': 'XRP',
    'ADAUSDT': 'Cardano',
    'SOLUSDT': 'Solana',
  };

  final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

  bool _firstMarketLoad = true;

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
    _fetchMarketData();
    _fetchNews();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _fetchMarketData());
  }

  Future<void> _fetchMarketData() async {
    if (_firstMarketLoad) setState(() { _isMarketLoading = true; });
    try {
      final response = await http.get(Uri.parse('https://api.binance.com/api/v3/ticker/24hr'));
      if (response.statusCode == 200) {
        final List<dynamic> allData = json.decode(response.body);
        final filtered = allData.where((item) => _popularSymbols.contains(item['symbol'])).toList();
        filtered.sort((a, b) => double.parse(b['priceChangePercent']).compareTo(double.parse(a['priceChangePercent'])));
        final newMarketData = filtered.map((item) => {
          'symbol': item['symbol'],
          'name': _coinNames[item['symbol']] ?? item['symbol'],
          'price': double.tryParse(item['lastPrice'] ?? '0') ?? 0.0,
          'priceChange': double.tryParse(item['priceChangePercent'] ?? '0') ?? 0.0,
          'icon': _coinIcons[item['symbol']] ?? '',
        }).toList();
        // Fiyat değişimi animasyonu için kontrol
        for (final coin in newMarketData) {
          final symbol = coin['symbol'];
          final newPrice = coin['price'];
          final lastPrice = _lastPrices[symbol];
          if (lastPrice != null && newPrice != lastPrice) {
            _flashColors[symbol] = newPrice > lastPrice ? Colors.green : Colors.red;
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) setState(() => _flashColors[symbol] = null);
            });
          }
          _lastPrices[symbol] = newPrice;
        }
        setState(() {
          _marketData = newMarketData;
          _isMarketLoading = false;
          _firstMarketLoad = false;
        });
      } else {
        setState(() {
          _marketError = 'Piyasa verileri alınamadı (HTTP ${response.statusCode})';
          _isMarketLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _marketError = 'Piyasa verileri alınırken hata oluştu: $e';
        _isMarketLoading = false;
      });
    }
  }

  Future<void> _fetchNews() async {
    setState(() {
      _isNewsLoading = true;
      _newsError = null;
    });
    try {
      final response = await http.get(Uri.parse('https://min-api.cryptocompare.com/data/v2/news/?lang=TR'));
      if (response.statusCode == 200) {
        final List<dynamic> newsList = json.decode(response.body)['Data'];
        setState(() {
          _news = newsList.map((item) => {
            'title': item['title'],
            'source': item['source'],
            'time': DateFormat('yyyy-MM-dd').format(DateTime.fromMillisecondsSinceEpoch(item['published_on'] * 1000)),
            'image': item['imageurl'],
            'url': item['url'],
          }).toList();
          _isNewsLoading = false;
        });
      } else {
        setState(() {
          _newsError = 'Haberler alınamadı (HTTP ${response.statusCode})';
          _isNewsLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _newsError = 'Haberler alınırken hata oluştu: $e';
        _isNewsLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _scrollTimer?.cancel();
    _scrollTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_scrollController.hasClients) {
        if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        } else {
          _scrollController.animateTo(
            _scrollController.position.pixels + 100,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: themeProvider.isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: themeProvider.isDarkMode ? const Color(0xFF111111) : Colors.white,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: themeProvider.isDarkMode ? const Color(0xFFFFD700) : Colors.black),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: AssetImage('assets/images/logo.jpg'),
              radius: 20,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'QuantumTrade',
                  style: TextStyle(
                    color: themeProvider.isDarkMode ? const Color(0xFFFFD700) : Colors.black,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '"The world is yours"',
                  style: TextStyle(
                    fontSize: 12,
                    color: themeProvider.isDarkMode ? Colors.grey : Colors.black54,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.notifications, color: themeProvider.isDarkMode ? const Color(0xFFFFD700) : Colors.black),
                onPressed: () {
                  Navigator.pushNamed(context, '/notifications');
                },
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Provider.of<NotificationProvider>(context).hasUnreadNotifications ? Colors.red : Colors.grey,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    Provider.of<NotificationProvider>(context).hasUnreadNotifications ? '!' : '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
          UserAvatarButton(),
        ],
      ),
      drawer: Drawer(
        backgroundColor: themeProvider.isDarkMode ? const Color(0xFF111111) : Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: themeProvider.isDarkMode ? const Color(0xFF111111) : Colors.white,
                border: Border(bottom: BorderSide(color: themeProvider.isDarkMode ? const Color(0xFFFFD700) : Colors.black)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundImage: AssetImage('assets/images/logo.jpg'),
                    radius: 30,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'QuantumTrade',
                    style: TextStyle(
                      color: themeProvider.isDarkMode ? const Color(0xFFFFD700) : Colors.black,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '"The world is yours"',
                    style: TextStyle(
                      fontSize: 14,
                      color: themeProvider.isDarkMode ? Colors.grey : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.home, color: themeProvider.isDarkMode ? const Color(0xFFFFD700) : Colors.black),
              title: Text(languageProvider.getText('Ana Sayfa'), style: TextStyle(color: themeProvider.isDarkMode ? Colors.white : Colors.black)),
              selected: true,
              selectedTileColor: themeProvider.isDarkMode ? const Color(0xFF222222) : Colors.grey[200],
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.show_chart, color: themeProvider.isDarkMode ? const Color(0xFFFFD700) : Colors.black),
              title: Text(languageProvider.getText('Piyasa'), style: TextStyle(color: themeProvider.isDarkMode ? Colors.white : Colors.black)),
              selected: false,
              selectedTileColor: themeProvider.isDarkMode ? const Color(0xFF222222) : Colors.grey[200],
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/piyasa');
              },
            ),
            ListTile(
              leading: Icon(Icons.person, color: themeProvider.isDarkMode ? const Color(0xFFFFD700) : Colors.black),
              title: Text(languageProvider.getText('Profilim'), style: TextStyle(color: themeProvider.isDarkMode ? Colors.white : Colors.black)),
              selected: false,
              selectedTileColor: themeProvider.isDarkMode ? const Color(0xFF222222) : Colors.grey[200],
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/profilim');
              },
            ),
            ListTile(
              leading: Icon(Icons.smart_toy, color: themeProvider.isDarkMode ? const Color(0xFFFFD700) : Colors.black),
              title: Text('AI Asistan', style: TextStyle(color: themeProvider.isDarkMode ? Colors.white : Colors.black)),
              selected: false,
              selectedTileColor: themeProvider.isDarkMode ? const Color(0xFF222222) : Colors.grey[200],
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/ai-asistan');
              },
            ),
            Divider(color: themeProvider.isDarkMode ? const Color(0xFF444444) : Colors.grey),
            ListTile(
              leading: Icon(Icons.login, color: themeProvider.isDarkMode ? const Color(0xFFFFD700) : Colors.black),
              title: Text(languageProvider.getText('Kullanıcı Girişi'), style: TextStyle(color: themeProvider.isDarkMode ? Colors.white : Colors.black)),
              selected: false,
              selectedTileColor: themeProvider.isDarkMode ? const Color(0xFF222222) : Colors.grey[200],
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
            ListTile(
              leading: Icon(Icons.settings, color: themeProvider.isDarkMode ? const Color(0xFFFFD700) : Colors.black),
              title: Text(languageProvider.getText('Ayarlar'), style: TextStyle(color: themeProvider.isDarkMode ? Colors.white : Colors.black)),
              selected: false,
              selectedTileColor: themeProvider.isDarkMode ? const Color(0xFF222222) : Colors.grey[200],
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/ayarlar');
              },
            ),
            ListTile(
              leading: Icon(Icons.help, color: themeProvider.isDarkMode ? const Color(0xFFFFD700) : Colors.black),
              title: Text(languageProvider.getText('Yardım'), style: TextStyle(color: themeProvider.isDarkMode ? Colors.white : Colors.black)),
              selected: false,
              selectedTileColor: themeProvider.isDarkMode ? const Color(0xFF222222) : Colors.grey[200],
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/yardim');
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Orijinal Slogan Bölümü
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: themeProvider.isDarkMode
                    ? [const Color(0xFF111111), const Color(0xFF222222)]
                    : [Colors.white, Colors.grey[100]!],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'HOŞ GELDİN GELECEĞİN MİLYONERİ', // Yeni üst slogan metni
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: themeProvider.isDarkMode ? const Color(0xFFFFD700) : Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'QUANTUMTRADE İLE DÜNYANIN İÇİNDEKİLERİNE SAHİP OLANLARIN ARASINA SEN DE KATIL', // Yeni alt slogan metni
                      style: TextStyle(
                        fontSize: 16,
                        color: themeProvider.isDarkMode ? Colors.grey : Colors.black54,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            // Kayan Haber
            Container(
              color: themeProvider.isDarkMode ? const Color(0xFF111111) : Colors.grey[100],
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: SingleChildScrollView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _news.take(3).map((news) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Icon(Icons.newspaper, color: themeProvider.isDarkMode ? const Color(0xFFFFD700) : Colors.black),
                        const SizedBox(width: 8),
                        Text(
                          news['title'] ?? '',
                          style: TextStyle(color: themeProvider.isDarkMode ? Colors.white : Colors.black),
                        ),
                      ],
                    ),
                  )).toList(),
                ),
              ),
            ),
            // Anlık Piyasa Verileri
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Anlık Piyasa Verileri',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_isMarketLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (_marketError != null)
                    Text(_marketError!, style: TextStyle(color: Colors.red))
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 2.3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: _marketData.length,
                      itemBuilder: (context, index) {
                        final coin = _marketData[index];
                        final priceChange = coin['priceChange'] ?? 0.0;
                        final isPositive = priceChange >= 0;
                        final symbol = coin['symbol'];
                        final flashColor = _flashColors[symbol];
                        final borderColor = flashColor ?? (isPositive ? Colors.green : Colors.red);
                        final bgColor = themeProvider.isDarkMode ? const Color(0xFF181818) : Colors.grey[100];
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          decoration: BoxDecoration(
                            color: bgColor,
                            border: Border.all(color: borderColor, width: 3),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: borderColor.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    coin['symbol'].replaceAll('USDT', ''),
                                    style: TextStyle(
                                      color: Colors.yellow[700],
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      fontFamily: 'Orbitron',
                                    ),
                                  ),
                                  Text(
                                    currencyFormat.format(coin['price'] ?? 0.0),
                                    style: TextStyle(
                                      color: Colors.yellow[700],
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      fontFamily: 'Orbitron',
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '${isPositive ? '+' : ''}${priceChange.toStringAsFixed(2)}%',
                                style: TextStyle(
                                  color: isPositive ? Colors.greenAccent : Colors.redAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  fontFamily: 'Orbitron',
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
            // Haberler Bölümü
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kripto Haberleri',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_isNewsLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (_newsError != null)
                    Text(_newsError!, style: TextStyle(color: Colors.red))
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _news.length,
                      itemBuilder: (context, index) {
                        final news = _news[index];
                        return Card(
                          color: themeProvider.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: news['image'] != null && news['image'].toString().isNotEmpty
                                ? Image.network(news['image'], width: 48, height: 48, fit: BoxFit.cover)
                                : Icon(Icons.newspaper, size: 48, color: themeProvider.isDarkMode ? Colors.white : Colors.black),
                            title: Text(
                              news['title'] ?? '',
                              style: TextStyle(
                                color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Text(
                                      news['source'] ?? '',
                                      style: TextStyle(
                                        color: themeProvider.isDarkMode ? Colors.grey : Colors.black54,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      news['time'] ?? '',
                                      style: TextStyle(
                                        color: themeProvider.isDarkMode ? Colors.grey : Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            onTap: () {
                              if (news['url'] != null) {
                                // url_launcher ile haber detayına gidilebilir
                              }
                            },
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: themeProvider.isDarkMode ? const Color(0xFF111111) : Colors.white,
          border: Border(top: BorderSide(color: themeProvider.isDarkMode ? const Color(0xFFFFD700) : Colors.black)),
        ),
        child: Text(
          "© 2025 QuantumTrade • Tüm Hakları Saklıdır",
          textAlign: TextAlign.center,
          style: TextStyle(color: themeProvider.isDarkMode ? Colors.grey : Colors.black54),
        ),
      ),
    );
  }
} 