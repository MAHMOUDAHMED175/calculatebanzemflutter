import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:metro/presentation/screens/some_location.dart'; // مكتبة geocoding

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  List<TextEditingController> addressFields = [];
  TextEditingController addText = TextEditingController();
  AnimationController? _animationController;
  Animation<double>? _animation;
  List<Map<String, double>> locations = []; // قائمة لتخزين الإحداثيات

  @override
  void initState() {
    super.initState();
    _getLocation();
    addressFields.add(addText);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(microseconds: 400),
    );
    _animation = Tween<double>(begin: 0, end: 20)
        .chain(CurveTween(curve: Curves.slowMiddle))
        .animate(_animationController!)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _animationController!.reverse();
        }
      });
  }

  @override
  void dispose() {
    _animationController!.dispose();
    super.dispose();
  }

  bool checkDuplicateAndShake() {
    Set<String> addressSet = {};
    bool? haveDuplicate; // للتحقق من وجود حقل فارغ أو عنوان مكرر

    for (var controller in addressFields) {
      String address = controller.text.trim();

      // تحقق من إذا كان الحقل فارغًا
      if (address.isEmpty) {
        haveDuplicate = true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('One or more fields are empty')),
        );
      } else if (!addressSet.add(address)) {
        haveDuplicate = true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Duplicate address found: $address')),
        );
        // خروج من الحلقة عند اكتشاف عنوان مكرر
      } else {
        haveDuplicate = false;
      }
    }
    print(haveDuplicate);
    return haveDuplicate!; // إذا كانت هناك مشكلة (فارغ أو مكرر)، سيتم إرجاع true
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<void> _getCoordinatesFromAddress(String address) async {
    try {
      List<Location> locationsList = await locationFromAddress(address);

      if (locationsList.isNotEmpty) {
        Location location = locationsList.first;
        setState(() {
          locations.add({
            'latitude': location.latitude,
            'longitude': location.longitude,
          });
        });

        print(
            "Coordinates: Latitude ${location.latitude}, Longitude ${location.longitude}");
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  Future<void> _getLocation() async {
    try {
      Position position = await _determinePosition();

      // تحويل الإحداثيات إلى عنوان باستخدام geocoding
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      Placemark place = placemarks[0];

      // تجميع العنوان
      String address =
          "${place.subThoroughfare ?? ''} ${place.thoroughfare ?? ''}، ${place.administrativeArea ?? ''}، ${place.locality ?? ''}، ${place.country ?? ''}";

// إزالة المسافات الزائدة
      address = address.replaceAll(RegExp(r'\s+'), ' ').trim();

// طباعة العنوان
      print(address);
      setState(() {
        addressFields[0].text = address; // وضع العنوان في الحقل الأول
      });
    } catch (e) {
      print("Error: $e");
    }
  }

  void addLocationField() async {
    if (checkDuplicateAndShake() == false) {
      if (addressFields.isNotEmpty) {
        String address = addressFields.last.text.trim();
        if (address.isNotEmpty) {
          await _getCoordinatesFromAddress(
              address); // تحويل العنوان إلى إحداثيات
        }
      }
      setState(() {
        TextEditingController newController = TextEditingController();
        addressFields.add(newController);
      });
    } // إذا كان كل شيء صحيحًا، قم بتشغيل الرسوم المتحركة
    else {
      _animationController?.forward(); // Trigger shake animation
    }
  }

  void removeLastField() {
    if (addressFields.length > 1) {
      setState(() {
        addressFields.removeLast();
        if (locations.isNotEmpty) {
          locations.removeLast(); // حذف الإحداثيات الأخيرة
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot remove the last field!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Example'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: addressFields.length,
                itemBuilder: (context, index) {
                  return AnimatedBuilder(
                    animation: _animationController ??
                        AnimationController(
                          vsync: this,
                          duration: const Duration(microseconds: 400),
                        ),
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(_animation!.value, 0),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: TextField(
                            controller: addressFields[index],
                            decoration: const InputDecoration(
                              labelText: 'Enter address',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: addLocationField,
                child: const Text('Add new Location'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SomeLocations(locations: locations),
                    ),
                  );
                  print(locations.toString());
                },
                child: const Text('Calculate Banzem'),
              ),
              ElevatedButton(
                onPressed: removeLastField,
                child: const Text('Remove Last Location'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
