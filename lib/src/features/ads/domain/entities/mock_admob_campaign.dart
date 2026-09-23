import 'package:flutter/material.dart';

/// Represents a simulated creative advertisement campaign delivered via AdMob.
class MockAdmobCampaign {
  final String id;
  final String sponsorName;
  final String title;
  final String description;
  final String ctaText;
  final IconData icon;
  final Color primaryColor;
  final double rating;
  final String reviewsCount;
  final String targetUrl;

  const MockAdmobCampaign({
    required this.id,
    required this.sponsorName,
    required this.title,
    required this.description,
    required this.ctaText,
    required this.icon,
    required this.primaryColor,
    required this.rating,
    required this.reviewsCount,
    this.targetUrl = 'https://google.com/admob',
  });

  static const List<MockAdmobCampaign> sampleCampaigns = [
    MockAdmobCampaign(
      id: 'camp_supermarket',
      sponsorName: 'MercadoFresh',
      title: 'Descuento del 25% en frutas y verduras',
      description:
          'Haz tu pedido hoy y recibe tus compras en menos de 45 minutos. Envío gratis en tu primera orden.',
      ctaText: 'Comprar ahora',
      icon: Icons.local_grocery_store_rounded,
      primaryColor: Color(0xFF16A34A), // Green 600
      rating: 4.8,
      reviewsCount: '24k',
    ),
    MockAdmobCampaign(
      id: 'camp_cloud',
      sponsorName: 'SyncCloud Pro',
      title: '50GB de almacenamiento gratis en la nube',
      description:
          'Mantén tus notas, listas y fotos sincronizadas en tiempo real en todos tus dispositivos móviles y desktop.',
      ctaText: 'Instalar gratis',
      icon: Icons.cloud_done_rounded,
      primaryColor: Color(0xFF2563EB), // Blue 600
      rating: 4.9,
      reviewsCount: '89k',
    ),
    MockAdmobCampaign(
      id: 'camp_finance',
      sponsorName: 'BolsaSmart Finanzas',
      title: 'Controla tus gastos y ahorra dinero',
      description:
          'La app número 1 para gestionar presupuestos personales y listas de compras familiares con IA.',
      ctaText: 'Probar ahora',
      icon: Icons.account_balance_wallet_rounded,
      primaryColor: Color(0xFF7C3AED), // Violet 600
      rating: 4.7,
      reviewsCount: '15k',
    ),
    MockAdmobCampaign(
      id: 'camp_delivery',
      sponsorName: 'ExpressChef',
      title: 'Cenas gourmet en tu puerta en 30 minutos',
      description:
          'Los mejores restaurantes de tu ciudad en una sola aplicación. Descárgala y recibe 3 envíos sin costo.',
      ctaText: 'Ver menú',
      icon: Icons.delivery_dining_rounded,
      primaryColor: Color(0xFFEA580C), // Orange 600
      rating: 4.6,
      reviewsCount: '52k',
    ),
  ];
}
