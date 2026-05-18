import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'categories.dart';


void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const HypenApp());
}

class HypenApp extends StatelessWidget {
  const HypenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HYPEN',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const OnboardingScreen(),
    );
  }
}


//  Slide data model

class SlideData {
  final Color color;
  final String category;
  final String headline;
  final String imagePath;

  const SlideData({
    required this.color,
    required this.category,
    required this.headline,
    required this.imagePath,
  });
}

const List<SlideData> _slides = [
  SlideData(
    color: Color.fromARGB(0, 0, 0, 0), 
    category: 'FASHION',
    headline: 'Make Your\nStyle',
    imagePath: 'assets/images/slide1.png',
  ),
  SlideData(
    color: Color.fromARGB(255, 44, 62, 80), // dark navy
    category: 'STREET',
    headline: 'Make Your\nStyle',
    imagePath: 'assets/images/slide2.jpg',
  ),
  SlideData(
    color: Color.fromARGB(255, 26, 26, 26), // near-black
    category: 'LUXURY',
    headline: 'Make Your\nStyle',
    imagePath: 'assets/images/slide3.jpg',
  ),
];


class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {

  int _currentIndex = 0;
  Timer? _timer;

  
  late final AnimationController _textCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );

  // Derived animations from the single controller
  late final Animation<double> _textFade = _textCtrl;
  late final Animation<Offset> _textSlide = Tween<Offset>(
    begin: const Offset(0, 0.06),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut));

  @override
  void initState() {
    super.initState();
    _textCtrl.forward();
    
    _timer = Timer.periodic(const Duration(seconds: 6), (_) => _next());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _textCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (!mounted) return;
    setState(() {
      _currentIndex = (_currentIndex + 1) % _slides.length;
    });
    // Reset and replay the text entrance animation
    _textCtrl
      // ..reset()
      ..forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_currentIndex];

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [

          // ── Background carousel ──────────────────────────
          
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 700),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: child,
            ),
            child: Container(
              // ValueKey tells AnimatedSwitcher "this is a new slide"
              key: ValueKey(_currentIndex),
              color: slide.color,
              
              child: Image.asset(
                slide.imagePath,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),

          // ── Bottom dark gradient — keeps text legible ────
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.45, 1.0],
                colors: [Colors.transparent, Colors.black87],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [

                // Brand name
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Text(
                    'HYPEN.',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: Colors.white,
                    ),
                  ),
                ),

                const Spacer(),

                // Animated headline text
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: FadeTransition(
                    opacity: _textFade,
                    child: SlideTransition(
                      position: _textSlide,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            slide.category,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 2.5,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            slide.headline,
                            style: const TextStyle(
                              fontSize: 70,
                              fontWeight: FontWeight.w900,
                              height: 1.0,
                              letterSpacing: -1.0,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // Dot indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_slides.length, (i) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _currentIndex ? 22 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: i == _currentIndex
                            ? Colors.white
                            : Colors.white38,
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 28),

                // Skip / Discover row
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [

                      TextButton(
                        onPressed: () => debugPrint('Skip tapped'),
                        child: const Text(
                          'Skip',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white60,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                     ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CategoriesScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                          label: const Text(
                            'Discover',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          icon: const Icon(Icons.arrow_outward, size: 17),
                          iconAlignment: IconAlignment.end,
                        ),

                    ],
                  ),
                ),

              ],
            ),
          ),

        ],
      ),
    );
  }
}

