import 'package:flutter/material.dart';
import 'package:travel_companion_app/models/monument.dart'; // Update with your actual path
import 'package:travel_companion_app/services/recommendation_service.dart'; // Update with your actual path
import 'package:travel_companion_app/widgets/destination_card_for_recommendation_page.dart';

class RecommendationScreen extends StatefulWidget {
  const RecommendationScreen({super.key});

  @override
  State<RecommendationScreen> createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen> {
  bool isLoading = true;
  List<Monument> recommendations = [];
  String? errorMessage;
  @override
  void initState() {
    super.initState();
    _fetchRecommendations();
  }

  Future<void> _fetchRecommendations({String? prompt}) async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final monuments =
          await RecommendationService.getRecommendations(prompt: prompt);
      setState(() {
        recommendations = monuments;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recommended Places',
            style: TextStyle(
              fontWeight: FontWeight.bold, // Make text bold
            )),
        backgroundColor: const Color.fromARGB(255, 148, 20, 1),
        foregroundColor: const Color.fromARGB(255, 255, 255, 255),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Content
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : errorMessage != null
                    ? _buildErrorWidget()
                    : recommendations.isEmpty
                        ? const Center(
                            child: Text('No recommendations found'),
                          )
                        : Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: ListView.builder(
                              itemCount: recommendations.length,
                              itemBuilder: (context, index) {
                                final monument = recommendations[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16.0),
                                  child: _buildDestinationCard(monument),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 60,
          ),
          const SizedBox(height: 16),
          const Text(
            'Error loading recommendations',
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            errorMessage!,
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _fetchRecommendations(),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildDestinationCard(Monument monument) {
    return RecommendationCard(
      monument: monument,
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Selected: ${monument.name}')),
        );
      },
    );
  }
}
