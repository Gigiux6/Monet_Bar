import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/firestore_service.dart';
import '../../data/models/menu_model.dart';
import '../../data/models/reward_model.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../widgets/app_bar_logo.dart';

class AdminMenuSettingsScreen extends StatelessWidget {
  const AdminMenuSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'GESTIONE MENU E PREMI',
            style: GoogleFonts.playfairDisplay(
              color: AppTheme.textCream,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          centerTitle: true,
          actions: const [AppBarLogo()],
          bottom: const TabBar(
            indicatorColor: AppTheme.accentGold,
            labelColor: AppTheme.accentGold,
            unselectedLabelColor: AppTheme.textSecondary,
            tabs: [
              Tab(icon: Icon(Icons.restaurant_menu), text: 'Prodotti'),
              Tab(icon: Icon(Icons.card_giftcard), text: 'Premi'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _ProductsTab(),
            _RewardsTab(),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// PRODOTTI
// ==========================================

class _ProductsTab extends StatefulWidget {
  const _ProductsTab();
  @override
  State<_ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends State<_ProductsTab> {
  MenuCategory _selectedCategory = MenuCategory.caffetteria;

  void _showProductForm({MenuItem? item}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: AppTheme.backgroundDark,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _ProductForm(
              itemToEdit: item,
              onSaved: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
    );
  }

  void _deleteProduct(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: Text('Elimina Prodotto', style: GoogleFonts.outfit(color: AppTheme.textCream)),
        content: Text('Sei sicuro di voler eliminare questo prodotto?', style: GoogleFonts.outfit(color: AppTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annulla')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Elimina', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await FirestoreService().deleteMenuItem(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Prodotto eliminato!'), backgroundColor: Colors.redAccent));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Errore: $e'), backgroundColor: Colors.redAccent));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: () => _showProductForm(),
            icon: const Icon(Icons.add),
            label: const Text('AGGIUNGI NUOVO PRODOTTO'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentGold,
              foregroundColor: AppTheme.backgroundDark,
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
        ),
        // Categorie
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: MenuCategory.values.length,
            itemBuilder: (context, index) {
              final cat = MenuCategory.values[index];
              final isSelected = cat == _selectedCategory;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6.0),
                child: ChoiceChip(
                  label: Text(
                    cat.displayName,
                    style: GoogleFonts.outfit(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? AppTheme.backgroundDark : AppTheme.textSecondary,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: AppTheme.accentGold,
                  backgroundColor: AppTheme.cardDark,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedCategory = cat);
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected ? AppTheme.accentGold : AppTheme.accentGold.withOpacity(0.15),
                    ),
                  ),
                  showCheckmark: false,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        // Lista Prodotti
        Expanded(
          child: StreamBuilder<List<MenuItem>>(
            stream: FirestoreService().menuItemsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              final list = (snapshot.data ?? []).where((item) => item.category == _selectedCategory).toList();
              if (list.isEmpty) {
                return Center(child: Text('Nessun prodotto in questa categoria.', style: GoogleFonts.outfit(color: AppTheme.textMuted)));
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final item = list[index];
                  return Card(
                    color: AppTheme.cardDark,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: AppTheme.accentGold.withOpacity(0.15)),
                    ),
                    child: ListTile(
                      title: Text(item.name, style: GoogleFonts.outfit(color: AppTheme.textCream, fontWeight: FontWeight.bold)),
                      subtitle: Text('${item.price.toStringAsFixed(2)}€', style: GoogleFonts.outfit(color: AppTheme.accentGold)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.edit, color: Colors.blueAccent), onPressed: () => _showProductForm(item: item)),
                          IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent), onPressed: () => _deleteProduct(item.id)),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ProductForm extends StatefulWidget {
  final MenuItem? itemToEdit;
  final VoidCallback onSaved;
  const _ProductForm({this.itemToEdit, required this.onSaved});
  @override
  State<_ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<_ProductForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late final TextEditingController _priceController;
  late final TextEditingController _ingredientsController;
  late MenuCategory _category;
  late bool _isSignature;
  bool _isSaving = false;

  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  String? _existingImageUrl;

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 75,
    );
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedImage = image;
        _selectedImageBytes = bytes;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    final item = widget.itemToEdit;
    _nameController = TextEditingController(text: item?.name ?? '');
    _descController = TextEditingController(text: item?.description ?? '');
    _priceController = TextEditingController(text: item != null ? item.price.toStringAsFixed(2) : '');
    _ingredientsController = TextEditingController(text: item?.ingredients.join(', ') ?? '');
    _category = item?.category ?? MenuCategory.caffetteria;
    _isSignature = item?.isSignature ?? false;
    _existingImageUrl = item?.imageUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _ingredientsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      String? finalImageUrl = _existingImageUrl;
      if (_selectedImageBytes != null) {
        final ref = FirebaseStorage.instance.ref().child('menu_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
        await ref.putData(_selectedImageBytes!, SettableMetadata(contentType: 'image/jpeg'));
        finalImageUrl = await ref.getDownloadURL();
      }

      final item = MenuItem(
        id: widget.itemToEdit?.id ?? '', 
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        price: double.parse(_priceController.text.trim().replaceAll(',', '.')),
        category: _category,
        ingredients: _ingredientsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        isSignature: _isSignature,
        iconName: null,
        imageUrl: finalImageUrl,
      );
      if (widget.itemToEdit == null) {
        await FirestoreService().addMenuItem(item);
      } else {
        await FirestoreService().updateMenuItem(item);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Prodotto salvato con successo!'), backgroundColor: Colors.green));
      widget.onSaved();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Errore: $e'), backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.itemToEdit == null ? 'NUOVO PRODOTTO' : 'MODIFICA PRODOTTO', style: GoogleFonts.playfairDisplay(color: AppTheme.textCream, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 150,
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.accentGold.withOpacity(0.5)),
                image: _selectedImageBytes != null
                    ? DecorationImage(image: MemoryImage(_selectedImageBytes!), fit: BoxFit.contain)
                    : ((_existingImageUrl != null && _existingImageUrl!.isNotEmpty)
                        ? DecorationImage(image: NetworkImage(_existingImageUrl!), fit: BoxFit.contain)
                        : null),
              ),
              child: _selectedImageBytes == null && (_existingImageUrl == null || _existingImageUrl!.isEmpty)
                  ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.camera_alt, color: AppTheme.accentGold, size: 40), SizedBox(height: 8), Text('Aggiungi Foto', style: TextStyle(color: AppTheme.textSecondary))]))
                  : Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt, color: Colors.white, size: 32),
                            SizedBox(height: 4),
                            Text('Modifica Foto', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nameController,
            style: GoogleFonts.outfit(color: AppTheme.textCream),
            decoration: const InputDecoration(labelText: 'Nome Prodotto', prefixIcon: Icon(Icons.fastfood, color: AppTheme.accentGold)),
            validator: (v) => v!.trim().isEmpty ? 'Richiesto' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descController,
            style: GoogleFonts.outfit(color: AppTheme.textCream),
            maxLines: null,
            minLines: 3,
            keyboardType: TextInputType.multiline,
            decoration: const InputDecoration(labelText: 'Descrizione', prefixIcon: Icon(Icons.description, color: AppTheme.accentGold)),
            validator: (v) => v!.trim().isEmpty ? 'Richiesta' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _priceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: GoogleFonts.outfit(color: AppTheme.textCream),
            decoration: const InputDecoration(labelText: 'Prezzo (€)', prefixIcon: Icon(Icons.euro, color: AppTheme.accentGold)),
            validator: (v) => double.tryParse(v!.trim().replaceAll(',', '.')) == null ? 'Prezzo non valido' : null,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<MenuCategory>(
            value: _category,
            dropdownColor: AppTheme.surfaceDark,
            decoration: const InputDecoration(labelText: 'Categoria', prefixIcon: Icon(Icons.category, color: AppTheme.accentGold)),
            items: MenuCategory.values.map((cat) => DropdownMenuItem(value: cat, child: Text(cat.displayName, style: GoogleFonts.outfit(color: AppTheme.textCream)))).toList(),
            onChanged: (val) => setState(() => _category = val!),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _ingredientsController,
            style: GoogleFonts.outfit(color: AppTheme.textCream),
            decoration: const InputDecoration(labelText: 'Ingredienti (separati da virgola)', prefixIcon: Icon(Icons.kitchen, color: AppTheme.accentGold)),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: Text('Prodotto Signature', style: GoogleFonts.outfit(color: AppTheme.textCream)),
            activeColor: AppTheme.accentGold,
            value: _isSignature,
            onChanged: (v) => setState(() => _isSignature = v),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isSaving ? null : _submit,
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentGold, foregroundColor: AppTheme.backgroundDark, padding: const EdgeInsets.symmetric(vertical: 16)),
            child: _isSaving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(AppTheme.backgroundDark))) : const Text('SALVA PRODOTTO'),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// PREMI
// ==========================================

class _RewardsTab extends StatefulWidget {
  const _RewardsTab();
  @override
  State<_RewardsTab> createState() => _RewardsTabState();
}

class _RewardsTabState extends State<_RewardsTab> {
  void _showRewardForm({Reward? item}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: AppTheme.backgroundDark,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _RewardForm(
              itemToEdit: item,
              onSaved: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
    );
  }

  void _deleteReward(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: Text('Elimina Premio', style: GoogleFonts.outfit(color: AppTheme.textCream)),
        content: Text('Sei sicuro di voler eliminare questo premio?', style: GoogleFonts.outfit(color: AppTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annulla')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Elimina', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await FirestoreService().deleteReward(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Premio eliminato!'), backgroundColor: Colors.redAccent));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Errore: $e'), backgroundColor: Colors.redAccent));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: () => _showRewardForm(),
            icon: const Icon(Icons.add),
            label: const Text('AGGIUNGI NUOVO PREMIO'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentGold,
              foregroundColor: AppTheme.backgroundDark,
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
        ),
        const TabBar(
          indicatorColor: AppTheme.accentGold,
          labelColor: AppTheme.accentGold,
          unselectedLabelColor: AppTheme.textSecondary,
          tabs: [
            Tab(text: 'Classici'),
            Tab(text: 'Speciali a Data Fissa'),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: StreamBuilder<List<Reward>>(
            stream: FirestoreService().rewardsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              final list = snapshot.data ?? [];
              final classicList = list.where((r) => !r.isSpecial).toList();
              final specialList = list.where((r) => r.isSpecial).toList();
              
              return TabBarView(
                children: [
                  _buildRewardsList(classicList),
                  _buildRewardsList(specialList),
                ],
              );
            },
          ),
        ),
      ],
      ),
    );
  }

  Widget _buildRewardsList(List<Reward> list) {
    if (list.isEmpty) {
      return Center(child: Text('Nessun premio disponibile.', style: GoogleFonts.outfit(color: AppTheme.textMuted)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        return Card(
          color: AppTheme.cardDark,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppTheme.accentGold.withOpacity(0.15)),
          ),
          child: ListTile(
            title: Text(item.title, style: GoogleFonts.outfit(color: AppTheme.textCream, fontWeight: FontWeight.bold)),
            subtitle: Text(
              item.isSpecial ? '${item.pointsCost} punti • Attivo il ${item.terms}' : '${item.pointsCost} punti', 
              style: GoogleFonts.outfit(color: AppTheme.accentGold)
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(icon: const Icon(Icons.edit, color: Colors.blueAccent), onPressed: () => _showRewardForm(item: item)),
                IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent), onPressed: () => _deleteReward(item.id)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RewardForm extends StatefulWidget {
  final Reward? itemToEdit;
  final VoidCallback onSaved;
  const _RewardForm({this.itemToEdit, required this.onSaved});
  @override
  State<_RewardForm> createState() => _RewardFormState();
}

class _RewardFormState extends State<_RewardForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late final TextEditingController _pointsController;
  late final TextEditingController _termsController;
  late final TextEditingController _validityDaysController;
  late bool _isSpecial;
  bool _isSaving = false;

  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  String? _existingImageUrl;

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 75,
    );
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedImage = image;
        _selectedImageBytes = bytes;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    final item = widget.itemToEdit;
    _titleController = TextEditingController(text: item?.title ?? '');
    _descController = TextEditingController(text: item?.description ?? '');
    _pointsController = TextEditingController(text: item != null ? item.pointsCost.toString() : '');
    _termsController = TextEditingController(text: item?.terms ?? '');
    _validityDaysController = TextEditingController(text: item != null ? item.validityDays.toString() : '0');
    _isSpecial = item?.isSpecial ?? false;
    _existingImageUrl = item?.imageUrl;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _pointsController.dispose();
    _termsController.dispose();
    _validityDaysController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      String? finalImageUrl = _existingImageUrl;
      if (_selectedImageBytes != null) {
        final ref = FirebaseStorage.instance.ref().child('rewards_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
        await ref.putData(_selectedImageBytes!, SettableMetadata(contentType: 'image/jpeg'));
        finalImageUrl = await ref.getDownloadURL();
      }

      final reward = Reward(
        id: widget.itemToEdit?.id ?? '',
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        pointsCost: int.parse(_pointsController.text.trim()),
        terms: _isSpecial ? _termsController.text.trim() : '',
        iconName: '',
        imageUrl: finalImageUrl,
        isSpecial: _isSpecial,
        validityDays: _isSpecial ? (int.tryParse(_validityDaysController.text.trim()) ?? 0) : 0,
      );
      if (widget.itemToEdit == null) {
        await FirestoreService().addReward(reward);
      } else {
        await FirestoreService().updateReward(reward);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Premio salvato con successo!'), backgroundColor: Colors.green));
      widget.onSaved();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Errore: $e'), backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.itemToEdit == null ? 'NUOVO PREMIO' : 'MODIFICA PREMIO', style: GoogleFonts.playfairDisplay(color: AppTheme.textCream, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 150,
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.accentGold.withOpacity(0.5)),
                image: _selectedImageBytes != null
                    ? DecorationImage(image: MemoryImage(_selectedImageBytes!), fit: BoxFit.contain)
                    : ((_existingImageUrl != null && _existingImageUrl!.isNotEmpty)
                        ? DecorationImage(image: NetworkImage(_existingImageUrl!), fit: BoxFit.contain)
                        : null),
              ),
              child: _selectedImageBytes == null && (_existingImageUrl == null || _existingImageUrl!.isEmpty)
                  ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.camera_alt, color: AppTheme.accentGold, size: 40), SizedBox(height: 8), Text('Aggiungi Foto', style: TextStyle(color: AppTheme.textSecondary))]))
                  : Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt, color: Colors.white, size: 32),
                            SizedBox(height: 4),
                            Text('Modifica Foto', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _titleController,
            style: GoogleFonts.outfit(color: AppTheme.textCream),
            decoration: const InputDecoration(labelText: 'Titolo Premio', prefixIcon: Icon(Icons.star, color: AppTheme.accentGold)),
            validator: (v) => v!.trim().isEmpty ? 'Richiesto' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descController,
            style: GoogleFonts.outfit(color: AppTheme.textCream),
            maxLines: null,
            minLines: 3,
            keyboardType: TextInputType.multiline,
            decoration: const InputDecoration(labelText: 'Descrizione', prefixIcon: Icon(Icons.description, color: AppTheme.accentGold)),
            validator: (v) => v!.trim().isEmpty ? 'Richiesta' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _pointsController,
            keyboardType: TextInputType.number,
            style: GoogleFonts.outfit(color: AppTheme.textCream),
            decoration: const InputDecoration(labelText: 'Costo in Punti (0 per regalo gratuito)', prefixIcon: Icon(Icons.toll, color: AppTheme.accentGold)),
            validator: (v) => int.tryParse(v!.trim()) == null ? 'Valore intero non valido' : null,
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: Text('Premio Speciale a Calendario', style: GoogleFonts.outfit(color: AppTheme.textCream)),
            subtitle: Text('Es: festività fisse o eventi particolari uguali per tutti.', style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 12)),
            activeColor: AppTheme.accentGold,
            value: _isSpecial,
            onChanged: (v) => setState(() => _isSpecial = v),
          ),
          if (_isSpecial) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _termsController,
              style: GoogleFonts.outfit(color: AppTheme.textCream),
              decoration: const InputDecoration(
                labelText: 'Data di attivazione (Giorno-Mese, es: 25-12 per Natale)', 
                prefixIcon: Icon(Icons.calendar_today, color: AppTheme.accentGold)
              ),
              validator: (v) {
                if (!_isSpecial) return null;
                final val = v!.trim();
                if (val.isEmpty) return 'Richiesto per i premi speciali';
                final parts = val.split('-');
                if (parts.length != 2) return 'Formato non valido (usa GG-MM)';
                if (int.tryParse(parts[0]) == null || int.tryParse(parts[1]) == null) return 'Formato non valido';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _validityDaysController,
              keyboardType: TextInputType.number,
              style: GoogleFonts.outfit(color: AppTheme.textCream),
              decoration: const InputDecoration(
                labelText: 'Giorni di tolleranza (es. 3 per renderlo valido ±3 giorni)', 
                prefixIcon: Icon(Icons.timer_outlined, color: AppTheme.accentGold)
              ),
              validator: (v) {
                if (!_isSpecial) return null;
                if (int.tryParse(v!.trim()) == null) return 'Inserisci un numero valido (0 per solo il giorno esatto)';
                return null;
              },
            ),
          ],
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isSaving ? null : _submit,
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentGold, foregroundColor: AppTheme.backgroundDark, padding: const EdgeInsets.symmetric(vertical: 16)),
            child: _isSaving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(AppTheme.backgroundDark))) : const Text('SALVA PREMIO'),
          ),
        ],
      ),
    );
  }
}
