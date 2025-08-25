class UsbDeviceInfo {
  final String deviceId;
  final String productName;
  final int vendorId;
  final int productId;
  final bool isDistingNT;

  const UsbDeviceInfo({
    required this.deviceId,
    required this.productName,
    required this.vendorId,
    required this.productId,
    required this.isDistingNT,
  });

  factory UsbDeviceInfo.fromMap(Map<dynamic, dynamic> map) {
    return UsbDeviceInfo(
      deviceId: map['deviceId'] as String,
      productName: map['productName'] as String,
      vendorId: map['vendorId'] as int,
      productId: map['productId'] as int,
      isDistingNT: map['isDistingNT'] as bool,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'deviceId': deviceId,
      'productName': productName,
      'vendorId': vendorId,
      'productId': productId,
      'isDistingNT': isDistingNT,
    };
  }
}
