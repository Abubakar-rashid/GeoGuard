import '../../core/constants/api_config.dart';
import 'api_client.dart';

/// AI Assistant service that communicates with the backend API
class AIAssistantService {
  final ApiClient _apiClient;

  AIAssistantService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Get safety advice from AI for a specific disaster type
  Future<String> getSafetyAdvice({
    required String disasterType,
    String? userLocation,
    bool isEmergency = false,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConfig.aiSafetyAdvice,
        data: {
          'disaster_type': disasterType,
          'user_location': userLocation,
          'is_emergency': isEmergency,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return data['advice'] as String;
      }
      return _getOfflineSafetyAdvice(disasterType);
    } catch (e) {
      print('AI Assistant error: $e');
      return _getOfflineSafetyAdvice(disasterType);
    }
  }

  /// Chat with AI assistant about disaster safety
  Future<String> chat(String userMessage) async {
    try {
      final response = await _apiClient.post(
        ApiConfig.aiChat,
        data: {
          'message': userMessage,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return data['response'] as String;
      }
      return 'AI Assistant is currently unavailable. Please try again later.';
    } catch (e) {
      print('AI Chat error: $e');
      return 'I apologize, but I am having trouble responding right now. Please try again later.';
    }
  }

  /// Get precautions for specific disaster
  Future<String> getPrecautions(String disasterType) async {
    try {
      final response = await _apiClient.post(
        ApiConfig.aiPrecautions,
        data: {
          'disaster_type': disasterType,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return data['precautions'] as String;
      }
      return _getOfflinePrecautions(disasterType);
    } catch (e) {
      return _getOfflinePrecautions(disasterType);
    }
  }

  /// Analyze seasonal disaster trends
  Future<String> analyzeSeasonalTrends({
    required String region,
    required int month,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConfig.aiSeasonalTrends,
        data: {
          'region': region,
          'month': month,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return data['analysis'] as String;
      }
      return 'Seasonal analysis requires an internet connection.';
    } catch (e) {
      return 'Unable to analyze seasonal trends at this time.';
    }
  }

  String _getOfflineSafetyAdvice(String disasterType) {
    switch (disasterType.toLowerCase()) {
      case 'earthquake':
        return '''
🏠 EARTHQUAKE SAFETY

DURING:
• DROP to hands and knees
• Take COVER under sturdy furniture
• HOLD ON until shaking stops
• Stay away from windows and heavy objects

AFTER:
• Check for injuries and provide first aid
• Be prepared for aftershocks
• Check gas, water, and electric lines
• Use flashlight, not candles
''';

      case 'flood':
        return '''
🌊 FLOOD SAFETY

DURING:
• Move immediately to higher ground
• Never walk or drive through flood waters
• Turn off utilities at main switches
• Disconnect electrical appliances

AFTER:
• Return only when authorities say it's safe
• Clean and disinfect everything
• Watch for road hazards
• Document damage for insurance
''';

      case 'weather':
      case 'thunderstorm':
        return '''
⛈️ SEVERE WEATHER SAFETY

DURING:
• Go indoors immediately
• Stay away from windows
• Avoid using corded phones
• Unplug electronic equipment

IF CAUGHT OUTSIDE:
• Avoid tall isolated objects
• Get to low ground
• Never seek shelter under trees
''';

      default:
        return 'Stay calm and follow local emergency guidelines.';
    }
  }

  String _getOfflinePrecautions(String disasterType) {
    switch (disasterType.toLowerCase()) {
      case 'earthquake':
        return '''
1. Secure heavy furniture to walls
2. Know how to turn off utilities
3. Prepare an emergency kit
4. Identify safe spots in each room
5. Practice DROP, COVER, HOLD ON drills
''';

      case 'flood':
        return '''
1. Know your flood risk zone
2. Keep important documents elevated
3. Have a battery-powered radio
4. Never drive through flooded roads
5. Have evacuation routes planned
''';

      default:
        return '''
1. Monitor weather forecasts
2. Have a battery-powered radio
3. Know your shelter location
4. Keep emergency supplies ready
5. Have a family communication plan
''';
    }
  }
}
