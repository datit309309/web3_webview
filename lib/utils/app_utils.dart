import 'package:clipboard/clipboard.dart';
import 'package:intl/intl.dart';

class AppUtils {
  static void copyToClipboard(String text, [String? message]) {
    FlutterClipboard.copy(text)
        .then((value) => print('Copied to clipboard: $text'));
  }

  static String formatCoin(
    dynamic amount, {
    String symbol = '',
    int? decimalDigits = 2,
    bool leftSymbol = false,
    bool useUnitSuffix = false, // Thêm parameter để bật/tắt việc sử dụng B,M,K
  }) {
    if (amount is String) {
      try {
        amount = double.parse(amount);
      } catch (e) {
        amount = 0;
      }
    }

    double numAmount = amount.toDouble();
    String suffix = '';

    if (useUnitSuffix && numAmount != 0) {
      if (numAmount.abs() >= 1e12) {
        numAmount /= 1e12;
        suffix = 'T';
      } else if (numAmount.abs() >= 1e9) {
        numAmount /= 1e9;
        suffix = 'B';
      } else if (numAmount.abs() >= 1e6) {
        numAmount /= 1e6;
        suffix = 'M';
      } else if (numAmount.abs() >= 1e3) {
        numAmount /= 1e3;
        suffix = 'K';
      } else if (numAmount.abs() < 1 && numAmount.abs() > 0) {
        if (numAmount.abs() >= 1e-3) {
          numAmount *= 1e3;
          suffix = 'm';
        } else if (numAmount.abs() >= 1e-6) {
          numAmount *= 1e6;
          suffix = 'μ';
        } else if (numAmount.abs() >= 1e-9) {
          numAmount *= 1e9;
          suffix = 'n';
        }
      }
    }

    // Xác định số chữ số thập phân
    if (numAmount == 0) {
      decimalDigits = 0;
    } else if (suffix.isEmpty) {
      if (numAmount.abs() < 100) {
        decimalDigits = decimalDigits ?? 6;
      }
    } else {
      // Với các suffix, điều chỉnh số chữ số thập phân theo giá trị
      if (numAmount.abs() >= 100) {
        decimalDigits = 1;
      } else if (numAmount.abs() >= 10) {
        decimalDigits = 2;
      } else {
        decimalDigits = 3;
      }
    }

    var formatLargeCoin = NumberFormat.currency(
      locale: 'en_US',
      symbol: symbol,
      decimalDigits: decimalDigits,
      customPattern: leftSymbol ? '\u00a4 #,###' : '#,### \u00a4',
    );

    String formatted = formatLargeCoin.format(numAmount);
    formatted = removeUnnecessaryZeros(formatted, symbol, leftSymbol);

    // Thêm số 0 phía trước nếu bắt đầu bằng dấu chấm
    if (formatted.startsWith('.')) {
      formatted = '0$formatted';
    }
    if (formatted.startsWith('-.')) {
      formatted = formatted.replaceFirst('-.', '-0.');
    }

    // Thêm suffix vào kết quả
    if (suffix.isNotEmpty) {
      if (symbol.isEmpty) {
        formatted = '$formatted$suffix';
      } else {
        formatted = formatted.replaceAll(symbol, '').trim();
        formatted = leftSymbol
            ? '$symbol $formatted$suffix'
            : '$formatted$suffix $symbol';
      }
    }

    return formatted;
  }

  static String removeUnnecessaryZeros(
      String formatted, String symbol, bool leftSymbol) {
    formatted = leftSymbol ? formatted.split(' ')[1] : formatted.split(' ')[0];
    // Kiểm tra nếu chuỗi có phần thập phân
    if (formatted.contains('.')) {
      // Tách phần nguyên và phần thập phân
      List<String> parts = formatted.split('.');
      String integerPart = parts[0] == '' ? '0' : parts[0];
      String decimalPart =
          parts[1].replaceAll(RegExp(r'\D'), ''); // Bỏ các ký tự không phải số

      // Loại bỏ các chữ số 0 thừa ở cuối phần thập phân, nhưng giữ lại số khác 0
      decimalPart = decimalPart.replaceAll(RegExp(r'0+$'), '');

      // Nếu phần thập phân sau khi loại bỏ toàn là 0, chỉ trả về phần nguyên
      if (decimalPart.isEmpty) {
        formatted = integerPart;
      } else {
        formatted = '$integerPart.$decimalPart';
      }
    }
    return symbol != ''
        ? leftSymbol
            ? '$symbol $formatted'
            : '$formatted $symbol'
        : formatted;
  }
}

extension StringExt on String {
  String ellipsisWalletAddress() {
    if (length < 20) {
      return this;
    }
    return '${substring(0, 13)}...${substring(length - 13)}';
  }

  String ellipsisMidWalletAddress() {
    if (length < 20) {
      return this;
    }
    return '${substring(0, 8)}...${substring(length - 8)}';
  }

  String ellipsisMaxWalletAddress() {
    if (length < 20) {
      return this;
    }
    return '${substring(0, 4)}...${substring(length - 3)}';
  }
}

extension BigIntX on BigInt {
  double toRealDouble(int decimals) {
    return this / BigInt.from(10).pow(decimals);
  }

  double parseGwei() {
    return this / BigInt.from(10).pow(9);
  }

  double parseEther() {
    return this / BigInt.from(10).pow(18);
  }
}
