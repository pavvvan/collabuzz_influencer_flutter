import 'package:dio/dio.dart';

import 'constants.dart';


class LocationServices {
  final Dio _dio = Dio();

  Future<List<Map<String, dynamic>>> fetchStates() async {
    final response = await _dio.get(
      'https://api.countrystatecity.in/v1/countries/IN/states',
      options: Options(headers: {'X-CSCAPI-KEY': CSC_API_KEY}),
    );
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<List<Map<String, dynamic>>> fetchCities(String stateIso) async {
    final response = await _dio.get(
      'https://api.countrystatecity.in/v1/countries/IN/states/$stateIso/cities',
      options: Options(headers: {'X-CSCAPI-KEY': CSC_API_KEY}),
    );
    return List<Map<String, dynamic>>.from(response.data);
  }
}
