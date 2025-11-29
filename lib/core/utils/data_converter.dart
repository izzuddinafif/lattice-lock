class DataConverter {
  /// Convert string to binary representation
  static String stringToBinary(String text) {
    return text.codeUnits
        .map((char) => char.toRadixString(2).padLeft(8, '0'))
        .join('');
  }
  
  /// Convert binary to string
  static String binaryToString(String binary) {
    // Ensure binary string length is multiple of 8
    final paddedBinary = binary.padLeft((binary.length / 8).ceil() * 8, '0');
    
    String result = '';
    for (int i = 0; i < paddedBinary.length; i += 8) {
      final byte = paddedBinary.substring(i, i + 8);
      final charCode = int.parse(byte, radix: 2);
      result += String.fromCharCode(charCode);
    }
    return result;
  }
  
  /// Convert binary string to list of bits
  static List<int> binaryToBitList(String binary) {
    return binary.split('').map((bit) => int.parse(bit)).toList();
  }
  
  /// Convert list of bits to binary string
  static String bitListToBinary(List<int> bits) {
    return bits.map((bit) => bit.toString()).join('');
  }
  
  /// Pad binary string to specified grid size
  static String padBinaryToGrid(String binary, int gridSize) {
    final totalCells = gridSize * gridSize;
    final paddedLength = (totalCells / 8).ceil() * 8; // Round up to nearest byte
    return binary.padRight(paddedLength, '0');
  }
}