import 'package:flutter/material.dart';
import 'package:travel_companion_app/models/monument.dart';
import 'package:travel_companion_app/widgets/destination_card_for_recommendation_page.dart';
import 'package:travel_companion_app/services/monument_service.dart';
import 'package:flutter/cupertino.dart';

class AllMonumentsScreen extends StatefulWidget {
  final String title;
  final String? categoryFilter;

  const AllMonumentsScreen({
    super.key,
    required this.title,
    this.categoryFilter,
  });

  @override
  State<AllMonumentsScreen> createState() => _AllMonumentsScreenState();
}

class _AllMonumentsScreenState extends State<AllMonumentsScreen> {
  List<Monument> monuments = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchAllMonuments();
  }

  Future<void> _fetchAllMonuments() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });

      final fetchedMonuments = await MonumentService.getAllMonuments();

      // Apply category filter if specified
      // List<Monument> filteredMonuments = fetchedMonuments;
      // if (widget.categoryFilter != null) {
      //   String filterType = '';

      //   // Map category names to type values in the API
      //   switch (widget.categoryFilter) {
      //     case 'Temples':
      //       filterType = 'Temple';
      //       break;
      //     case 'Stupas':
      //       filterType = 'Stupa';
      //       break;
      //     case 'Monuments':
      //       filterType = 'Monument';
      //       break;
      //     default:
      //       // No filtering
      //       break;
      //   }

      //   if (filterType.isNotEmpty) {
      //     filteredMonuments = fetchedMonuments
      //         .where((monument) => monument.type.contains(filterType))
      //         .toList();
      //   }
      // }

      setState(() {
        monuments = fetchedMonuments;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error fetching monuments: $e';
      });
      print('Error in _fetchAllMonuments: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All',
            style: TextStyle(
              fontWeight: FontWeight.bold, // Make text bold
            )),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        errorMessage,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.red,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _fetchAllMonuments,
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                )
              : monuments.isEmpty
                  ? const Center(
                      child: Text(
                        'No monuments available',
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 1,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1 / 1.1,
                        ),
                        itemCount: monuments.length,
                        itemBuilder: (context, index) {
                          return RecommendationCard(
                            monument: monuments[index],
                            onTap: () {
                              // Add navigation to detail page if needed
                            },
                          );
                        },
                      ),
                    ),
    );
  }
}
