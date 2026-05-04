import 'package:equatable/equatable.dart';

class ProductModel {
  final int id;
  final String name;
  final double price;
  final String category;
  final String imageUrl;

  ProductModel({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.imageUrl,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
  return ProductModel(
    id: json['ID'],
    name: json['name'],
    price: (json['price'] as num).toDouble(),
    category: json['category'],
    imageUrl: json['image_url'],
  );
}
}
