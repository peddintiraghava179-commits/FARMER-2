import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const FarmerExpenseApp());

class FarmRecord {
  final String id, title, crop, category;
  final double amount;
  final bool isIncome;
  final DateTime date;
  FarmRecord({required this.id, required this.title, required this.crop, required this.category, required this.amount, required this.isIncome, required this.date});
  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'crop': crop, 'category': category, 'amount': amount, 'isIncome': isIncome, 'date': date.toIso8601String()};
  factory FarmRecord.fromJson(Map<String, dynamic> j) => FarmRecord(id: j['id'], title: j['title'], crop: j['crop'], category: j['category'], amount: (j['amount'] as num).toDouble(), isIncome: j['isIncome'], date: DateTime.parse(j['date']));
}

class FarmerExpenseApp extends StatelessWidget {
  const FarmerExpenseApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Farmer Expense Record', debugShowCheckedModeBanner: false,
    theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF176B3A)), scaffoldBackgroundColor: const Color(0xFFF5F8F3), inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder(), filled: true, fillColor: Colors.white)),
    home: const DashboardPage(),
  );
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}
class _DashboardPageState extends State<DashboardPage> {
  final List<FarmRecord> records = [];
  bool loading = true;
  double get income => records.where((r) => r.isIncome).fold(0, (s, r) => s + r.amount);
  double get expenses => records.where((r) => !r.isIncome).fold(0, (s, r) => s + r.amount);
  double get profit => income - expenses;
  String money(double n) => '₹${n.toStringAsFixed(2)}';

  @override
  void initState() { super.initState(); loadRecords(); }
  Future<void> loadRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('farm_records');
    if (saved != null) {
      try {
        final list = jsonDecode(saved) as List<dynamic>;
        records.addAll(list.map((e) => FarmRecord.fromJson(Map<String, dynamic>.from(e as Map))));
      } catch (_) {}
    }
    if (mounted) setState(() => loading = false);
  }
  Future<void> saveRecords() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('farm_records', jsonEncode(records.map((r) => r.toJson()).toList()));
  }
  Future<void> addRecord(bool isIncome) async {
    final record = await showDialog<FarmRecord>(context: context, builder: (_) => AddRecordDialog(isIncome: isIncome));
    if (record != null) { setState(() => records.insert(0, record)); await saveRecords(); }
  }
  Future<void> deleteRecord(FarmRecord r) async { setState(() => records.removeWhere((e) => e.id == r.id)); await saveRecords(); }

  @override
  Widget build(BuildContext context) {
    final recent = [...records]..sort((a, b) => b.date.compareTo(a.date));
    return Scaffold(
      appBar: AppBar(backgroundColor: const Color(0xFF176B3A), foregroundColor: Colors.white, title: const Row(children: [Icon(Icons.agriculture, size: 30), SizedBox(width: 10), Text('Farmer Expense Record', style: TextStyle(fontWeight: FontWeight.bold))])),
      body: loading ? const Center(child: CircularProgressIndicator()) : Center(
        child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1100), child: ListView(padding: const EdgeInsets.all(18), children: [
          Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), gradient: const LinearGradient(colors: [Color(0xFF176B3A), Color(0xFF39965A)], begin: Alignment.topLeft, end: Alignment.bottomRight)), child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Your farm. Your records. Your growth.', style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.bold)),
            SizedBox(height: 8), Text('Track crop costs, sales and profit in one simple place.', style: TextStyle(color: Colors.white, fontSize: 15)),
          ])),
          const SizedBox(height: 18),
          LayoutBuilder(builder: (context, c) {
            final wide = c.maxWidth > 650;
            final cards = [
              SummaryCard(title: 'Total Income', amount: money(income), icon: Icons.savings, color: const Color(0xFF167A48)),
              SummaryCard(title: 'Total Expenses', amount: money(expenses), icon: Icons.receipt_long, color: const Color(0xFFC65B2B)),
              SummaryCard(title: profit >= 0 ? 'Net Profit' : 'Net Loss', amount: money(profit.abs()), icon: profit >= 0 ? Icons.trending_up : Icons.trending_down, color: profit >= 0 ? const Color(0xFF2767B2) : Colors.red),
            ];
            return Flex(direction: wide ? Axis.horizontal : Axis.vertical, children: cards.map((card) => FlexibleBox(wide: wide, child: Padding(padding: EdgeInsets.only(bottom: wide ? 0 : 10, right: wide ? 10 : 0), child: card))).toList());
          }),
          const SizedBox(height: 10),
          LayoutBuilder(builder: (context, c) {
            final wide = c.maxWidth > 550;
            final buttons = [
              ActionCard(label: 'Add Expense', subtitle: 'Seeds, fertilizer, labour…', icon: Icons.add_shopping_cart, color: const Color(0xFFC65B2B), onTap: () => addRecord(false)),
              ActionCard(label: 'Add Crop Income', subtitle: 'Record crop sales', icon: Icons.currency_rupee, color: const Color(0xFF176B3A), onTap: () => addRecord(true)),
            ];
            return Flex(direction: wide ? Axis.horizontal : Axis.vertical, children: buttons.map((b) => FlexibleBox(wide: wide, child: Padding(padding: EdgeInsets.only(right: wide ? 10 : 0, bottom: wide ? 0 : 10), child: b))).toList());
          }),
          const SizedBox(height: 12),
          const Text('Recent Records', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (recent.isEmpty) Container(padding: const EdgeInsets.all(28), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)), child: const Column(children: [
            Icon(Icons.menu_book, size: 42, color: Colors.green), SizedBox(height: 8),
            Text('No records yet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            Text('Tap “Add Expense” or “Add Crop Income” to get started.'),
          ])) else ...recent.map((r) => Card(
            color: Colors.white, elevation: 0, margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(backgroundColor: r.isIncome ? const Color(0xFFDDF3E4) : const Color(0xFFFFE9DD), child: Icon(r.isIncome ? Icons.south_west : Icons.north_east, color: r.isIncome ? Colors.green.shade800 : Colors.deepOrange)),
              title: Text(r.title, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('${r.crop} • ${r.category} • ${r.date.day}/${r.date.month}/${r.date.year}'),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('${r.isIncome ? '+' : '−'}${money(r.amount)}', style: TextStyle(fontWeight: FontWeight.bold, color: r.isIncome ? Colors.green.shade800 : Colors.deepOrange)),
                IconButton(tooltip: 'Delete record', icon: const Icon(Icons.delete_outline), onPressed: () => deleteRecord(r)),
              ]),
            ),
          )),
          const SizedBox(height: 16),
          const Text('Tip: Add every small cost too. Accurate records help you understand which crops are profitable.', style: TextStyle(color: Colors.black54)),
        ])),
      ),
    );
  }
}

class FlexibleBox extends StatelessWidget {
  final bool wide; final Widget child;
  const FlexibleBox({super.key, required this.wide, required this.child});
  @override
  Widget build(BuildContext context) => wide ? Expanded(child: child) : child;
}
class SummaryCard extends StatelessWidget {
  final String title, amount; final IconData icon; final Color color;
  const SummaryCard({super.key, required this.title, required this.amount, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(17), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(17)), child: Row(children: [
    CircleAvatar(backgroundColor: color.withValues(alpha: .12), child: Icon(icon, color: color)), const SizedBox(width: 12),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Colors.black54)), const SizedBox(height: 4), Text(amount, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color))])),
  ]));
}
class ActionCard extends StatelessWidget {
  final String label, subtitle; final IconData icon; final Color color; final VoidCallback onTap;
  const ActionCard({super.key, required this.label, required this.subtitle, required this.icon, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => SizedBox(width: double.infinity, child: Card(elevation: 0, color: Colors.white, child: InkWell(borderRadius: BorderRadius.circular(16), onTap: onTap, child: Padding(padding: const EdgeInsets.all(17), child: Row(children: [
    CircleAvatar(backgroundColor: color.withValues(alpha: .12), child: Icon(icon, color: color)), const SizedBox(width: 12),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), Text(subtitle, style: const TextStyle(color: Colors.black54))])),
    const Icon(Icons.chevron_right),
  ])))));
}

class AddRecordDialog extends StatefulWidget {
  final bool isIncome;
  const AddRecordDialog({super.key, required this.isIncome});
  @override
  State<AddRecordDialog> createState() => _AddRecordDialogState();
}
class _AddRecordDialogState extends State<AddRecordDialog> {
  final formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final amountController = TextEditingController();
  String crop = 'Paddy', category = 'Seeds';
  DateTime date = DateTime.now();
  List<String> get categories => widget.isIncome ? ['Crop Sale', 'Other Income'] : ['Seeds', 'Fertilizer', 'Pesticide', 'Labour', 'Irrigation', 'Fuel', 'Equipment', 'Transport', 'Other'];
  @override
  void dispose() { titleController.dispose(); amountController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.isIncome ? 'Add Crop Income' : 'Add Farm Expense'),
    content: SizedBox(width: 420, child: Form(key: formKey, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
      TextFormField(controller: titleController, decoration: InputDecoration(labelText: widget.isIncome ? 'Income details' : 'Expense name', hintText: widget.isIncome ? 'e.g. Paddy sale' : 'e.g. Urea fertilizer'), validator: (v) => v == null || v.trim().isEmpty ? 'Please enter a name' : null),
      const SizedBox(height: 12),
      TextFormField(controller: amountController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Amount (₹)', prefixText: '₹ '), validator: (v) { final n = double.tryParse(v ?? ''); return n == null || n <= 0 ? 'Enter an amount greater than zero' : null; }),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(value: crop, decoration: const InputDecoration(labelText: 'Crop'), items: ['Paddy', 'Cotton', 'Chilli', 'Maize', 'Groundnut', 'Turmeric', 'Vegetables', 'Other'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) => setState(() => crop = v ?? 'Paddy')),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(value: category, decoration: const InputDecoration(labelText: 'Category'), items: categories.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) => setState(() => category = v ?? categories.first)),
      const SizedBox(height: 12),
      Row(children: [const Icon(Icons.calendar_month, color: Colors.green), const SizedBox(width: 8), Expanded(child: Text('${date.day}/${date.month}/${date.year}')), TextButton(onPressed: () async { final chosen = await showDatePicker(context: context, initialDate: date, firstDate: DateTime(2000), lastDate: DateTime.now().add(const Duration(days: 3650))); if (chosen != null) setState(() => date = chosen); }, child: const Text('Choose date'))]),
    ])))),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
      FilledButton(onPressed: () { if (!formKey.currentState!.validate()) return; Navigator.pop(context, FarmRecord(id: DateTime.now().microsecondsSinceEpoch.toString(), title: titleController.text.trim(), crop: crop, category: category, amount: double.parse(amountController.text.trim()), isIncome: widget.isIncome, date: date)); }, child: const Text('Save Record')),
    ],
  );
}
