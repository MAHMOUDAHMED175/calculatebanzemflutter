import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:metro/presentation/screens/best_route.dart';

class SomeLocations extends StatelessWidget {
  final List<Map<String, double>> locations; // قائمة لتخزين الإحداثيات

  SomeLocations({Key? key, required this.locations}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Some Locations'),
      ),
      body: FutureBuilder(
        future: calculateDistancesAndCosts(locations),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final data = snapshot.data as Map<String, dynamic>;
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.grey.withOpacity(0.2),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Text(
                        textAlign: TextAlign.center,
                        "سيارات صغيرة: حوالي 5-8 لترات لكل 100 كيلومتر. \nسيارات متوسطة الحجم: حوالي 7-10 لترات لكل 100 كيلومتر.\n سيارات كبيرة: حوالي 10-15 لترات لكل 100 كيلومتر. \nسيارات الدفع الرباعي: حوالي 12-20 لترات لكل 100 كيلومتر. \nسيارات هجينة: حوالي 3-6 لترات لكل 100 كيلومتر.",
                        style: const TextStyle(fontSize: 15),
                      ),
                      Container(
                        width: double.infinity,
                        height: 1,
                        color: Colors.deepPurple,
                      ),
                      Spacer(),
                      Text(
                        'مجموع المسافات بالكيلومترات: ${data['totalDistance'].toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 15),
                      ),
                      Container(
                        width: double.infinity,
                        height: 1,
                        color: Colors.deepPurple,
                      ),
                      Text(
                        'عدد اللترات المطلوبة: ${data['litres'].toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 20),
                      ),
                      Container(
                        width: double.infinity,
                        height: 1,
                        color: Colors.deepPurple,
                      ),
                      Text(
                        'المبلغ المطلوب: ${data['price'].toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 20),
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        BestRouteScreen(locations: locations)));
                          },
                          label: Text("Best Route"),
                          icon: Icon(
                            Icons.arrow_circle_left,
                            color: Colors.deepPurple,
                          ))
                    ],
                  ),
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Future<Map<String, double>> calculateDistancesAndCosts(
      List<Map<String, double>> ListLocations) async {
    double totalDistance = 0;
    for (int i = 0; i < ListLocations.length - 1; i++) {
      final loc1 = ListLocations[i];
      final loc2 = ListLocations[i + 1];

      print('loc1: ${loc1['latitude']}, ${loc1['longitude']}');
      print('loc2: ${loc2['latitude']}, ${loc2['longitude']}');

      double distance = Geolocator.distanceBetween(
        loc1['latitude']!,
        loc1['longitude']!,
        loc2['latitude']!,
        loc2['longitude']!,
      );

      print('Distance between points: $distance meters');

      totalDistance += distance / 1000; // تحويل المسافة إلى كيلومترات
    }

    double litres = totalDistance / 10;
    double price = litres * 13;

    print('Total distance: $totalDistance km');
    print('Litres needed: $litres');
    print('Total price: $price');

    return {
      'totalDistance': totalDistance,
      'litres': litres,
      'price': price,
    };
  }
}
