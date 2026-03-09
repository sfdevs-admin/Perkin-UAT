public with sharing class B2BHMACGeneratorHandler {
  // private static final String HMAC_ALGORITHM = 'HmacSHA512'; //'HMACSHA1';
  
  public static String generateAuthorizationValue(
    Map<String, Object> taxConfig,
  String dateHeader
  ) {
    String username = (String) taxConfig.get('Username');
    String password = (String) taxConfig.get('Password');
    String secretKey = (String) taxConfig.get('HmacKey');
    String authenticateEndpoint = (String) taxConfig.get('EndPoint');
    String hmacAlgorithm = (String) taxConfig.get('HmacAlgorithm');
    hmacAlgorithm = 'Hmac' + hmacAlgorithm;
    
    String hmacInput =
      B2BConstants.HTTP_POST +
      B2BConstants.HTTP_HEADER_CONTENT_TYPE_JSON +
      dateHeader +
      +'/'+authenticateEndpoint +
      username +
      password;
    
    hmacInput = hmacInput.trim();
    
    String hmacSignature = generateHMAC(hmacInput, secretKey, hmacAlgorithm);
    return 'TAX ' + username + ':' + hmacSignature;
  }
  
  private static String generateHMAC(String hmacInput, String secretKey, String hmacAlgorithm) {
    Blob hmacData = Blob.valueOf(hmacInput.trim());
    Blob hmacKeyBlob = Blob.valueOf(secretKey);
    Blob hmacSignatureBlob = Crypto.generateMac(hmacAlgorithm,hmacData,hmacKeyBlob);
    return EncodingUtil.base64Encode(hmacSignatureBlob);
  }
}