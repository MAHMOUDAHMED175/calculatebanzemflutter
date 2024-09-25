import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart'; // تأكد من أنك قمت بإضافة مكتبة geocoding في pubspec.yaml
import 'dart:math';

// لحساب المسافة باستخدام معادلة Haversine
double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
  const R = 6371; // نصف قطر الأرض بالكيلومترات
  double latDistance = (lat2 - lat1) * pi / 180.0;
  double lonDistance = (lon2 - lon1) * pi / 180.0;

  double a = sin(latDistance / 2) * sin(latDistance / 2) +
      cos(lat1 * pi / 180) *
          cos(lat2 * pi / 180) *
          sin(lonDistance / 2) *
          sin(lonDistance / 2);
  double c = 2 * atan2(sqrt(a), sqrt(1 - a));

  return R * c; // المسافة بالكيلومترات
}

// كلاس لتخزين معلومات المسافة
class DistanceInfo {
  final int fromIndex;
  final int toIndex;
  final double distance;

  DistanceInfo(this.fromIndex, this.toIndex, this.distance);
}

// لحساب المسافات بين جميع النقاط
List<DistanceInfo> calculateDistances(List<List<double>> locations) {
  List<DistanceInfo> distanceInfos = [];
  for (int i = 0; i < locations.length; i++) {
    for (int j = i + 1; j < locations.length; j++) {
      double distance = calculateDistance(
          locations[i][0], locations[i][1], locations[j][0], locations[j][1]);
      distanceInfos.add(DistanceInfo(i, j, distance));
    }
  }
  return distanceInfos;
}

// البحث عن أقصر مسار يزور جميع النقاط
List<int> findPath(List<List<double>> locations) {
  List<DistanceInfo> distances = calculateDistances(locations);
  List<int> path = [0]; // بداية المسار من النقطة الأولى
  List<bool> visited = List.filled(locations.length, false);
  visited[0] = true;

  int currentIndex = 0;
  while (path.length < locations.length) {
    int nextIndex = -1;
    double minDistance = double.infinity;

    for (var info in distances) {
      if (info.fromIndex == currentIndex &&
          !visited[info.toIndex] &&
          info.distance < minDistance) {
        nextIndex = info.toIndex;
        minDistance = info.distance;
      }
    }

    if (nextIndex != -1) {
      path.add(nextIndex);
      visited[nextIndex] = true;
      currentIndex = nextIndex;
    } else {
      for (int i = 0; i < visited.length; i++) {
        if (!visited[i]) {
          path.add(i);
          visited[i] = true;
          currentIndex = i;
          break;
        }
      }
    }
  }

  return path;
}

// دالة لتحويل النقاط إلى عناوين
Future<List<String>> convertPointToAddress(List<List<double>> locations) async {
  List<String> addresses = [];

  for (int i = 0; i < locations.length; i++) {
    List<Placemark> placemarks = await placemarkFromCoordinates(
      locations[i][0], // latitude
      locations[i][1], // longitude
    );

    if (placemarks.isNotEmpty) {
      Placemark place = placemarks[0];

      // تجميع العنوان
      String address =
          "${place.subThoroughfare ?? ''} ${place.thoroughfare ?? ''}، ${place.locality ?? ''}، ${place.administrativeArea ?? ''}، ${place.country ?? ''}";

      // إزالة المسافات الزائدة
      address = address.replaceAll(RegExp(r'\s+'), ' ').trim();
      addresses.add(address);
    } else {
      addresses.add('عنوان غير متوفر');
    }
  }

  return addresses;
}

// واجهة المستخدم لعرض المسار
class BestRouteScreen extends StatelessWidget {
  final List<Map<String, double>> locations;

  BestRouteScreen({required this.locations});

  @override
  Widget build(BuildContext context) {
    // تحويل القائمة من {latitude, longitude} إلى قائمة من List<double>
    List<List<double>> formattedLocations = locations.map((loc) {
      return [loc['latitude']!, loc['longitude']!];
    }).toList();

    List<int> path = findPath(formattedLocations);

    return FutureBuilder<List<String>>(
      future: convertPointToAddress(
          formattedLocations), // تحويل الإحداثيات إلى عناوين
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('خطأ: ${snapshot.error}'));
        } else {
          List<String> stringPath = snapshot.data ?? [];

          return Scaffold(
            appBar: AppBar(
              title: const Text('أفضل مسار'),
              backgroundColor: Colors.deepPurpleAccent,
            ),
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text('المسار الأفضل:', style: TextStyle(fontSize: 20)),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: path.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(
                            'النقطة ${path[index] + 1}: ${stringPath[path[index]]}', // عرض العنوان بدلاً من الإحداثيات
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }
}
