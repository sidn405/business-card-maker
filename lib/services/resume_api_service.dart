import 'dart:convert';
import 'package:http/http.dart' as http;

/// ProStack Resume API Service
/// Calls FastAPI backend for AI-powered resume generation
class ResumeAPIService {
  // UPDATE THESE AFTER DEPLOYMENT
  static const String baseUrl = 'https://your-railway-url.railway.app';
  static const String apiKey = 'your-prostack-api-key';
  
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'X-API-Key': apiKey,
  };

  /// Check if backend is healthy
  static Future<bool> healthCheck() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      print('Health check failed: $e');
      return false;
    }
  }

  /// Generate AI-enhanced resume
  static Future<Map<String, dynamic>> generateResume({
    required String fullName,
    required String email,
    required String phone,
    required String location,
    String? linkedin,
    String? portfolio,
    String? summary,
    String? targetRole,
    int? yearsExperience,
    List<Map<String, dynamic>>? workExperience,
    List<Map<String, dynamic>>? education,
    List<Map<String, dynamic>>? skills,
    List<Map<String, dynamic>>? projects,
    List<Map<String, dynamic>>? certifications,
    String template = 'modern',
    String? targetIndustry,
    String? jobDescription,
    bool enhanceSummary = true,
    bool optimizeKeywords = true,
    bool improveAchievements = true,
  }) async {
    try {
      final requestBody = {
        'full_name': fullName,
        'email': email,
        'phone': phone,
        'location': location,
        'linkedin': linkedin,
        'portfolio': portfolio,
        'summary': summary,
        'target_role': targetRole,
        'years_experience': yearsExperience,
        'work_experience': workExperience ?? [],
        'education': education ?? [],
        'skills': skills ?? [],
        'projects': projects ?? [],
        'certifications': certifications ?? [],
        'template': template,
        'target_industry': targetIndustry,
        'job_description': jobDescription,
        'enhance_summary': enhanceSummary,
        'optimize_keywords': optimizeKeywords,
        'improve_achievements': improveAchievements,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/resume/generate'),
        headers: _headers,
        body: json.encode(requestBody),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        throw Exception('Invalid API key');
      } else {
        throw Exception('Failed to generate resume: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Resume generation error: $e');
    }
  }

  /// Enhance just the professional summary
  static Future<String> enhanceSummary({
    required String summary,
    required String targetRole,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/resume/enhance-summary'),
        headers: _headers,
        body: json.encode({
          'summary': summary,
          'target_role': targetRole,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['enhanced_summary'];
      } else {
        throw Exception('Failed to enhance summary: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Summary enhancement error: $e');
    }
  }

  /// Analyze job description and extract requirements
  static Future<Map<String, dynamic>> analyzeJobDescription({
    required String jobDescription,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/resume/analyze-job'),
        headers: _headers,
        body: json.encode({
          'job_description': jobDescription,
        }),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['analysis'];
      } else {
        throw Exception('Failed to analyze job: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Job analysis error: $e');
    }
  }
}

/// Example Usage:
/// 
/// ```dart
/// // Check backend health
/// final isHealthy = await ResumeAPIService.healthCheck();
/// 
/// // Generate resume
/// final result = await ResumeAPIService.generateResume(
///   fullName: 'John Doe',
///   email: 'john@example.com',
///   phone: '555-1234',
///   location: 'New York, NY',
///   targetRole: 'Software Engineer',
///   workExperience: [
///     {
///       'company': 'Tech Corp',
///       'title': 'Developer',
///       'start_date': '2020-01-01',
///       'current': true,
///       'achievements': ['Built features', 'Improved performance'],
///     }
///   ],
///   skills: [
///     {'name': 'Python', 'category': 'technical'},
///     {'name': 'FastAPI', 'category': 'technical'},
///   ],
/// );
/// 
/// print(result['resume_data']);
/// print('ATS Score: ${result['ats_score']}');
/// print('Suggestions: ${result['suggestions']}');
/// ```
