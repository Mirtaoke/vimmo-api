import '../../core/constants/api_constants.dart';

class EsgeApiProvider {
  const EsgeApiProvider();
  String endpoint(String path) => '${ApiConstants.baseUrl}$path';
}
