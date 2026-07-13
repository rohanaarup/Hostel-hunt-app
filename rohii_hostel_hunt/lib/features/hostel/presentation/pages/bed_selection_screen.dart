import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:rohii_hostel_hunt/features/hostel/presentation/pages/booking_success_screen.dart';

import 'package:rohii_hostel_hunt/features/hostel/domain/models/hostel.dart';

class BedSelectionScreen extends StatefulWidget {
  final Hostel hostel;

  const BedSelectionScreen({super.key, required this.hostel});

  @override
  State<BedSelectionScreen> createState() => _BedSelectionScreenState();
}

class _BedSelectionScreenState extends State<BedSelectionScreen> {
  final List<String> floors = ["Ground Floor", "Floor 1", "Floor 2", "Floor 3"];
  
  final Map<String, List<String>> roomsPerFloor = {
    "Ground Floor": ["G01", "G02", "G03"],
    "Floor 1": ["101", "102", "103", "104"],
    "Floor 2": ["201", "202", "203"],
    "Floor 3": ["301", "302", "303", "304", "305"],
  };

  final List<Map<String, String>> bedsInfo = [
    {"id": "1", "label": "Bed 1", "status": "available"},
    {"id": "2", "label": "Bed 2", "status": "booked"},
    {"id": "3", "label": "Bed 3", "status": "available"},
    {"id": "4", "label": "Bed 4", "status": "available"},
  ];

  String? selectedFloor;
  String? selectedRoom;
  String? selectedBedId;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDone = selectedFloor != null && selectedRoom != null && selectedBedId != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Your Bed"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionHeader("SELECT FLOOR"),
            const SizedBox(height: 12),
            ...floors.map((floor) => _buildFloorCard(floor, cs)),

            const SizedBox(height: 20),
            _buildSectionHeader("SELECT ROOM NO"),
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: selectedFloor == null
                  ? _buildEmptyState("Please select a floor first", cs)
                  : Column(
                      key: ValueKey(selectedFloor),
                      children: roomsPerFloor[selectedFloor]!
                          .map((room) => _buildRoomCard(room, cs))
                          .toList(),
                    ),
            ),

            const SizedBox(height: 20),
            _buildSectionHeader("SELECT BED IN ROOM"),
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: selectedRoom == null
                  ? _buildEmptyState("Please select a room first", cs)
                  : Column(
                      key: ValueKey(selectedRoom),
                      children: [
                        _buildRoomDiagram(cs),
                        const SizedBox(height: 16),
                        _buildLegend(cs),
                      ],
                    ),
            ),

            const SizedBox(height: 20),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: selectedBedId != null
                  ? _buildSelectedBedInfo(cs)
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(isActive: isDone, cs: cs),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          color: Colors.orange, // Constant accent as requested
        ),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String text, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Text(
          text,
          style: TextStyle(color: cs.onSurface.withOpacity(0.5)),
        ),
      ),
    );
  }

  Widget _buildFloorCard(String floor, ColorScheme cs) {
    final isSelected = selectedFloor == floor;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFloor = floor;
          selectedRoom = null;
          selectedBedId = null;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected ? cs.primary.withOpacity(0.1) : cs.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? cs.primary : cs.outline.withOpacity(0.3),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Radio<String>(
              value: floor,
              groupValue: selectedFloor,
              activeColor: cs.primary,
              onChanged: (val) {
                setState(() {
                  selectedFloor = val;
                  selectedRoom = null;
                  selectedBedId = null;
                });
              },
            ),
            Text(
              floor, 
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomCard(String room, ColorScheme cs) {
    final isSelected = selectedRoom == room;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedRoom = room;
          selectedBedId = null;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected ? cs.primary.withOpacity(0.1) : cs.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? cs.primary : cs.outline.withOpacity(0.3),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Radio<String>(
              value: room,
              groupValue: selectedRoom,
              activeColor: cs.primary,
              onChanged: (val) {
                setState(() {
                  selectedRoom = val;
                  selectedBedId = null;
                });
              },
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Room $room", 
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: cs.onSurface,
                  ),
                ),
                Text(
                  "4-sharing • ₹6,500/mo", 
                  style: TextStyle(
                    fontSize: 12, 
                    color: cs.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomDiagram(ColorScheme cs) {
    return Container(
      width: double.infinity,
      height: 280,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline.withOpacity(0.3), width: 2),
      ),
      child: Stack(
        children: [
          // Bathroom
          Positioned(
            top: 0,
            left: 0,
            child: Container(
              width: 50,
              height: 70,
              decoration: const BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(14), 
                  bottomRight: Radius.circular(8)
                ),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wc, size: 20, color: Colors.white),
                  Text("BATH\nROOM", style: TextStyle(fontSize: 8, color: Colors.white), textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
          
          // Wardrobe
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 50,
              height: 70,
              decoration: const BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(14), 
                  bottomLeft: Radius.circular(8)
                ),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.checkroom, size: 20, color: Colors.white),
                  Text("WARD\nROBE", style: TextStyle(fontSize: 8, color: Colors.white), textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
          
          // Window
          Positioned(
            top: 100,
            right: 0,
            child: Container(
              width: 16,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.2),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8), 
                  bottomLeft: Radius.circular(8)
                ),
              ),
              child: Center(
                child: RotatedBox(
                  quarterTurns: 1,
                  child: Text(
                    "WINDOW", 
                    style: TextStyle(
                      fontSize: 10, 
                      color: cs.onSurface.withOpacity(0.5)
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Entrance
          Positioned(
            bottom: 0,
            left: 60,
            right: 60,
            child: Container(
              height: 30,
              decoration: BoxDecoration(
                color: cs.onSurface.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8), 
                  topRight: Radius.circular(8)
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.door_front_door, size: 16, color: cs.onSurface.withOpacity(0.6)),
                  const SizedBox(width: 4),
                  Text(
                    "ENTRANCE", 
                    style: TextStyle(
                      fontSize: 10, 
                      fontWeight: FontWeight.bold, 
                      letterSpacing: 1, 
                      color: cs.onSurface.withOpacity(0.6)
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Beds (2x2 Grid)
          Center(
            child: SizedBox(
              width: 160,
              height: 180,
              child: Wrap(
                spacing: 20,
                runSpacing: 20,
                children: bedsInfo.map((b) => _buildBedTile(b, cs)).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBedTile(Map<String, String> bed, ColorScheme cs) {
    final bool isAvailable = bed['status'] == 'available';
    final bool isSelected = selectedBedId == bed['id'];
    
    Color bgColor = isSelected ? cs.primary : (isAvailable ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1));
    Color borderColor = isSelected ? cs.primary : (isAvailable ? Colors.green : Colors.red);
    Color textColor = isSelected ? cs.onPrimary : (isAvailable ? Colors.green.shade800 : Colors.red.shade800);

    return GestureDetector(
      onTap: () {
        if (!isAvailable) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("This bed is already booked")),
          );
          return;
        }
        setState(() {
          selectedBedId = (selectedBedId == bed['id']) ? null : bed['id'];
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 70,
        height: 80,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: 2),
          boxShadow: isSelected
              ? [BoxShadow(color: cs.primary.withOpacity(0.4), blurRadius: 8, spreadRadius: 1)]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isAvailable ? Icons.bed : Icons.lock,
              color: textColor,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              bed['label']!,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(ColorScheme cs) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendItem(Colors.green, "Available", cs),
        const SizedBox(width: 16),
        _legendItem(Colors.red, "Booked", cs),
        const SizedBox(width: 16),
        _legendItem(cs.primary, "Selected", cs),
      ],
    );
  }

  Widget _legendItem(Color color, String label, ColorScheme cs) {
    return Row(
      children: [
        CircleAvatar(radius: 6, backgroundColor: color),
        const SizedBox(width: 6),
        Text(
          label, 
          style: TextStyle(fontSize: 12, color: cs.onSurface),
        ),
      ],
    );
  }

  Widget _buildSelectedBedInfo(ColorScheme cs) {
    final bedInfo = bedsInfo.firstWhere((b) => b['id'] == selectedBedId);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cs.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "${bedInfo['label']} selected", 
            style: TextStyle(fontWeight: FontWeight.bold, color: cs.primary, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text("Type: Lower Bunk", style: TextStyle(color: cs.onSurface)),
          Text("Near window: Yes", style: TextStyle(color: cs.onSurface)),
          const SizedBox(height: 4),
          Text("Price: ₹6,500/mo", style: TextStyle(fontWeight: FontWeight.bold, color: cs.onSurface)),
        ],
      ),
    );
  }

  Widget _buildBottomBar({required bool isActive, required ColorScheme cs}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16).copyWith(
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: cs.surface,
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.05), 
            blurRadius: 10, 
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: isActive
                ? () async {
                    // Show a loading dialog
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const Center(
                        child: CircularProgressIndicator(color: Colors.orange),
                      ),
                    );

                    // Simulate network request (Flutter Only Safe Extension)
                    await Future.delayed(const Duration(seconds: 2));

                    if (!mounted) return;
                    Navigator.pop(context); // Close loading dialog
                    
                    final bedInfo = bedsInfo.firstWhere((b) => b['id'] == selectedBedId);
                    
                    // Navigate to success screen
                    Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (_) => BookingSummaryScreen(
                          hostel: widget.hostel,
                          floor: selectedFloor!,
                          room: selectedRoom!,
                          bedLabel: bedInfo['label']!,
                        ),
                      ),
                    );
                  }
                : null,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isActive ? 1.0 : 0.4,
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B35), Color(0xFFE85D04)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_month, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      "Book the Bed ✓",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Online payment coming soon!")),
              );
            },
            child: Text(
              "Do you want to pay online?",
              style: TextStyle(fontSize: 12, color: cs.onSurface.withOpacity(0.5)),
            ),
          ),
        ],
      ),
    );
  }
}
