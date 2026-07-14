// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:receipt_app/models/project.dart';
// import 'package:receipt_app/models/review.dart';
// import 'package:receipt_app/models/booking.dart';
// import 'package:receipt_app/widgets/kpi_card.dart';
// import 'package:receipt_app/widgets/revenue_chart.dart';
// import 'package:receipt_app/widgets/occupancy_chart.dart';
// import 'package:receipt_app/widgets/review_card.dart';
// import 'package:receipt_app/widgets/booking_card.dart';

// class ProjectDetailScreen extends StatelessWidget {
//   final Project project;

//   const ProjectDetailScreen({super.key, required this.project});

//   @override
//   Widget build(BuildContext context) {
//     final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

//     final projectReviews = sampleReviews
//         .where((r) => r.projectId == project.id)
//         .toList();
//     final projectBookings = sampleBookings
//         .where((b) => b.projectId == project.id)
//         .toList();

//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           project.name.length > 20
//               ? '${project.name.substring(0, 20)}...'
//               : project.name,
//           style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.notifications_outlined),
//             onPressed: () {},
//           ),
//           const SizedBox(width: 8),
//         ],
//       ),
//       body: SingleChildScrollView(
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Revenue Overview KPIs
//             _buildSectionHeader(context, 'Revenue Overview'),
//             const SizedBox(height: 8),
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: KpiCard(
//                       icon: Icons.attach_money,
//                       value: currencyFormat.format(project.revenue),
//                       label: 'Total Revenue',
//                       color: const Color(0xFF00897B),
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: KpiCard(
//                       icon: Icons.calendar_today,
//                       value: '${project.bookings}',
//                       label: 'Total Bookings',
//                       color: const Color(0xFF1565C0),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 12),
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: KpiCard(
//                       icon: Icons.star,
//                       value: project.rating.toString(),
//                       label: 'Average Rating',
//                       color: const Color(0xFFFFB300),
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: KpiCard(
//                       icon: Icons.analytics,
//                       value: '${(project.occupancyRate * 100).toInt()}%',
//                       label: 'Occupancy Rate',
//                       color: const Color(0xFF7B1FA2),
//                     ),
//                   ),
//                 ],
//               ),
//             ),

//             const SizedBox(height: 16),

//             // Revenue Chart
//             RevenueChart(stats: project.revenueStats),

//             const SizedBox(height: 8),

//             // Occupancy Chart
//             OccupancyChart(stats: project.occupancyStats),

//             const SizedBox(height: 16),

//             // Property Owner
//             _buildSectionHeader(context, 'Property Owner'),
//             const SizedBox(height: 8),
//             Card(
//               margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Row(
//                   children: [
//                     CircleAvatar(
//                       radius: 28,
//                       backgroundColor:
//                           const Color(0xFF00897B).withValues(alpha: 0.15),
//                       child: Text(
//                         project.ownerName
//                             .split(' ')
//                             .map((n) => n[0])
//                             .join(''),
//                         style: const TextStyle(
//                           color: Color(0xFF00897B),
//                           fontWeight: FontWeight.w600,
//                           fontSize: 16,
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 16),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             project.ownerName,
//                             style: const TextStyle(
//                               fontWeight: FontWeight.w600,
//                               fontSize: 15,
//                             ),
//                           ),
//                           const SizedBox(height: 6),
//                           _contactRow(
//                               Icons.email_outlined, project.ownerEmail),
//                           const SizedBox(height: 4),
//                           _contactRow(
//                               Icons.phone_outlined, project.ownerPhone),
//                           const SizedBox(height: 4),
//                           _contactRow(
//                               Icons.location_on_outlined, project.ownerAddress),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),

//             const SizedBox(height: 16),

//             // Properties
//             _buildSectionHeader(context, 'Properties'),
//             const SizedBox(height: 8),
//             ...List.generate(3, (index) {
//               final properties = [
//                 'Villa Samudra',
//                 'Garden Suite',
//                 'Vintage Residence',
//               ];
//               return Card(
//                 margin:
//                     const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
//                 child: ListTile(
//                   leading: Container(
//                     width: 40,
//                     height: 40,
//                     decoration: BoxDecoration(
//                       color: const Color(0xFF00897B).withValues(alpha: 0.1),
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     child: const Icon(
//                       Icons.holiday_village_outlined,
//                       color: Color(0xFF00897B),
//                       size: 20,
//                     ),
//                   ),
//                   title: Text(
//                     properties[index],
//                     style: const TextStyle(
//                       fontWeight: FontWeight.w500,
//                       fontSize: 14,
//                     ),
//                   ),
//                   subtitle: Text(
//                     project.location,
//                     style: TextStyle(
//                       fontSize: 12,
//                       color: Colors.grey[600],
//                     ),
//                   ),
//                   trailing: const Icon(Icons.chevron_right),
//                 ),
//               );
//             }),

//             const SizedBox(height: 16),

//             // Recent Reviews
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               child: Row(
//                 children: [
//                   const Text(
//                     'Recent Reviews',
//                     style: TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                   const Spacer(),
//                   TextButton(
//                     onPressed: () {},
//                     child: const Text('See All'),
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 4),
//             Card(
//               margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: projectReviews.isEmpty
//                     ? const Text('No reviews yet.')
//                     : Column(
//                         children: projectReviews
//                             .map((r) => ReviewCard(review: r))
//                             .toList(),
//                       ),
//               ),
//             ),

//             const SizedBox(height: 16),

//             // Recent Bookings
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               child: Row(
//                 children: [
//                   const Text(
//                     'Recent Bookings',
//                     style: TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                   const Spacer(),
//                   TextButton(
//                     onPressed: () {},
//                     child: const Text('See All'),
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 4),
//             Card(
//               margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: projectBookings.isEmpty
//                     ? const Text('No bookings yet.')
//                     : Column(
//                         children: projectBookings
//                             .map((b) => BookingCard(booking: b))
//                             .toList(),
//                       ),
//               ),
//             ),

//             const SizedBox(height: 32),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildSectionHeader(BuildContext context, String title) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16),
//       child: Text(
//         title,
//         style: const TextStyle(
//           fontSize: 16,
//           fontWeight: FontWeight.w600,
//         ),
//       ),
//     );
//   }

//   Widget _contactRow(IconData icon, String text) {
//     return Row(
//       children: [
//         Icon(icon, size: 14, color: Colors.grey[500]),
//         const SizedBox(width: 8),
//         Expanded(
//           child: Text(
//             text,
//             style: TextStyle(
//               fontSize: 12,
//               color: Colors.grey[600],
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }
