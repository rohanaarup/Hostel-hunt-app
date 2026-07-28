import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rohii_hostel_hunt/features/hostel/presentation/pages/booking_success_screen.dart';
import 'package:rohii_hostel_hunt/features/hostel/domain/models/hostel.dart';
import 'package:rohii_hostel_hunt/features/hostel/domain/models/room.dart';
import 'package:rohii_hostel_hunt/features/hostel/presentation/providers/room_provider.dart';

class BedSelectionScreen extends ConsumerStatefulWidget {
  final Hostel hostel;

  const BedSelectionScreen({super.key, required this.hostel});

  @override
  ConsumerState<BedSelectionScreen> createState() => _BedSelectionScreenState();
}

class _BedSelectionScreenState extends ConsumerState<BedSelectionScreen> {
  int? selectedFloor;
  Room? selectedRoom;
  String? selectedBedId;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDone = selectedFloor != null && selectedRoom != null && selectedBedId != null;

    final roomsAsyncValue = ref.watch(roomsProvider(widget.hostel.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Your Bed"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: roomsAsyncValue.when(
        data: (groupedRooms) {
          if (groupedRooms.isEmpty) {
            return Center(
              child: Text("No rooms available for this hostel.", style: TextStyle(color: cs.onSurface)),
            );
          }

          final floors = groupedRooms.keys.toList();
          if (selectedFloor != null && !floors.contains(selectedFloor)) {
             // Reset selections if the chosen floor is missing (shouldn't happen on static fetch)
             WidgetsBinding.instance.addPostFrameCallback((_) {
               setState(() {
                 selectedFloor = null;
                 selectedRoom = null;
                 selectedBedId = null;
               });
             });
          }

          final roomsForSelectedFloor = selectedFloor != null ? groupedRooms[selectedFloor]! : <Room>[];

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSectionHeader("SELECT FLOOR"),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: floors.map((floor) => _buildFloorChip(floor, cs)).toList(),
                  ),
                ),

                const SizedBox(height: 20),
                _buildSectionHeader("SELECT ROOM NO"),
                const SizedBox(height: 12),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: selectedFloor == null
                      ? _buildEmptyState("Please select a floor first", cs)
                      : GridView.builder(
                          key: ValueKey(selectedFloor),
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 1.5,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: roomsForSelectedFloor.length,
                          itemBuilder: (context, index) {
                            return _buildRoomCard(roomsForSelectedFloor[index], cs);
                          },
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
                          key: ValueKey(selectedRoom?.roomId),
                          children: [
                            _buildRoomDiagram(selectedRoom!, cs),
                            const SizedBox(height: 16),
                            _buildLegend(cs),
                          ],
                        ),
                ),

                const SizedBox(height: 20),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: selectedBedId != null && selectedRoom != null
                      ? _buildSelectedBedInfo(selectedRoom!, cs)
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.orange)),
        error: (error, stack) => Center(
          child: Text("Error loading rooms", style: TextStyle(color: cs.error)),
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
          color: Colors.orange,
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

  Widget _buildFloorChip(int floor, ColorScheme cs) {
    final isSelected = selectedFloor == floor;
    final String floorName = floor == 0 ? "Ground Floor" : "Floor $floor";
    
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(floorName),
        selected: isSelected,
        selectedColor: cs.primary.withOpacity(0.2),
        labelStyle: TextStyle(
          color: isSelected ? cs.primary : cs.onSurface,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        side: BorderSide(color: isSelected ? cs.primary : cs.outline.withOpacity(0.3)),
        onSelected: (selected) {
          setState(() {
            selectedFloor = selected ? floor : null;
            selectedRoom = null;
            selectedBedId = null;
          });
        },
      ),
    );
  }

  Widget _buildRoomCard(Room room, ColorScheme cs) {
    final isSelected = selectedRoom?.roomId == room.roomId;
    final isFull = room.availableBeds == 0;
    
    return GestureDetector(
      onTap: () {
        if (isFull) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text("This room is full")),
           );
           return;
        }
        setState(() {
          selectedRoom = room;
          selectedBedId = null;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? cs.primary.withOpacity(0.1) : (isFull ? cs.surface.withOpacity(0.5) : cs.surface),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? cs.primary : cs.outline.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  room.roomName.isNotEmpty ? room.roomName : "Room ${room.roomNumber}", 
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.bold,
                    color: isFull ? cs.onSurface.withOpacity(0.5) : cs.onSurface,
                    fontSize: 16,
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle, color: cs.primary, size: 18),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              "${room.sharingType.toUpperCase()} • ₹${room.pricePerMonth.toInt()}/mo", 
              style: TextStyle(
                fontSize: 10, 
                color: isFull ? cs.onSurface.withOpacity(0.4) : cs.onSurface.withOpacity(0.7),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.bed, size: 12, color: isFull ? Colors.red.withOpacity(0.5) : Colors.green),
                const SizedBox(width: 4),
                Text(
                  isFull ? "FULL" : "${room.availableBeds} left",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isFull ? Colors.red.withOpacity(0.5) : Colors.green,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildRoomDiagram(Room room, ColorScheme cs) {
    // Generate beds based on bedCount and availableBeds
    // We assume the first (bedCount - availableBeds) are booked
    final int bookedBeds = room.bedCount - room.availableBeds;
    
    final List<Map<String, dynamic>> bedsInfo = List.generate(room.bedCount, (index) {
       final bedNo = index + 1;
       final isAvailable = index >= bookedBeds;
       return {
         "id": bedNo.toString(),
         "label": "Bed $bedNo",
         "status": isAvailable ? "available" : "booked"
       };
    });

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
          if (room.hasAttachedBathroom)
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
          
          // Beds
          Center(
            child: SizedBox(
              width: 180,
              height: 180,
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                runAlignment: WrapAlignment.center,
                children: bedsInfo.map((b) => _buildBedTile(b, cs)).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBedTile(Map<String, dynamic> bed, ColorScheme cs) {
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
        width: 60,
        height: 70,
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
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              bed['label']!,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 10,
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

  Widget _buildSelectedBedInfo(Room room, ColorScheme cs) {
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
            "Bed $selectedBedId selected", 
            style: TextStyle(fontWeight: FontWeight.bold, color: cs.primary, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text("Room: ${room.roomName.isNotEmpty ? room.roomName : room.roomNumber}", style: TextStyle(color: cs.onSurface)),
          Text("AC: ${room.isAc ? 'Yes' : 'No'}", style: TextStyle(color: cs.onSurface)),
          const SizedBox(height: 4),
          Text("Price: ₹${room.pricePerMonth.toInt()}/mo", style: TextStyle(fontWeight: FontWeight.bold, color: cs.onSurface)),
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

                    // Simulate network request
                    await Future.delayed(const Duration(seconds: 1));

                    if (!mounted) return;
                    Navigator.pop(context); // Close loading dialog
                    
                    // Navigate to success screen
                    Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (_) => BookingSummaryScreen(
                          hostel: widget.hostel,
                          floor: selectedFloor == 0 ? "Ground Floor" : "Floor $selectedFloor",
                          room: selectedRoom!.roomNumber,
                          bedLabel: "Bed $selectedBedId",
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
