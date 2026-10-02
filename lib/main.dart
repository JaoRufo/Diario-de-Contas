import 'package:flutter/material.dart';
import 'package:diario_de_contas/providers/expenses_provider.dart';
import 'package:diario_de_contas/screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final provider = ExpensesProvider();
  runApp(DiarioDeContasApp(provider: provider));
}

class DiarioDeContasApp extends StatelessWidget {
  const DiarioDeContasApp({super.key, required this.provider});
  final ExpensesProvider provider;

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Diário de Contas',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: const ColorScheme.light(
            primary: Color(0xFFB88632),
            onPrimary: Color(0xFF17130D),
            secondary: Color(0xFF2B2720),
            onSecondary: Colors.white,
            surface: Color(0xFFFFFCF7),
            onSurface: Color(0xFF17130D),
            surfaceContainerHighest: Color(0xFFF1ECE3),
          ),
          scaffoldBackgroundColor: const Color(0xFFF7F4EE),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFFF7F4EE),
            surfaceTintColor: Colors.transparent,
            foregroundColor: Color(0xFF17130D),
            elevation: 0,
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFFFFFCF7),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE5DED1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE5DED1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: Color(0xFFB88632), width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          ),
          cardTheme: CardThemeData(
            color: const Color(0xFFFFFCF7),
            elevation: 0,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Color(0xFFEDE5D8)),
            ),
          ),
          dividerTheme: const DividerThemeData(color: Color(0xFFE9E1D4)),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF17130D),
              foregroundColor: const Color(0xFFFFD98A),
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          floatingActionButtonTheme: FloatingActionButtonThemeData(
            backgroundColor: const Color(0xFF17130D),
            foregroundColor: const Color(0xFFFFD98A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        home: _SplashScreen(provider: provider),
      );
}

class _SplashScreen extends StatefulWidget {
  const _SplashScreen({required this.provider});

  final ExpensesProvider provider;

  @override
  State<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen>
    with SingleTickerProviderStateMixin {
  late final Future<void> _loading;
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _loading = Future.wait<void>([
      widget.provider.load(),
      Future<void>.delayed(const Duration(milliseconds: 900)),
    ]).then((_) {});
    _loading.then((_) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => HomeScreen(provider: widget.provider),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4EE),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: Tween<double>(begin: 0.94, end: 1.0).animate(
                CurvedAnimation(
                  parent: _animationController,
                  curve: Curves.easeInOut,
                ),
              ),
              child: Image.asset(
                'lib/imgs/logo-diario-contas.png',
                width: 210,
                height: 150,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Organize suas contas e cuide melhor\ndo seu dinheiro.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF2B2720),
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
            ),
            const SizedBox(height: 28),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Color(0xFFB88632),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
