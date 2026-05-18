import 'dart:convert';
import 'dart:io';
import 'package:logging/logging.dart';
import 'log_manager.dart';

class CurrencyConverterService {
  static final CurrencyConverterService _instance = CurrencyConverterService._internal();
  factory CurrencyConverterService() => _instance;
  CurrencyConverterService._internal();

  final _logger = Logger('CurrencyConverterService');
  
  Map<String, double> _rates = {}; // Currency -> Rate (relative to base)
  DateTime? _lastUpdate;
  
  bool get hasRates => _rates.isNotEmpty && _rates.containsKey('RUB');
  DateTime? get lastUpdate => _lastUpdate;

  Future<void> fetchRates(String source) async {
    try {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
      
      if (source == 'er-api') {
        final url = Uri.parse('https://open.er-api.com/v6/latest/USD');
        final request = await client.getUrl(url);
        final response = await request.close();
        
        if (response.statusCode == 200) {
          final body = await response.transform(utf8.decoder).join();
          final data = json.decode(body) as Map<String, dynamic>;
          final ratesData = data['rates'] as Map<String, dynamic>;
          
          _rates.clear();
          ratesData.forEach((key, value) {
            _rates[key] = (value as num).toDouble();
          });
          _lastUpdate = DateTime.now();
          LogManager.info('Конвертер валют обновлен (ER-API). База: USD, RUB: ${_rates['RUB']}');
        } else {
          throw Exception('ER-API returned ${response.statusCode}');
        }
      } else if (source == 'frankfurter') {
        // У Frankfurter API по умолчанию база EUR
        final url = Uri.parse('https://api.frankfurter.app/latest');
        final request = await client.getUrl(url);
        final response = await request.close();
        
        if (response.statusCode == 200) {
          final body = await response.transform(utf8.decoder).join();
          final data = json.decode(body) as Map<String, dynamic>;
          final ratesData = data['rates'] as Map<String, dynamic>;
          
          _rates.clear();
          ratesData.forEach((key, value) {
            _rates[key] = (value as num).toDouble();
          });
          final base = data['base'] as String? ?? 'EUR';
          _rates[base] = 1.0;
          _lastUpdate = DateTime.now();
          LogManager.info('Конвертер валют обновлен (Frankfurter). База: $base, RUB: ${_rates['RUB']}');
        } else {
          throw Exception('Frankfurter returned ${response.statusCode}');
        }
      } else if (source == 'ratata') {
        final url = Uri.parse('https://ratata.money/api/v1/rates/latest?base=RUB');
        final request = await client.getUrl(url);
        final response = await request.close();
        
        if (response.statusCode == 200) {
          final body = await response.transform(utf8.decoder).join();
          final data = json.decode(body) as Map<String, dynamic>;
          final ratesData = data['rates'] as Map<String, dynamic>;
          
          _rates.clear();
          ratesData.forEach((key, value) {
            _rates[key] = (value as num).toDouble();
          });
          _rates['RUB'] = 1.0;
          _lastUpdate = DateTime.now();
          LogManager.info('Конвертер валют обновлен (Ratata). База: RUB, USD: ${_rates['USD']}');
        } else {
          throw Exception('Ratata returned ${response.statusCode}');
        }
      } else if (source == 'cbr-json') {
        final url = Uri.parse('https://www.cbr-xml-daily.ru/latest.js');
        final request = await client.getUrl(url);
        final response = await request.close();
        
        if (response.statusCode == 200) {
          final body = await response.transform(utf8.decoder).join();
          final data = json.decode(body) as Map<String, dynamic>;
          final ratesData = data['rates'] as Map<String, dynamic>;
          
          _rates.clear();
          ratesData.forEach((key, value) {
            _rates[key] = (value as num).toDouble();
          });
          _rates['RUB'] = 1.0;
          _lastUpdate = DateTime.now();
          LogManager.info('Конвертер валют обновлен (CBR-JSON). База: RUB, USD: ${_rates['USD']}');
        } else {
          throw Exception('CBR JSON returned ${response.statusCode}');
        }
      } else if (source == 'cbr-xml') {
        final url = Uri.parse('https://www.cbr.ru/scripts/XML_daily.asp');
        final request = await client.getUrl(url);
        final response = await request.close();
        
        if (response.statusCode == 200) {
          // CBR returns windows-1251, so we decode as latin1/ascii to safely extract English tags and digits
          final bytes = await response.expand((b) => b).toList();
          final body = String.fromCharCodes(bytes);
          
          final regex = RegExp(r'<CharCode>([A-Z]+)<\/CharCode>.*?<Nominal>(\d+)<\/Nominal>.*?<Value>([\d,]+)<\/Value>');
          final matches = regex.allMatches(body);
          
          _rates.clear();
          for (final match in matches) {
            final code = match.group(1)!;
            final nominal = double.parse(match.group(2)!);
            final valueStr = match.group(3)!.replaceAll(',', '.');
            final value = double.parse(valueStr);
            
            // value is how many RUB for `nominal` amount of `code`
            // Example: 1 USD = 90 RUB. _rates['USD'] should be 1 / 90.
            _rates[code] = nominal / value;
          }
          _rates['RUB'] = 1.0;
          _lastUpdate = DateTime.now();
          LogManager.info('Конвертер валют обновлен (CBR-XML). База: RUB, USD: ${_rates['USD']}');
        } else {
          throw Exception('CBR XML returned ${response.statusCode}');
        }
      }
    } catch (e) {
      _logger.warning('Ошибка обновления курсов: $e');
      LogManager.error('Конвертер: ошибка загрузки курсов ($source) - $e');
    }
  }

  /// Converts an amount from [fromCurrency] to RUB.
  /// Returns null if conversion is impossible (e.g. unknown currency or no rates).
  double? convertToRub(double amount, String fromCurrency) {
    if (fromCurrency.toUpperCase() == 'RUB') return amount;
    if (_rates.isEmpty || !_rates.containsKey('RUB')) return null;
    
    final cur = fromCurrency.toUpperCase();
    if (!_rates.containsKey(cur)) return null;
    
    final rateToRub = _rates['RUB']! / _rates[cur]!;
    return amount * rateToRub;
  }
}
