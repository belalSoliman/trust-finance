import 'package:flutter/material.dart';
import 'package:trust_finiance/utils/navigation/routes.dart';

class FloatingBtn extends StatefulWidget {
  const FloatingBtn({super.key});

  @override
  State<FloatingBtn> createState() => _FloatingBtnState();
}

class _FloatingBtnState extends State<FloatingBtn>
    with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  late AnimationController _animationController;
  final List<Map<String, dynamic>> _menuItems = [
    {
      'title': 'Add Customer',
      'icon': Icons.person_add,
      'color': const Color(0xFFFF8DA1), // Primary pink
    },
    {
      'title': 'Add Payment',
      'icon': Icons.payment,
      'color': const Color.fromARGB(255, 240, 177, 193), // Secondary pink
    },
    {
      'title': 'Add Invoice',
      'icon': Icons.receipt,
      'color': const Color(0xFFE5C1CD), // Dusty rose
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
  }

  void _initializeAnimation() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _animationController.forward();
      } else {
        _animationController.reverse().then((_) {
          if (!mounted) return;
          setState(() {}); // Trigger rebuild after animation completes
        });
      }
    });
  }

  void _handleNavigation(String title, BuildContext context) {
    _toggleMenu(); // Close menu first
    Future.delayed(const Duration(milliseconds: 300), () {
      // Wait for menu animation to complete
      if (!mounted) return;
      switch (title) {
        case 'Add Customer':
          print('Add Customer');
          Navigator.pushNamed(context, Routes.addCustomer);
          break;
        case 'Add Payment':
          print('Add Payment');
          Navigator.pushNamed(context, Routes.addPayment);
          break;
        case 'Add Invoice':
          print('Add Invoice');
          Navigator.pushNamed(context, Routes.createInovice);
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 16),
      child: SizedBox(
        width: 200,
        height: _isOpen ? 240 : 56,
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            // Menu Items
            if (_isOpen) // Only build menu items when menu is open
              ..._menuItems.asMap().entries.map((entry) {
                int index = entry.key;
                Map<String, dynamic> item = entry.value;
                return AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  right: 0,
                  bottom: (index + 1) * 65.0,
                  child: AnimatedOpacity(
                    opacity: _isOpen ? 1 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _handleNavigation(item['title'], context),
                        borderRadius: BorderRadius.circular(30),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: item['color'],
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(item['icon'], color: Colors.white),
                              const SizedBox(width: 8),
                              Text(
                                item['title'],
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),

            // Main Button
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: _isOpen ? 8 : 4,
                    offset: Offset(0, _isOpen ? 4 : 2),
                  ),
                ],
              ),
              child: FloatingActionButton(
                onPressed: _toggleMenu,
                backgroundColor: Theme.of(context).colorScheme.primary,
                elevation: 0,
                child: AnimatedRotation(
                  turns: _isOpen ? 0.125 : 0,
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    _isOpen ? Icons.close : Icons.add,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
