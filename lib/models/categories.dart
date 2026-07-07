import 'package:flutter/material.dart';

class CategoryItem {
  final String name;
  final IconData icon;
  final Color color;

  const CategoryItem({
    required this.name,
    required this.icon,
    required this.color,
  });
}

const List<CategoryItem> expenseCategories = [
  CategoryItem(name: 'Shopping', icon: Icons.shopping_bag_outlined, color: Color(0xFFE91E63)),
  CategoryItem(name: 'Grocery', icon: Icons.shopping_cart_outlined, color: Color(0xFF4CAF50)),
  CategoryItem(name: 'Fuel', icon: Icons.local_gas_station_outlined, color: Color(0xFFFF9800)),
  CategoryItem(name: 'Medical', icon: Icons.medical_services_outlined, color: Color(0xFFF44336)),
  CategoryItem(name: 'Food', icon: Icons.restaurant_outlined, color: Color(0xFFFF5722)),
  CategoryItem(name: 'Office', icon: Icons.work_outline, color: Color(0xFF2196F3)),
  CategoryItem(name: 'Courier', icon: Icons.local_shipping_outlined, color: Color(0xFF795548)),
  CategoryItem(name: 'Recharge', icon: Icons.bolt_outlined, color: Color(0xFF00BCD4)),
  CategoryItem(name: 'Other', icon: Icons.more_horiz_outlined, color: Color(0xFF607D8B)),
];
