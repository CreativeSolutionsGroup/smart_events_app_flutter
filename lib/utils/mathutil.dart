import "dart:math";

class MathUtil {
  static double getDistance(int rssi, int? txPower) {
    int realTX = txPower == null ? -41 : txPower;
    /*
     * RSSI = TxPower - 10 * n * lg(d)
     * n = 2 (in free space)
     *
     * d = 10 ^ ((TxPower - RSSI) / (10 * n))
     */
    double rsi = (realTX.toDouble() - rssi) / (10 * 2);
    return pow(10.0, rsi).toDouble();
  }

  static double calculateDistance(int? txPower, int rssi) {
    if (rssi == 0) {
      return -1.0; // if we cannot determine accuracy, return -1.
    }
    int realTX = txPower == null ? -41 : txPower;
    double ratio = rssi*1.0/realTX;
    if (ratio < 1.0) {
      return pow(ratio,10).toDouble();
    }
    else {
      double accuracy =  (0.89976)*pow(ratio,7.7095) + 0.111;
      return accuracy;
    }
  }
}