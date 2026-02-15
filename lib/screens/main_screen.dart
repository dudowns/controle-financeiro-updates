import 'package:flutter/material.dart';
import 'dashboard.dart';
import 'lancamentos.dart';
import 'investimentos_tabs.dart';
import 'metas_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(), // ← CORRIGIDO!
    const LancamentosScreen(), // ← OK
    const InvestimentosTabsScreen(), // ← CORRIGIDO!
    const MetasScreen(), // ← OK
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Controle Financeiro'),
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt), label: 'Gastos'),
          BottomNavigationBarItem(
              icon: Icon(Icons.show_chart), label: 'Invest'),
          BottomNavigationBarItem(icon: Icon(Icons.flag), label: 'Metas'),
        ],
      ),
    );
  }
}
