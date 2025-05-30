import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../providers/theme_provider.dart';
import '../providers/language_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/user_avatar_button.dart';
import 'dart:async';

class PiyasaPage extends StatefulWidget {
  const PiyasaPage({Key? key}) : super(key: key);

  @override
  State<PiyasaPage> createState() => _PiyasaPageState();
}

class _PiyasaPageState extends State<PiyasaPage> {
  late final WebViewController _controller;
  bool _isAnalyzing = false;
  final List<String> _analysisParts = [];
  final List<String> _currentTypingTexts = [];
  Timer? _typingTimer;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse('https://www.tradingview.com/chart/?symbol=BINANCE:BTCUSDT'));
    _startAIAnalysis();
    
    // Her dakika analizi güncelle
    Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        _startAIAnalysis();
      }
    });
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    super.dispose();
  }

  void _startAIAnalysis() {
    setState(() {
      _isAnalyzing = true;
      _analysisParts.clear();
      _currentTypingTexts.clear();
      _isTyping = false;
    });

    // Binance API'den veri al
    http.get(Uri.parse('https://api.binance.com/api/v3/klines?symbol=BTCUSDT&interval=1h&limit=100'))
      .then((response) {
        if (response.statusCode == 200) {
          final data = json.decode(response.body) as List;
          // Kapanış fiyatlarını al
          final closes = data.map<double>((candle) => double.parse(candle[4].toString())).toList();
          
          // RSI hesapla
          final rsi = _calculateRSI(closes);
          final currentRSI = rsi[rsi.length - 1];
          
          // MACD hesapla
          final macd = _calculateMACD(closes);
          final macdLine = macd['macdLine'] as List<double>;
          final signalLine = macd['signalLine'] as List<double>;
          final histogram = macd['histogram'] as List<double>;
          
          final currentMACD = macdLine.last;
          final currentSignal = signalLine.last;
          final currentHistogram = histogram.last;

          // Analiz parçalarını güncelle
          _analysisParts.clear();
          _analysisParts.addAll([
            'RSI Analizi: ${_getRSIAnalysis(currentRSI)}',
            'MACD Analizi: ${_getMACDAnalysis(currentMACD, currentSignal, currentHistogram)}',
            'Genel Trend Analizi: ${_getTrendAnalysis(currentRSI, currentMACD, currentSignal)}',
            'Yatırım Tavsiyesi: ${_getInvestmentAdvice(currentRSI, currentMACD, currentSignal)}'
          ]);

          // Her satır için boş string başlat
          _currentTypingTexts.clear();
          _currentTypingTexts.addAll(List.filled(_analysisParts.length, ''));

          _startTyping();
        } else {
          throw Exception('Veri alınamadı: ${response.statusCode}');
        }
      })
      .catchError((error) {
        print('Veri çekme hatası: $error');
        setState(() {
          _isAnalyzing = false;
        });
      });
  }

  List<double> _calculateRSI(List<double> prices, {int period = 14}) {
    List<double> gains = [];
    List<double> losses = [];
    List<double> rsi = [];

    // İlk fiyat değişimlerini hesapla
    for (int i = 1; i < prices.length; i++) {
      double change = prices[i] - prices[i - 1];
      gains.add(change > 0 ? change : 0);
      losses.add(change < 0 ? -change : 0);
    }

    // İlk RSI değerini hesapla
    double avgGain = gains.sublist(0, period).reduce((a, b) => a + b) / period;
    double avgLoss = losses.sublist(0, period).reduce((a, b) => a + b) / period;
    double rs = avgGain / avgLoss;
    rsi.add(100 - (100 / (1 + rs)));

    // Kalan RSI değerlerini hesapla
    for (int i = period; i < gains.length; i++) {
      avgGain = ((avgGain * (period - 1)) + gains[i]) / period;
      avgLoss = ((avgLoss * (period - 1)) + losses[i]) / period;
      rs = avgGain / avgLoss;
      rsi.add(100 - (100 / (1 + rs)));
    }

    return rsi;
  }

  Map<String, List<double>> _calculateMACD(List<double> prices, {int fastPeriod = 12, int slowPeriod = 26, int signalPeriod = 9}) {
    List<double> ema12 = _calculateEMA(prices, fastPeriod);
    List<double> ema26 = _calculateEMA(prices, slowPeriod);
    List<double> macdLine = [];
    List<double> signalLine = [];
    List<double> histogram = [];

    // MACD çizgisini hesapla
    for (int i = 0; i < ema12.length; i++) {
      macdLine.add(ema12[i] - ema26[i]);
    }

    // Sinyal çizgisini hesapla
    signalLine = _calculateEMA(macdLine, signalPeriod);

    // Histogramı hesapla
    for (int i = 0; i < macdLine.length; i++) {
      histogram.add(macdLine[i] - signalLine[i]);
    }

    return {
      'macdLine': macdLine,
      'signalLine': signalLine,
      'histogram': histogram
    };
  }

  List<double> _calculateEMA(List<double> prices, int period) {
    double k = 2 / (period + 1);
    List<double> ema = [prices[0]];

    for (int i = 1; i < prices.length; i++) {
      ema.add(prices[i] * k + ema[i - 1] * (1 - k));
    }

    return ema;
  }

  String _getRSIAnalysis(double rsi) {
    if (rsi > 70) return "Aşırı alım bölgesinde (RSI: ${rsi.toStringAsFixed(2)}). Satış fırsatı oluşabilir.";
    if (rsi < 30) return "Aşırı satım bölgesinde (RSI: ${rsi.toStringAsFixed(2)}). Alım fırsatı oluşabilir.";
    if (rsi > 50) return "Yükseliş trendinde (RSI: ${rsi.toStringAsFixed(2)}). Momentum güçlü.";
    return "Düşüş trendinde (RSI: ${rsi.toStringAsFixed(2)}). Momentum zayıf.";
  }

  String _getMACDAnalysis(double macd, double signal, double histogram) {
    if (macd > signal && histogram > 0) {
      return "MACD sinyal çizgisinin üzerinde ve histogram pozitif. Yükseliş trendi güçlü.";
    } else if (macd < signal && histogram < 0) {
      return "MACD sinyal çizgisinin altında ve histogram negatif. Düşüş trendi güçlü.";
    } else if (macd > signal && histogram < 0) {
      return "MACD sinyal çizgisinin üzerinde ancak histogram negatif. Trend zayıflıyor.";
    } else {
      return "MACD sinyal çizgisinin altında ancak histogram pozitif. Trend güçleniyor.";
    }
  }

  String _getTrendAnalysis(double rsi, double macd, double signal) {
    if (rsi > 50 && macd > signal) {
      return "Güçlü yükseliş trendi. RSI ve MACD yükselişi destekliyor.";
    } else if (rsi < 50 && macd < signal) {
      return "Güçlü düşüş trendi. RSI ve MACD düşüşü destekliyor.";
    } else if (rsi > 50 && macd < signal) {
      return "Trend zayıflıyor. RSI yükselişi gösterirken MACD düşüş sinyali veriyor.";
    } else {
      return "Trend güçleniyor. RSI düşüşü gösterirken MACD yükseliş sinyali veriyor.";
    }
  }

  String _getInvestmentAdvice(double rsi, double macd, double signal) {
    if (rsi > 70 && macd < signal) {
      return "GÜÇLÜ SATIM - Aşırı alım bölgesi ve MACD düşüş sinyali.";
    } else if (rsi < 30 && macd > signal) {
      return "GÜÇLÜ ALIM - Aşırı satım bölgesi ve MACD yükseliş sinyali.";
    } else if (rsi > 60 && macd > signal) {
      return "SATIM - Yükseliş trendi zayıflıyor.";
    } else if (rsi < 40 && macd < signal) {
      return "ALIM - Düşüş trendi zayıflıyor.";
    } else {
      return "BEKLE - Trend belirsiz, daha net sinyaller bekleyin.";
    }
  }

  void _startTyping() {
    setState(() {
      _isTyping = true;
    });

    List<int> charIndices = List.filled(_analysisParts.length, 0);
    bool allComplete = false;

    _typingTimer?.cancel();
    _typingTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (allComplete) {
        timer.cancel();
        setState(() {
          _isTyping = false;
          _isAnalyzing = false;
        });
        return;
      }

      setState(() {
        allComplete = true;
        for (int i = 0; i < _analysisParts.length; i++) {
          if (charIndices[i] < _analysisParts[i].length) {
            _currentTypingTexts[i] += _analysisParts[i][charIndices[i]];
            charIndices[i]++;
            allComplete = false;
          }
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    // Kullanıcı giriş yapmamışsa login sayfasına yönlendir
    if (!authProvider.isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: themeProvider.isDarkMode ? const Color(0xFF111111) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: themeProvider.isDarkMode ? const Color(0xFFFFD700) : Colors.black,
                  width: 2,
                ),
              ),
              title: Row(
                children: [
                  Icon(
                    Icons.lock,
                    color: themeProvider.isDarkMode ? const Color(0xFFFFD700) : Colors.black,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Giriş Gerekli',
                    style: TextStyle(
                      color: themeProvider.isDarkMode ? const Color(0xFFFFD700) : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: Text(
                'Bu sayfayı görüntülemek için lütfen giriş yapın.',
                style: TextStyle(
                  color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                  child: Text(
                    'Giriş Yap',
                    style: TextStyle(
                      color: themeProvider.isDarkMode ? const Color(0xFFFFD700) : Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      });
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
          ),
        ),
      );
    }

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
          UserAvatarButton(),
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
              selected: false,
              selectedTileColor: themeProvider.isDarkMode ? const Color(0xFF222222) : Colors.grey[200],
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/');
              },
            ),
            ListTile(
              leading: Icon(Icons.show_chart, color: themeProvider.isDarkMode ? const Color(0xFFFFD700) : Colors.black),
              title: Text(languageProvider.getText('Piyasa'), style: TextStyle(color: themeProvider.isDarkMode ? Colors.white : Colors.black)),
              selected: true,
              selectedTileColor: themeProvider.isDarkMode ? const Color(0xFF222222) : Colors.grey[200],
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.person, color: themeProvider.isDarkMode ? const Color(0xFFFFD700) : Colors.black),
              title: Text(languageProvider.getText('Profilim'), style: TextStyle(color: themeProvider.isDarkMode ? Colors.white : Colors.black)),
              selected: false,
              selectedTileColor: themeProvider.isDarkMode ? const Color(0xFF222222) : Colors.grey[200],
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/profilim');
              },
            ),
            ListTile(
              leading: Icon(Icons.smart_toy, color: themeProvider.isDarkMode ? const Color(0xFFFFD700) : Colors.black),
              title: Text('AI Asistan', style: TextStyle(color: themeProvider.isDarkMode ? Colors.white : Colors.black)),
              selected: false,
              selectedTileColor: themeProvider.isDarkMode ? const Color(0xFF222222) : Colors.grey[200],
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/ai-asistan');
              },
            ),
            Divider(color: themeProvider.isDarkMode ? const Color(0xFF444444) : Colors.grey),
            ListTile(
              leading: Icon(Icons.settings, color: themeProvider.isDarkMode ? const Color(0xFFFFD700) : Colors.black),
              title: Text(languageProvider.getText('Ayarlar'), style: TextStyle(color: themeProvider.isDarkMode ? Colors.white : Colors.black)),
              selected: false,
              selectedTileColor: themeProvider.isDarkMode ? const Color(0xFF222222) : Colors.grey[200],
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/ayarlar');
              },
            ),
            ListTile(
              leading: Icon(Icons.help, color: themeProvider.isDarkMode ? const Color(0xFFFFD700) : Colors.black),
              title: Text(languageProvider.getText('Yardım'), style: TextStyle(color: themeProvider.isDarkMode ? Colors.white : Colors.black)),
              selected: false,
              selectedTileColor: themeProvider.isDarkMode ? const Color(0xFF222222) : Colors.grey[200],
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/yardim');
              },
            ),
            ListTile(
              leading: Icon(Icons.logout, color: themeProvider.isDarkMode ? const Color(0xFFFFD700) : Colors.black),
              title: Text(languageProvider.getText('Çıkış Yap'), style: TextStyle(color: themeProvider.isDarkMode ? Colors.white : Colors.black)),
              selected: false,
              selectedTileColor: themeProvider.isDarkMode ? const Color(0xFF222222) : Colors.grey[200],
              onTap: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      backgroundColor: themeProvider.isDarkMode ? const Color(0xFF111111) : Colors.white,
                      title: Text(
                        'Çıkış Yap',
                        style: TextStyle(
                          color: themeProvider.isDarkMode ? const Color(0xFFFFD700) : Colors.black,
                        ),
                      ),
                      content: Text(
                        'Çıkış yapmak istediğinizden emin misiniz?',
                        style: TextStyle(
                          color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text(
                            'İptal',
                            style: TextStyle(
                              color: themeProvider.isDarkMode ? const Color(0xFFFFD700) : Colors.blue,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Provider.of<AuthProvider>(context, listen: false).logout();
                            Navigator.pushReplacementNamed(context, '/login');
                          },
                          child: Text(
                            'Çıkış Yap',
                            style: TextStyle(
                              color: themeProvider.isDarkMode ? const Color(0xFFFFD700) : Colors.blue,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: themeProvider.isDarkMode ? const Color(0xFF1a1a1a) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: themeProvider.isDarkMode ? const Color(0xFF333333) : Colors.grey.shade300,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: themeProvider.isDarkMode 
                          ? const Color(0xFFFFD700).withOpacity(0.1)
                          : Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    height: 400,
                    child: WebViewWidget(controller: _controller),
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: themeProvider.isDarkMode ? const Color(0xFF1a1a1a) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: themeProvider.isDarkMode ? const Color(0xFF333333) : Colors.grey.shade300,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: themeProvider.isDarkMode 
                          ? const Color(0xFFFFD700).withOpacity(0.1)
                          : Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.star,
                          color: const Color(0xFFFFD700),
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'QUANTUMTRADE AI',
                          style: TextStyle(
                            color: themeProvider.isDarkMode ? const Color(0xFFFFD700) : Colors.black,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.star,
                          color: const Color(0xFFFFD700),
                          size: 24,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_isAnalyzing)
                      Column(
                        children: [
                          ...List.generate(_analysisParts.length, (index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (_isTyping && _currentTypingTexts[index].isNotEmpty)
                                    Container(
                                      width: 8,
                                      height: 16,
                                      margin: const EdgeInsets.only(right: 8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFD700),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  Expanded(
                                    child: Text(
                                      _currentTypingTexts[index],
                                      style: TextStyle(
                                        color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          if (_isTyping)
                            Column(
                              children: [
                                const SizedBox(height: 16),
                                const CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'QuantumTrade AI teknik analiz yapıyor...',
                                  style: TextStyle(
                                    color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      )
                    else
                      Column(
                        children: _analysisParts.map((text) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            text,
                            style: TextStyle(
                              color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                              height: 1.5,
                            ),
                          ),
                        )).toList(),
                      ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Son güncelleme: ${DateTime.now().toString().substring(11, 16)}',
                          style: TextStyle(
                            color: themeProvider.isDarkMode ? Colors.grey : Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD700),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
