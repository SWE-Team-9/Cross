// ─────────────────────────────────────────────────────────────────────────────

//  bottom_nav_bar.dart  —  Shared Bottom Navigation Bar with Temporary Blob Animation

//  Used by: HomePage, FeedPage (and any future screen)

// ─────────────────────────────────────────────────────────────────────────────



import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';



class BottomNavBar extends StatelessWidget {

  static const double minHeight = 58;



  final int selected;

  final ValueChanged<int>? onTap; // optional — uses default routing if null



  const BottomNavBar({

    super.key,

    required this.selected,

    this.onTap,

  });



  static const _items = [

    _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home'),

    _NavItem(

        icon: Icons.grid_view_outlined,

        activeIcon: Icons.grid_view,

        label: 'Feed'),

    _NavItem(icon: Icons.search, activeIcon: Icons.search, label: 'Search'),

    _NavItem(

        icon: Icons.library_music_outlined,

        activeIcon: Icons.library_music,

        label: 'Library'),

    _NavItem(

        icon: Icons.equalizer_outlined,

        activeIcon: Icons.equalizer,

        label: 'Upgrade'),

  ];



  static const _routes = ['/home', '/feed', '/search', '/library', '/upgrade'];



  void _handleTap(BuildContext context, int index) {

    if (onTap != null) {

      onTap!(index);

      return;

    }

    // Default: navigate via go_router

    if (index < _routes.length) {

      context.go(_routes[index]);

    }

  }



  @override

  Widget build(BuildContext context) {

    return Container(

      constraints: const BoxConstraints(minHeight: minHeight),

      decoration: const BoxDecoration(

        color: Colors.black,

        border: Border(top: BorderSide(color: Color(0xFF1F1F1F))),

      ),

      child: SafeArea(

        top: false,

        child: Row(

          children: List.generate(

            _items.length,

            (i) => Expanded(

              child: _NavItemButton(

                item: _items[i],

                isSelected: selected == i,

                onTap: () => _handleTap(context, i),

              ),

            ),

          ),

        ),

      ),

    );

  }

}



class _NavItem {

  final IconData icon, activeIcon;

  final String label;

  const _NavItem({

    required this.icon,

    required this.activeIcon,

    required this.label,

  });

}



/// A stateful item button handling the transient blob animation.

class _NavItemButton extends StatefulWidget {

  final _NavItem item;

  final bool isSelected;

  final VoidCallback onTap;



  const _NavItemButton({

    required this.item,

    required this.isSelected,

    required this.onTap,

  });



  @override

  State<_NavItemButton> createState() => _NavItemButtonState();

}



class _NavItemButtonState extends State<_NavItemButton> with SingleTickerProviderStateMixin {

  late AnimationController _animationController;

  late Animation<double> _scaleAnimation;

  late Animation<double> _opacityAnimation;



  @override

  void initState() {

    super.initState();

    _animationController = AnimationController(

      vsync: this,

      duration: const Duration(milliseconds: 300),

    );



    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(

      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),

    );



    _opacityAnimation = Tween<double>(begin: 0.15, end: 0.0).animate(

      CurvedAnimation(parent: _animationController, curve: Curves.easeInQuad),

    );

  }



  @override

  void dispose() {

    _animationController.dispose();

    super.dispose();

  }



  void _onTap() {

    // 1. Instantly restart and play the animation

    _animationController.forward(from: 0.0);



    // 2. Wait for the 300ms animation to complete before triggering navigation

    Future.delayed(const Duration(milliseconds: 300), () {

      if (mounted) {

        widget.onTap();

      }

    });

  }



  @override

  Widget build(BuildContext context) {

    return GestureDetector(

      onTap: _onTap,

      behavior: HitTestBehavior.opaque,

      child: Stack(

        alignment: Alignment.center,

        children: [

          // Positioned behind the text & icon inside the stack

          AnimatedBuilder(

            animation: _animationController,

            builder: (context, child) {

              // Strictly temporary: completely invisible and unrendered if animation isn't running

              if (_animationController.value == 0.0 || _animationController.isCompleted) {

                return const SizedBox.shrink();

              }

              return Opacity(

                opacity: _opacityAnimation.value,

                child: Transform.scale(

                  scale: _scaleAnimation.value,

                  child: Container(

                    width: 64,

                    height: 64,

                    decoration: const BoxDecoration(

                      color: Colors.white,

                      shape: BoxShape.circle,

                    ),

                  ),

                ),

              );

            },

          ),

         

          // Navigation Item UI

          Padding(

            padding: const EdgeInsets.symmetric(vertical: 12),

            child: Column(

              mainAxisSize: MainAxisSize.min,

              children: [

                Icon(

                  widget.isSelected ? widget.item.activeIcon : widget.item.icon,

                  color: widget.isSelected ? Colors.white : const Color(0xFF555555),

                  size: 23,

                ),

                const SizedBox(height: 3),

                Text(

                  widget.item.label,

                  style: TextStyle(

                    color: widget.isSelected ? Colors.white : const Color(0xFF555555),

                    fontSize: 12,

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