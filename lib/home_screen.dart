import 'package:flutter/material.dart';
import './screens/journey/dashboard_screen.dart';
// Imports corretos das telas (mesmo nível de pasta)
import './home_screen.dart';
import './screens/journey/journey_screen.dart';

// Import da tela de corrida (dentro da subpasta run)
import './screens/run/RunTrackingScreen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // Lista simples e padronizada das páginas
  final List<Widget> _pages = [
    const DashboardScreen(),
    const RunTrackingScreen(), // Colocamos o GPS no meio
    const JourneyScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D12),
      
      // Corpo da tela usando IndexedStack para manter o estado das abas
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      
      // NavigationBar Padrão do Flutter (Seguro, não quebra o layout)
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1A1A24),
        selectedItemColor: const Color(0xFF9C27B0),
        unselectedItemColor: Colors.grey.shade600,
        type: BottomNavigationBarType.fixed, // Impede animações estranhas nas abas
        elevation: 10,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: "Visão Geral",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_run),
            label: "Corrida GPS",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: "Jornada",
          ),
        ],
      ),
    );
  }
}