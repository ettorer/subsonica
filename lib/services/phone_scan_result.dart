enum PhoneScanStatus { found, empty, denied, failed }

class PhoneScanResult {
  const PhoneScanResult(this.status, {this.tracks = 0});

  final PhoneScanStatus status;
  final int tracks;
}
