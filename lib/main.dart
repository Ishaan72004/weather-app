import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Poppins',
      ),
      home: const WeatherScreen(),
    );
  }
}

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen>
    with SingleTickerProviderStateMixin {
  final String apiKey = "7415ec41322d4f87b64164154252708"; // Replace with your WeatherAPI key
  final TextEditingController _searchController = TextEditingController();

  Map<String, dynamic>? _weatherData;
  bool _isLoading = false;
  String _errorMessage = "";
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));

    // Fetch weather for default city
    _fetchWeatherData("London");
  }

  Future<void> _fetchWeatherData(String cityName) async {
    setState(() {
      _isLoading = true;
      _errorMessage = "";
      _animationController.reset();
    });

    try {
      final response = await http.get(
        Uri.parse(
            'http://api.weatherapi.com/v1/current.json?key=$apiKey&q=$cityName&aqi=no'),
      );

      if (response.statusCode == 200) {
        setState(() {
          _weatherData = json.decode(response.body);
          _isLoading = false;
        });
        _animationController.forward();
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = "City not found. Please try again.";
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Connection error. Please check your internet.";
      });
    }
  }

  String _getWeatherIcon(int conditionCode) {
    // WeatherAPI condition codes: https://www.weatherapi.com/docs/weather_conditions.json
    if (conditionCode == 1000) {
      return "☀️"; // Sunny/Clear
    } else if (conditionCode > 1000 && conditionCode <= 1030) {
      return "☁️"; // Cloudy
    } else if (conditionCode >= 1063 && conditionCode <= 1072 ||
        conditionCode >= 1150 && conditionCode <= 1183) {
      return "🌦️"; // Light rain
    } else if (conditionCode >= 1066 && conditionCode <= 1069 ||
        conditionCode >= 1114 && conditionCode <= 1117 ||
        conditionCode >= 1204 && conditionCode <= 1276) {
      return "❄️"; // Snow
    } else if (conditionCode == 1087 ||
        conditionCode >= 1273 && conditionCode <= 1276) {
      return "⛈️"; // Thunderstorm
    } else if (conditionCode >= 1189 && conditionCode <= 1201) {
      return "🌧️"; // Rain
    } else if (conditionCode >= 1135 && conditionCode <= 1147) {
      return "🌫️"; // Fog/Mist
    } else {
      return "🌡️"; // Default
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _getBackgroundGradient(),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Search bar
                _buildSearchBar(),
                const SizedBox(height: 20),

                // Main content
                Expanded(
                  child: _isLoading
                      ? _buildLoadingIndicator()
                      : _errorMessage.isNotEmpty
                      ? _buildErrorWidget()
                      : _buildWeatherInfo(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: "Search city...",
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                hintStyle: TextStyle(color: Colors.white70),
              ),
              style: const TextStyle(color: Colors.white),
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  _fetchWeatherData(value);
                }
              },
            ),
          ),
          IconButton(
            icon: const Icon(Iconsax.search_normal, color: Colors.white),
            onPressed: () {
              if (_searchController.text.isNotEmpty) {
                _fetchWeatherData(_searchController.text);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SpinKitDoubleBounce(
            color: Colors.white.withOpacity(0.8),
            size: 50.0,
          ),
          const SizedBox(height: 20),
          const Text(
            "Loading weather data...",
            style: TextStyle(color: Colors.white, fontSize: 16),
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
          const Icon(Icons.error_outline, color: Colors.white, size: 50),
          const SizedBox(height: 16),
          Text(
            _errorMessage,
            style: const TextStyle(color: Colors.white, fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => _fetchWeatherData("London"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
            ),
            child: const Text(
              "Try Again",
              style: TextStyle(color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherInfo() {
    if (_weatherData == null) {
      return Container();
    }

    final location = _weatherData!['location'];
    final current = _weatherData!['current'];

    final cityName = location['name'];
    final country = location['country'];
    final temperature = current['temp_c'].round();
    final condition = current['condition']['text'];
    final conditionCode = current['condition']['code'];
    final humidity = current['humidity'];
    final windSpeed = current['wind_kph'];
    final feelsLike = current['feelslike_c'].round();

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          children: [
            // Location
            Text(
              '$cityName, $country',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),

            // Date
            Text(
              _getFormattedDate(),
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 30),

            // Weather icon and temperature
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getWeatherIcon(conditionCode),
                  style: const TextStyle(fontSize: 80),
                ),
                const SizedBox(width: 10),
                Text(
                  '$temperature°',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 64,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Weather condition
            Text(
              condition,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 30),

            // Feels like
            Text(
              'Feels like $feelsLike°',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 40),

            // Additional info
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildInfoItem("Humidity", '$humidity%', Iconsax.drop),
                  _buildInfoItem("Wind", '${windSpeed.toStringAsFixed(1)} km/h', Iconsax.wind),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 5),
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    final days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    return '${days[now.weekday]}, ${now.day} ${months[now.month - 1]}';
  }

  List<Color> _getBackgroundGradient() {
    if (_weatherData == null) {
      return [Colors.blue.shade400, Colors.blue.shade700];
    }

    final current = _weatherData!['current'];
    final conditionCode = current['condition']['code'];

    // Determine gradient based on weather condition code
    if (conditionCode == 1000) {
      return [Colors.orange.shade300, Colors.orange.shade600]; // Sunny
    } else if (conditionCode > 1000 && conditionCode <= 1030) {
      return [Colors.blueGrey.shade400, Colors.blueGrey.shade700]; // Cloudy
    } else if (conditionCode >= 1063 && conditionCode <= 1195) {
      return [Colors.indigo.shade400, Colors.indigo.shade700]; // Rain
    } else if (conditionCode >= 1066 && conditionCode <= 1276) {
      return [Colors.cyan.shade300, Colors.cyan.shade600]; // Snow
    } else if (conditionCode == 1087 || conditionCode >= 1273) {
      return [Colors.purple.shade400, Colors.purple.shade700]; // Thunderstorm
    } else {
      return [Colors.blue.shade400, Colors.blue.shade700]; // Default
    }
  }
}