import 'package:flutter/material.dart';

class DeliveryDashboard extends StatefulWidget {
  final String courierId;
  final String courierName;

  const DeliveryDashboard({
    Key? key,
    required this.courierId,
    required this.courierName,
  }) : super(key: key);

  @override
  State<DeliveryDashboard> createState() => _DeliveryDashboardState();
}

class _DeliveryDashboardState extends State<DeliveryDashboard> {
  String _status = 'available'; // available, busy, offline

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('لوحة المندوب - ${widget.courierName}')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text('تحديث حالة التوفر:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'available', label: Text('متاح')),
                        ButtonSegment(value: 'busy', label: Text('مشغول')),
                        ButtonSegment(value: 'offline', label: Text('غير متصل')),
                      ],
                      selected: {_status},
                      onSelectionChanged: (Set<String> newSelection) {
                        setState(() {
                          _status = newSelection.first;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Expanded(
              child: Center(
                child: Text('الطلبات المسندة لك ستظهر هنا فور قبولها من المشرف'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}