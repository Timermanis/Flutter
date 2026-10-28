import 'package:flutter/material.dart';
import 'database_helper.dart';

// --- HOME SCREEN (UNCHANGED) ---
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {

    final customButtonStyle = ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF0F4C5C).withValues(alpha: 0.5), // Deep Water Teal button background
      foregroundColor: Colors.white,            // Text and icon color
      elevation: 4,                             // Adds a clean shadow effect
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), // Smooth rounded corners
      ),
    );  
    return Scaffold(
      // Allows the background image to bleed cleanly beneath the status and app bar frames
      extendBodyBehindAppBar: true, 
      appBar: AppBar(
        title: const
        Text('My Supplement Stack', style: TextStyle(
          fontWeight: FontWeight.bold, 
          color: Color.fromARGB(255, 190, 192, 192),
          decorationStyle: TextDecorationStyle.dotted,
          )),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            // --- UPDATED TO USE LOCAL ASSET COMPONENT ---
            image: AssetImage('assets/images/mobile_background.png'),
            fit: BoxFit.cover, // Automatically crops and scales for vertical smartphone proportions
          ),
        ),
        // Darkened translucent shield layer ensures white text labels remain legible against bright sky regions
        child: Container(
          color: Colors.black.withValues(alpha: 0.35), 
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Center(
            child: SizedBox(
              width: 400, // Keeps button layouts consistent across web, tablet, or phone screens
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ScreenOne())),
                    icon: const Icon(Icons.medication),
                    label: const Text('View Active Stack'),
                    style: customButtonStyle,
                  ),
                  const SizedBox(height: 16),
                  
                  ElevatedButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ScreenTwo())),
                    icon: const Icon(Icons.add),
                    label: const Text('Add New Supplement'),
                    style: customButtonStyle,
                  ),
                  const SizedBox(height: 16),
                  
                  ElevatedButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ScreenThree())),
                    icon: const Icon(Icons.pause_circle_filled),
                    label: const Text('Manage Supplement Status'),
                    style: customButtonStyle,
                  ),
                  const SizedBox(height: 16),
                  
                  ElevatedButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ScreenFour())),
                    icon: const Icon(Icons.comment),
                    label: const Text('Add Comment'),
                    style: customButtonStyle,
                  ),
                  const SizedBox(height: 16),
                  
                  ElevatedButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ScreenFive())),
                    icon: const Icon(Icons.history),
                    label: const Text('All Comments'),
                    style: customButtonStyle,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}



// --- NEW IMPLEMENTATION: SCREEN FOUR (COMMENTS WORKSPACE) ---
class ScreenFour extends StatefulWidget {
  const ScreenFour({super.key});

  @override
  State<ScreenFour> createState() => _ScreenFourState();
}

// --- CORRECTED IMPLEMENTATION: SCREEN FOUR (ID-BASED DROPDOWN CONTROLLER) ---
// class ScreenFour extends StatefulWidget {
//   const ScreenFour({super.key});

//   @override
//   State<ScreenFour> createState() => _ScreenFourState();
// }

class _ScreenFourState extends State<ScreenFour> {
  List<Map<String, dynamic>> _supplements = [];
  int? _selectedSupplementId; // FIX: Track the ID integer value directly instead of the Map object [2]
  List<Map<String, dynamic>> _comments = [];
  final _commentController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSupplements();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadSupplements() async {
    final data = await DatabaseHelper.instance.fetchAllSupplements();
    setState(() {
      _supplements = data;
      _isLoading = false;
      
      if (_supplements.isNotEmpty) {
        // Fallback guard: preserve active selection or reset to the first available index id
        if (_selectedSupplementId == null || !_supplements.any((s) => s['id'] == _selectedSupplementId)) {
          _selectedSupplementId = _supplements.first['id'];
        }
        _loadCommentsForSelected();
      } else {
        _selectedSupplementId = null;
        _comments = [];
      }
    });
  }

  Future<void> _loadCommentsForSelected() async {
    if (_selectedSupplementId != null) {
      final commentsData = await DatabaseHelper.instance.fetchCommentsForSupplement(_selectedSupplementId!);
      setState(() {
        _comments = commentsData;
      });
    }
  }

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty || _selectedSupplementId == null) return;

    await DatabaseHelper.instance.insertComment(
      _selectedSupplementId!,
      _commentController.text.trim(),
    );

    _commentController.clear();
    _loadCommentsForSelected(); // Redraw comments layout safely
    
    if (mounted) {
      FocusScope.of(context).unfocus(); // Close keypane
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Supplement Notes & Comments')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _supplements.isEmpty
              ? const Center(child: Text('Add a supplement first to log comments.'))
              : Center(
                  child: SizedBox(
                    width: 400,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Selector Dropdown Row
                          const Text('Select Supplement:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                value: _selectedSupplementId, // Binds tracking directly to matching unique row item ID [2]
                                isExpanded: true,
                                items: _supplements.map((sup) {
                                  return DropdownMenuItem<int>(
                                    value: sup['id'] as int,
                                    child: Text('${sup['supplement']} (${sup['brand'] ?? 'Generic'})'),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedSupplementId = value;
                                    _loadCommentsForSelected();
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // 2. Add New Comment Input Layout Frame
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _commentController,
                                  decoration: const InputDecoration(
                                    hintText: 'Add a new note or detail...',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton.filled(
                                onPressed: _submitComment,
                                icon: const Icon(Icons.send),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // 3. Header Title for list frame
                          const Text('History Log:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 8),

                          // 4. Comments History Feed Framework
                          Expanded(
                            child: _comments.isEmpty
                                ? const Center(child: Text('No comments recorded yet.', style: TextStyle(color: Colors.grey)))
                                : ListView.builder(
                                    itemCount: _comments.length,
                                    itemBuilder: (context, index) {
                                      final note = _comments[index];
                                      return Card(
                                        elevation: 0.5,
                                        margin: const EdgeInsets.symmetric(vertical: 4.0),
                                        child: Padding(
                                          padding: const EdgeInsets.all(12.0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                note['comment_text'] ?? '',
                                                style: const TextStyle(fontSize: 14),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                'Logged: ${note['date_added']}',
                                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }
}


// --- REST OF UNCHANGED CODE (SCREEN ONE, TWO, THREE & FIVE) ---
// ==================== SCREEN ONE ====================
class ScreenOne extends StatefulWidget {
  const ScreenOne({super.key});

  @override
  State<ScreenOne> createState() => _ScreenOneState();
}

// FIX: Added explicit generic type <ScreenOne>
class _ScreenOneState extends State<ScreenOne> {
  late Future<List<Map<String, dynamic>>> _supplementStackFuture;

  @override
  void initState() {
    super.initState();
    _supplementStackFuture = DatabaseHelper.instance.fetchActiveSupplements();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Active Supplement Stack')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _supplementStackFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text('No active supplements in your stack.'));
          
          final items = snapshot.data!;
          return Center(
            child: SizedBox(
              width: 400,
              child: ListView.builder(
                itemCount: items.length,
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Card(
                    elevation: 1,
                    margin: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: Text(item['supplement'] ?? 'Unknown', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: Colors.teal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                                child: Text(item['brand'] ?? 'Generic', style: const TextStyle(fontSize: 11, color: Colors.teal, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          const Padding(padding: EdgeInsets.symmetric(vertical: 6.0), child: Divider(height: 1, thickness: 0.5)),
                          Row(
                            children: [
                              Expanded(child: Row(children: [const Icon(Icons.scale, size: 14, color: Colors.grey), const SizedBox(width: 4), Expanded(child: Text('Dosage: ${item['dosage']}', style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis))])),
                              Expanded(child: Row(children: [const Icon(Icons.loop, size: 14, color: Colors.grey), const SizedBox(width: 4), Expanded(child: Text('Freq: ${item['times_per_day']}x/d', style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis))])),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(children: [const Icon(Icons.calendar_today, size: 14, color: Colors.grey), const SizedBox(width: 4), Text('Started: ${item['start_date']}', style: const TextStyle(fontSize: 13, color: Colors.grey))])
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

// ==================== SCREEN TWO ====================
class ScreenTwo extends StatefulWidget {
  const ScreenTwo({super.key});

  // FIX: Added explicit generic type <ScreenTwo>
  @override
  State<ScreenTwo> createState() => _ScreenTwoState();
}

// FIX: Added explicit generic type <ScreenTwo>
class _ScreenTwoState extends State<ScreenTwo> {
  // FIX: Explicit FormState designation added here
  final _formKey = GlobalKey<FormState>(); 
  final _supplementController = TextEditingController();
  final _dosageController = TextEditingController();
  final _frequencyController = TextEditingController();
  final _brandController = TextEditingController();
  final _startDateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _startDateController.text = DateTime.now().toString().split(' ')[0];
  }

  @override
  void dispose() {
    _supplementController.dispose();
    _dosageController.dispose();
    _frequencyController.dispose();
    _brandController.dispose();
    _startDateController.dispose();
    super.dispose();
  }

  Future<void> _saveSupplement() async {
    if (_formKey.currentState!.validate()) {
      final Map<String, dynamic> newSupplement = {
        'supplement': _supplementController.text.trim(),
        'dosage': _dosageController.text.trim(),
        'times_per_day': int.tryParse(_frequencyController.text.trim()) ?? 1,
        'start_date': _startDateController.text.trim(),
        'brand': _brandController.text.trim().isEmpty ? 'Generic' : _brandController.text.trim()
      };
      await DatabaseHelper.instance.insertSupplement(newSupplement);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Supplement saved successfully!')));
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Supplement')),
      body: Center(
        child: SizedBox(
          width: 400,
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24.0),
              children: [
                TextFormField(controller: _supplementController, decoration: const InputDecoration(labelText: 'Supplement Name *', prefixIcon: Icon(Icons.medication)), validator: (value) => value == null || value.trim().isEmpty ? 'Enter name' : null),
                const SizedBox(height: 16),
                TextFormField(controller: _brandController, decoration: const InputDecoration(labelText: 'Brand / Manufacturer', prefixIcon: Icon(Icons.business))),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: TextFormField(controller: _dosageController, decoration: const InputDecoration(labelText: 'Dosage *', prefixIcon: Icon(Icons.scale)), validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null)),
                    const SizedBox(width: 16),
                    Expanded(child: TextFormField(controller: _frequencyController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Times/Day *', prefixIcon: Icon(Icons.loop)), validator: (value) => value == null || value.isEmpty ? 'Required' : null))
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(controller: _startDateController, decoration: const InputDecoration(labelText: 'Start Date', prefixIcon: Icon(Icons.calendar_today)), validator: (value) => value == null || value.trim().isEmpty ? 'Enter start date' : null),
                const SizedBox(height: 32),
                FilledButton.icon(onPressed: _saveSupplement, icon: const Icon(Icons.save), label: const Text('Save Supplement'))
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== SCREEN THREE ====================
class ScreenThree extends StatefulWidget {
  const ScreenThree({super.key});

  // FIX: Added explicit generic type <ScreenThree>
  @override
  State<ScreenThree> createState() => _ScreenThreeState();
}

// FIX: Added explicit generic type <ScreenThree>
class _ScreenThreeState extends State<ScreenThree> {
  late Future<List<Map<String, dynamic>>> _allSupplementsFuture;

  @override
  void initState() {
    super.initState();
    _refreshList();
  }

  void _refreshList() {
    setState(() {
      _allSupplementsFuture = DatabaseHelper.instance.fetchAllSupplements();
    });
  }

  Future<void> _toggleStatus(int id, bool currentStatus) async {
    await DatabaseHelper.instance.updateSuspensionStatus(id, currentStatus);
    _refreshList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Statuses')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _allSupplementsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text('No supplements found.'));
          
          final items = snapshot.data!;
          return Center(
            child: SizedBox(
              width: 400,
              child: ListView.builder(
                itemCount: items.length,
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final int id = item['id'];
final bool isActive = item['is_active'] == 1;
return Card(
color: isActive ? null : Colors.grey.shade100,
elevation: 1,
margin: const EdgeInsets.symmetric(vertical: 4.0),
child: ListTile(
contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
title: Text(item['supplement'] ?? 'Unknown', style: TextStyle(fontWeight: FontWeight.bold, color: isActive ? null : Colors.grey, decoration: isActive ? null : TextDecoration.lineThrough)),
subtitle: Text('${item['brand'] ?? 'Generic'} • ${item['dosage']}', style: TextStyle(color: isActive ? null : Colors.grey)),
trailing: IconButton(
icon: Icon(isActive ? Icons.pause_circle_outline : Icons.play_circle_outline, color: isActive ? Colors.orange : Colors.teal, size: 28),
tooltip: isActive ? 'Suspend item' : 'Activate item',
// FIX: Wrapped broken callback reference smoothly
onPressed: () => _toggleStatus(id, isActive),
),
),
);
},
),
),
);
},
),
);
}
}
// class ScreenFive extends StatelessWidget {
//   const ScreenFive({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Screen Five'),
//         centerTitle: true,
//       ),
//       body: const Center(
//         child: Text(
//           'Welcome to Screen Five',
//           style: TextStyle(fontSize: 20),
//         ),
//       ),
//     );
//   }
// }
// ==================== SCREEN FIVE: GLOBAL COMMENTS LOG ====================
class ScreenFive extends StatefulWidget {
  const ScreenFive({super.key});

  @override
  State<ScreenFive> createState() => _ScreenFiveState();
}

class _ScreenFiveState extends State<ScreenFive> {
  late Future<List<Map<String, dynamic>>> _globalCommentsFuture;

  @override
  void initState() {
    super.initState();
    _globalCommentsFuture = DatabaseHelper.instance.fetchAllCommentsWithSupplements();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Stack Comments'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _globalCommentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading comments: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'No historical comments or notes found anywhere in your database.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            );
          }

          final globalNotes = snapshot.data!;

          return Center(
            child: SizedBox(
              width: 400, // Keeps frame presentation matching ScreenOne and ScreenFour
              child: ListView.builder(
                itemCount: globalNotes.length,
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                itemBuilder: (context, index) {
                  final note = globalNotes[index];
                  
                  return Card(
                    elevation: 1,
                    margin: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header tag showing which supplement this specific note belongs to
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  note['supplement_name'] ?? 'Unknown Supplement',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal.shade700,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                note['date_added'] ?? '',
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Brand: ${note['supplement_brand'] ?? 'Generic'}',
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Divider(height: 1, thickness: 0.5),
                          ),
                          // The actual note text
                          Text(
                            note['comment_text'] ?? '',
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
