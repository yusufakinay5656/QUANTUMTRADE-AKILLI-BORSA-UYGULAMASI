import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/language_provider.dart';
import '../widgets/user_avatar_button.dart';
import '../services/market_analysis_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_tts/flutter_tts.dart';

class ProfilimPage extends StatefulWidget {
  const ProfilimPage({Key? key}) : super(key: key);

  @override
  State<ProfilimPage> createState() => _ProfilimPageState();
}

class _ProfilimPageState extends State<ProfilimPage> {
  final MarketAnalysisService _marketAnalysisService = MarketAnalysisService();
  final FlutterTts flutterTts = FlutterTts();
  String _marketAnalysis = '';
  bool _isLoading = false;
  bool isLoading = false;
  bool isSpeaking = false;
  String errorMessage = '';
  Map<String, dynamic>? investmentAdvice;
  Timer? _refreshTimer;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    getInvestmentAdvice();
    _initTts();
    // Her 5 dakikada bir güncelle
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      getInvestmentAdvice();
    });
  }

  Future<void> _initTts() async {
    try {
      await flutterTts.setLanguage("tr-TR");
      await flutterTts.setSpeechRate(0.4);
      await flutterTts.setVolume(0.8);
      await flutterTts.setPitch(1.0);
      
      await flutterTts.setQueueMode(1);
      await flutterTts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.ambient,
        [
          IosTextToSpeechAudioCategoryOptions.allowBluetooth,
          IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
          IosTextToSpeechAudioCategoryOptions.mixWithOthers,
        ],
      );
    } catch (e) {
      print('TTS başlatma hatası: $e');
    }
  }

  Future<void> _speakAdvice() async {
    if (investmentAdvice == null) return;

    setState(() => isSpeaking = true);

    try {
      // Hoş geldiniz mesajı
      await flutterTts.speak('İyi günler geleceğin milyoneri. Milyoner olmana bir adım kaldı.');
      await Future.delayed(const Duration(seconds: 3));

      // Öne çıkan yatırım fırsatları
      await flutterTts.speak('Öne çıkan yatırım fırsatlarını sizinle paylaşıyorum.');
      await Future.delayed(const Duration(seconds: 2));

      final opportunities = investmentAdvice!['opportunities'] as List;
      for (var opportunity in opportunities) {
        if (!isSpeaking) break; // Eğer speaking durdurulduysa döngüden çık
        
        final symbol = opportunity['symbol'].toString().replaceAll('USDT', '');
        final advice = opportunity['advice'];
        final confidence = opportunity['confidence'];
        final reasoning = (opportunity['reasoning'] as List).join(', ');
        final riskLevel = opportunity['riskLevel'];
        
        // Sadece risk seviyesi ve yükseliş/düşüş bilgilerini içeren metin
        final text = '$symbol için tavsiyem $advice. Güven oranı yüzde $confidence. Risk seviyesi $riskLevel.';
        
        // Cümleyi daha anlaşılır hale getir
        final formattedText = text
            .replaceAll('BTC', 'Bitcoin')
            .replaceAll('ETH', 'Ethereum')
            .replaceAll('BNB', 'Binance Coin')
            .replaceAll('ADA', 'Cardano')
            .replaceAll('DOGE', 'Dogecoin')
            .replaceAll('GÜÇLÜ ALIM', 'Güçlü Alım')
            .replaceAll('ALIM', 'Alım')
            .replaceAll('GÜÇLÜ SATIM', 'Güçlü Satım')
            .replaceAll('SATIM', 'Satım')
            .replaceAll('BEKLE', 'Bekle')
            .replaceAll('YÜKSEK', 'Yüksek')
            .replaceAll('ORTA', 'Orta')
            .replaceAll('DÜŞÜK', 'Düşük');

        await flutterTts.speak(formattedText);
        await Future.delayed(const Duration(seconds: 3));
      }

      if (!isSpeaking) return; // Eğer speaking durdurulduysa fonksiyondan çık

      // Teknik analiz
      await flutterTts.speak('Şimdi teknik analiz sonuçlarını paylaşıyorum.');
      await Future.delayed(const Duration(seconds: 2));

      final technicalAnalysis = investmentAdvice!['technicalAnalysis'] as List;
      for (var analysis in technicalAnalysis) {
        if (!isSpeaking) break; // Eğer speaking durdurulduysa döngüden çık
        
        final symbol = analysis['symbol'].toString().replaceAll('USDT', '');
        final isPositive = analysis['isPositive'] ? 'yükseliş' : 'düşüş';
        
        final formattedSymbol = symbol
            .replaceAll('BTC', 'Bitcoin')
            .replaceAll('ETH', 'Ethereum')
            .replaceAll('BNB', 'Binance Coin')
            .replaceAll('ADA', 'Cardano')
            .replaceAll('DOGE', 'Dogecoin');
            
        await flutterTts.speak('$formattedSymbol için teknik analiz $isPositive trendinde.');
        await Future.delayed(const Duration(seconds: 2));
      }

      if (!isSpeaking) return; // Eğer speaking durdurulduysa fonksiyondan çık

      // Hacim analizi
      await flutterTts.speak('Hacim analizi sonuçları şu şekilde.');
      await Future.delayed(const Duration(seconds: 2));

      final volumeAnalysis = investmentAdvice!['volumeAnalysis'] as List;
      for (var analysis in volumeAnalysis) {
        if (!isSpeaking) break; // Eğer speaking durdurulduysa döngüden çık
        
        final symbol = analysis['symbol'].toString().replaceAll('USDT', '');
        final isPositive = analysis['isPositive'] ? 'yükseliş' : 'düşüş';
        
        final formattedSymbol = symbol
            .replaceAll('BTC', 'Bitcoin')
            .replaceAll('ETH', 'Ethereum')
            .replaceAll('BNB', 'Binance Coin')
            .replaceAll('ADA', 'Cardano')
            .replaceAll('DOGE', 'Dogecoin');
            
        await flutterTts.speak('$formattedSymbol için hacim analizi $isPositive trendinde.');
        await Future.delayed(const Duration(seconds: 2));
      }

      if (!isSpeaking) return; // Eğer speaking durdurulduysa fonksiyondan çık

      // Momentum analizi
      await flutterTts.speak('Momentum analizi sonuçları.');
      await Future.delayed(const Duration(seconds: 2));

      final momentumAnalysis = investmentAdvice!['momentumAnalysis'] as List;
      for (var analysis in momentumAnalysis) {
        if (!isSpeaking) break; // Eğer speaking durdurulduysa döngüden çık
        
        final symbol = analysis['symbol'].toString().replaceAll('USDT', '');
        final isPositive = analysis['isPositive'] ? 'yükseliş' : 'düşüş';
        
        final formattedSymbol = symbol
            .replaceAll('BTC', 'Bitcoin')
            .replaceAll('ETH', 'Ethereum')
            .replaceAll('BNB', 'Binance Coin')
            .replaceAll('ADA', 'Cardano')
            .replaceAll('DOGE', 'Dogecoin');
            
        await flutterTts.speak('$formattedSymbol için momentum analizi $isPositive trendinde.');
        await Future.delayed(const Duration(seconds: 2));
      }

      if (!isSpeaking) return; // Eğer speaking durdurulduysa fonksiyondan çık

      // Genel yatırım stratejisi
      await flutterTts.speak('Son olarak, genel yatırım stratejisi önerilerim.');
      await Future.delayed(const Duration(seconds: 2));

      final strategy = investmentAdvice!['strategy'] as List;
      for (var point in strategy) {
        if (!isSpeaking) break; // Eğer speaking durdurulduysa döngüden çık
        await flutterTts.speak(point);
        await Future.delayed(const Duration(seconds: 2));
      }

      if (!isSpeaking) return; // Eğer speaking durdurulduysa fonksiyondan çık

      await flutterTts.speak('QuantumTrade ile milyoner olma yolculuğunuzda başarılar dilerim.');
      await Future.delayed(const Duration(seconds: 2));

    } catch (e) {
      print('Sesli asistan hatası: $e');
    } finally {
      setState(() => isSpeaking = false);
    }
  }

  Future<void> _stopSpeaking() async {
    try {
      await flutterTts.stop();
      setState(() {
        isSpeaking = false;
      });
    } catch (e) {
      print('Sesi durdurma hatası: $e');
      // Hata durumunda da speaking durumunu false yap
      setState(() {
        isSpeaking = false;
      });
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    flutterTts.stop();
    super.dispose();
  }

  Future<void> _loadMarketAnalysis() async {
    setState(() => _isLoading = true);
    try {
      final analysis = await _marketAnalysisService.getDailyAnalysis();
      setState(() {
        _marketAnalysis = analysis;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Piyasa analizi yüklenirken hata oluştu: $e')),
        );
      }
    }
  }

  Future<void> getInvestmentAdvice() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      // Binance API'den veri al
      const symbols = ['BTCUSDT', 'ETHUSDT', 'BNBUSDT', 'ADAUSDT', 'DOGEUSDT'];
      final analyses = <Map<String, dynamic>>[];
      final investmentAdviceList = <Map<String, dynamic>>[];

      for (final symbol in symbols) {
        try {
          // 24 saatlik istatistikler
          final statsResponse = await http.get(
            Uri.parse('https://api.binance.com/api/v3/ticker/24hr?symbol=$symbol'),
          );
          final stats = json.decode(statsResponse.body);

          // Son işlemler
          final tradesResponse = await http.get(
            Uri.parse('https://api.binance.com/api/v3/trades?symbol=$symbol&limit=100'),
          );
          final trades = json.decode(tradesResponse.body);

          // Fiyat değişimi analizi
          final priceChange = double.parse(stats['priceChangePercent']);
          final volume = double.parse(stats['volume']);
          final highPrice = double.parse(stats['highPrice']);
          final lowPrice = double.parse(stats['lowPrice']);
          final currentPrice = double.parse(stats['lastPrice']);

          // Momentum hesaplama
          final recentTrades = trades.sublist(trades.length > 20 ? trades.length - 20 : 0);
          final buyVolume = recentTrades.where((t) => t['isBuyerMaker'] == true).length;
          final sellVolume = recentTrades.where((t) => t['isBuyerMaker'] == false).length;
          final momentum = (buyVolume - sellVolume) / (buyVolume + sellVolume) * 100;

          // Trend analizi
          final trend = {
            'direction': priceChange > 0 ? 'YÜKSELIŞ' : 'DÜŞÜŞ',
            'strength': priceChange.abs()
          };

          // Hacim analizi
          final volumeAnalysis = {
            'trend': volume > double.parse(stats['quoteVolume']) / 2 ? 'YÜKSELIŞ' : 'DÜŞÜŞ',
            'value': volume
          };

          // Momentum analizi
          final momentumAnalysis = {
            'direction': momentum > 0 ? 'YÜKSELIŞ' : 'DÜŞÜŞ',
            'strength': momentum.abs()
          };

          analyses.add({
            'symbol': symbol,
            'trend': trend,
            'volume': volumeAnalysis,
            'momentum': momentumAnalysis,
            'currentPrice': currentPrice
          });

          // Yatırım tavsiyesi oluştur
          var confidence = 0;
          var advice = '';
          final reasoning = <String>[];

          // Trend analizi
          if (trend['direction'] == 'YÜKSELIŞ' && (trend['strength'] as double) > 3) {
            confidence += 30;
            reasoning.add('Güçlü yükseliş trendi');
          } else if (trend['direction'] == 'DÜŞÜŞ' && (trend['strength'] as double) > 3) {
            confidence -= 30;
            reasoning.add('Güçlü düşüş trendi');
          }

          // Hacim analizi
          if (volume > double.parse(stats['quoteVolume']) / 2) {
            confidence += 20;
            reasoning.add('Yüksek işlem hacmi');
          }

          // Momentum analizi
          if (momentum.abs() > 20) {
            confidence += 10;
            reasoning.add('Güçlü momentum');
          }

          // Volatilite analizi
          final volatility = ((highPrice - lowPrice) / lowPrice) * 100;
          if (volatility > 5) {
            confidence += 10;
            reasoning.add('Yüksek volatilite fırsatı');
          }

          // Sonuç değerlendirmesi
          if (confidence >= 50) {
            advice = 'GÜÇLÜ ALIM';
          } else if (confidence >= 30) {
            advice = 'ALIM';
          } else if (confidence <= -50) {
            advice = 'GÜÇLÜ SATIM';
          } else if (confidence <= -30) {
            advice = 'SATIM';
          } else {
            advice = 'BEKLE';
          }

          investmentAdviceList.add({
            'symbol': symbol,
            'currentPrice': currentPrice,
            'advice': advice,
            'confidence': confidence.abs(),
            'reasoning': reasoning,
            'riskLevel': volatility > 10 ? 'YÜKSEK' : volatility > 5 ? 'ORTA' : 'DÜŞÜK'
          });

        } catch (e) {
          print('$symbol için veri alınamadı: $e');
        }
      }

      // Genel yatırım stratejisi
      final generalAdvice = [
        'Piyasa genelinde yükseliş trendi devam ediyor.',
        'Yüksek hacimli coinlere odaklanın.',
        'Risk yönetimi için portföyünüzü çeşitlendirin.',
        'Kısa vadeli işlemler için volatilite fırsatlarını değerlendirin.',
        'Uzun vadeli yatırımlar için güçlü temellere sahip coinleri tercih edin.'
      ];

      setState(() {
        investmentAdvice = {
          'opportunities': investmentAdviceList,
          'technicalAnalysis': analyses.map((a) => {
            'symbol': a['symbol'],
            'value': '${a['trend']['direction']} (%${(a['trend']['strength'] as double).toStringAsFixed(2)})',
            'isPositive': a['trend']['direction'] == 'YÜKSELIŞ'
          }).toList(),
          'volumeAnalysis': analyses.map((a) => {
            'symbol': a['symbol'],
            'value': '${a['volume']['trend']}',
            'isPositive': a['volume']['trend'] == 'YÜKSELIŞ'
          }).toList(),
          'momentumAnalysis': analyses.map((a) => {
            'symbol': a['symbol'],
            'value': '${a['momentum']['direction']} (%${(a['momentum']['strength'] as double).toStringAsFixed(2)})',
            'isPositive': a['momentum']['direction'] == 'YÜKSELIŞ'
          }).toList(),
          'strategy': generalAdvice
        };
        isLoading = false;
      });

    } catch (e) {
      setState(() {
        errorMessage = 'Yatırım tavsiyesi yüklenirken hata oluştu: $e';
        isLoading = false;
      });
    }
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

    // Kullanıcı bilgileri yüklenene kadar loading göster
    if (authProvider.user == null) {
      return Scaffold(
        backgroundColor: themeProvider.isDarkMode ? Colors.black : Colors.white,
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
          ),
        ),
      );
    }

    final user = authProvider.user!;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: themeProvider.isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: themeProvider.isDarkMode ? const Color(0xFF111111) : Colors.white,
        title: Text(
          languageProvider.getText('Profilim'),
          style: TextStyle(
            color: themeProvider.isDarkMode ? const Color(0xFFFFD700) : Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.menu,
            color: themeProvider.isDarkMode ? const Color(0xFFFFD700) : Colors.black,
          ),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: const [
          UserAvatarButton(),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hoş Geldiniz Mesajı
              Center(
                child: Column(
                  children: [
                    Text(
                      'HOŞ GELDİNİZ',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: themeProvider.isDarkMode ? const Color(0xFFFFD700) : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      user['name'] ?? 'Kullanıcı',
                      style: TextStyle(
                        fontSize: 20,
                        color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Sesli Asistan Butonları
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: isSpeaking ? null : _speakAdvice,
                          icon: Icon(isSpeaking ? Icons.record_voice_over : Icons.record_voice_over),
                          label: Text(isSpeaking ? 'Sesli Asistan Çalışıyor' : 'Sesli Asistan'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isSpeaking 
                              ? (themeProvider.isDarkMode ? Colors.grey : Colors.grey.shade300)
                              : (themeProvider.isDarkMode ? const Color(0xFFFFD700) : Colors.blue),
                            foregroundColor: isSpeaking 
                              ? (themeProvider.isDarkMode ? Colors.grey.shade600 : Colors.grey.shade700)
                              : (themeProvider.isDarkMode ? Colors.black : Colors.white),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: isSpeaking ? _stopSpeaking : null,
                          icon: Icon(isSpeaking ? Icons.stop : Icons.stop),
                          label: Text(isSpeaking ? 'Sesi Durdur' : 'Sesli Asistan Bekliyor'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isSpeaking 
                              ? (themeProvider.isDarkMode ? const Color(0xFFFFD700) : Colors.blue)
                              : (themeProvider.isDarkMode ? Colors.grey : Colors.grey.shade300),
                            foregroundColor: isSpeaking 
                              ? (themeProvider.isDarkMode ? Colors.black : Colors.white)
                              : (themeProvider.isDarkMode ? Colors.grey.shade600 : Colors.grey.shade700),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Kullanıcı Bilgileri
              Card(
                color: themeProvider.isDarkMode ? const Color(0xFF111111) : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: themeProvider.isDarkMode ? const Color(0xFFFFD700) : Colors.black,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow(
                        context,
                        Icons.person,
                        'Ad Soyad',
                        user['name'] ?? '',
                      ),
                      const Divider(),
                      _buildInfoRow(
                        context,
                        Icons.email,
                        'E-posta',
                        user['email'] ?? '',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Çıkış Yap Butonu
              ElevatedButton.icon(
                onPressed: () {
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
                icon: const Icon(Icons.logout),
                label: const Text('Çıkış Yap'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeProvider.isDarkMode ? const Color(0xFFFFD700) : Colors.blue,
                  foregroundColor: themeProvider.isDarkMode ? Colors.black : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Yatırım tavsiyesi butonu
              ElevatedButton(
                onPressed: isLoading ? null : getInvestmentAdvice,
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeProvider.isDarkMode ? const Color(0xFFFFD700) : Colors.blue,
                  foregroundColor: themeProvider.isDarkMode ? Colors.black : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  isLoading ? 'Yükleniyor...' : 'Günün Yatırım Tavsiyesi',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 24),
              if (errorMessage.isNotEmpty)
                Center(
                  child: Column(
                    children: [
                      Text(
                        errorMessage,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: getInvestmentAdvice,
                        child: const Text('Tekrar Dene'),
                      ),
                    ],
                  ),
                )
              else if (investmentAdvice != null) ...[
                // Öne Çıkan Yatırım Fırsatları
                Card(
                  color: themeProvider.isDarkMode ? const Color(0xFF111111) : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: themeProvider.isDarkMode ? const Color(0xFFFFD700) : Colors.black,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Öne Çıkan Yatırım Fırsatları',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: themeProvider.isDarkMode ? const Color(0xFFFFD700) : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...(investmentAdvice!['opportunities'] as List).map((coin) => buildInvestmentCard(coin)).toList(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Teknik Analiz
                Card(
                  color: themeProvider.isDarkMode ? const Color(0xFF111111) : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: themeProvider.isDarkMode ? const Color(0xFFFFD700) : Colors.black,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: buildAnalysisSection(
                      'Teknik Analiz',
                      (investmentAdvice!['technicalAnalysis'] as List).cast<Map<String, dynamic>>(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Hacim Analizi
                Card(
                  color: themeProvider.isDarkMode ? const Color(0xFF111111) : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: themeProvider.isDarkMode ? const Color(0xFFFFD700) : Colors.black,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: buildAnalysisSection(
                      'Hacim Analizi',
                      (investmentAdvice!['volumeAnalysis'] as List).cast<Map<String, dynamic>>(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Momentum Analizi
                Card(
                  color: themeProvider.isDarkMode ? const Color(0xFF111111) : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: themeProvider.isDarkMode ? const Color(0xFFFFD700) : Colors.black,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: buildAnalysisSection(
                      'Momentum Analizi',
                      (investmentAdvice!['momentumAnalysis'] as List).cast<Map<String, dynamic>>(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Genel Yatırım Stratejisi
                Card(
                  color: themeProvider.isDarkMode ? const Color(0xFF111111) : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: themeProvider.isDarkMode ? const Color(0xFFFFD700) : Colors.black,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Genel Yatırım Stratejisi',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: themeProvider.isDarkMode ? const Color(0xFFFFD700) : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...(investmentAdvice!['strategy'] as List).map((strategy) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Icon(
                                Icons.arrow_right,
                                color: themeProvider.isDarkMode ? const Color(0xFFFFD700) : Colors.black,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  strategy,
                                  style: TextStyle(
                                    color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )).toList(),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
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
              selected: false,
              selectedTileColor: themeProvider.isDarkMode ? const Color(0xFF222222) : Colors.grey[200],
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/piyasa');
              },
            ),
            ListTile(
              leading: Icon(Icons.person, color: themeProvider.isDarkMode ? const Color(0xFFFFD700) : Colors.black),
              title: Text(languageProvider.getText('Profilim'), style: TextStyle(color: themeProvider.isDarkMode ? Colors.white : Colors.black)),
              selected: true,
              selectedTileColor: themeProvider.isDarkMode ? const Color(0xFF222222) : Colors.grey[200],
              onTap: () {
                Navigator.pop(context);
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
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(
            icon,
            color: themeProvider.isDarkMode ? const Color(0xFFFFD700) : Colors.black,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: themeProvider.isDarkMode ? Colors.grey : Colors.black54,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildInvestmentCard(Map<String, dynamic> coin) {
    final isPositive = coin['advice']?.toString().contains('ALIM') ?? false;
    final color = isPositive ? Colors.green : Colors.red;
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.2),
            themeProvider.isDarkMode ? Colors.black.withOpacity(0.8) : Colors.white.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: color.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  coin['symbol']?.toString().replaceAll('USDT', '') ?? 'N/A',
                  style: TextStyle(
                    color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withOpacity(0.5)),
                  ),
                  child: Text(
                    coin['advice'] ?? 'N/A',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blue.withOpacity(0.5)),
                  ),
                  child: Text(
                    'Güven: ${coin['confidence']}%',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: (coin['riskLevel'] == 'YÜKSEK' ? Colors.red : 
                           coin['riskLevel'] == 'ORTA' ? Colors.orange : Colors.green).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: (coin['riskLevel'] == 'YÜKSEK' ? Colors.red : 
                             coin['riskLevel'] == 'ORTA' ? Colors.orange : Colors.green).withOpacity(0.5),
                    ),
                  ),
                  child: Text(
                    'Risk: ${coin['riskLevel']}',
                    style: TextStyle(
                      color: coin['riskLevel'] == 'YÜKSEK' ? Colors.red : 
                             coin['riskLevel'] == 'ORTA' ? Colors.orange : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: themeProvider.isDarkMode ? Colors.black.withOpacity(0.3) : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: themeProvider.isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Analiz Detayları:',
                    style: TextStyle(
                      color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...(coin['reasoning'] as List<dynamic>).map((reason) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.arrow_right,
                          color: color,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            reason.toString(),
                            style: TextStyle(
                              color: themeProvider.isDarkMode ? Colors.white70 : Colors.black87,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildAnalysisSection(String title, List<Map<String, dynamic>> data) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: themeProvider.isDarkMode ? Colors.white : Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...data.map((item) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                (item['isPositive'] == true ? Colors.green : Colors.red).withOpacity(0.1),
                themeProvider.isDarkMode ? Colors.black.withOpacity(0.8) : Colors.white.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: (item['isPositive'] == true ? Colors.green : Colors.red).withOpacity(0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: (item['isPositive'] == true ? Colors.green : Colors.red).withOpacity(0.1),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item['symbol']?.toString().replaceAll('USDT', '') ?? 'N/A',
                style: TextStyle(
                  color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: (item['isPositive'] == true ? Colors.green : Colors.red).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: (item['isPositive'] == true ? Colors.green : Colors.red).withOpacity(0.5),
                  ),
                ),
                child: Text(
                  item['value'] ?? 'N/A',
                  style: TextStyle(
                    color: item['isPositive'] == true ? Colors.green : Colors.red,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        )).toList(),
      ],
    );
  }
}
