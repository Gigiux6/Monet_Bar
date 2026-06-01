import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/menu_model.dart';
import '../../data/services/firestore_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../widgets/app_bar_logo.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final TextEditingController _searchController = TextEditingController();
  MenuCategory _selectedCategory = MenuCategory.caffetteria;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildFallbackIcon(MenuItem item) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: item.isSignature ? AppTheme.accentGold.withOpacity(0.15) : AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: item.isSignature ? AppTheme.accentGold : Colors.transparent, width: 1),
      ),
      child: Icon(_getIconForName(item.iconName), color: item.isSignature ? AppTheme.accentAmber : AppTheme.accentGold, size: 26),
    );
  }

  IconData _getIconForName(String? iconName) {
    switch (iconName) {
      case 'local_cafe':
        return Icons.local_cafe_outlined;
      case 'coffee':
        return Icons.coffee_outlined;
      case 'local_bar':
        return Icons.local_bar_outlined;
      case 'cake':
        return Icons.cake_outlined;
      case 'bakery_dining':
        return Icons.bakery_dining_outlined;
      case 'liquor':
        return Icons.liquor_outlined;
      case 'breakfast_dining':
        return Icons.breakfast_dining_outlined;
      case 'local_pizza':
        return Icons.local_pizza_outlined;
      case 'dinner_dining':
        return Icons.dinner_dining_outlined;
      default:
        return Icons.restaurant_menu_outlined;
    }
  }

  void _showItemDetails(MenuItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            border: Border(
              top: BorderSide(color: AppTheme.accentGold, width: 1.5),
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bottomsheet Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.textMuted.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              if (item.imageUrl != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 300),
                    child: CachedNetworkImage(
                      imageUrl: item.imageUrl!,
                      width: double.infinity,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => Container(height: 200, color: AppTheme.cardDark, child: const Center(child: CircularProgressIndicator())),
                      errorWidget: (context, url, error) => const SizedBox.shrink(),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Title and Price Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      item.name,
                      style: GoogleFonts.playfairDisplay(
                        color: AppTheme.textCream,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    '${item.price.toStringAsFixed(2)}€',
                    style: GoogleFonts.playfairDisplay(
                      color: AppTheme.accentGold,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Category Badge and Signature
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.cardDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.accentGold.withOpacity(0.4), width: 1),
                    ),
                    child: Text(
                      item.category.displayName,
                      style: GoogleFonts.outfit(
                        color: AppTheme.accentGold,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (item.isSignature) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.accentAmber.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.accentAmber, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: AppTheme.accentAmber, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            'Consigliato',
                            style: GoogleFonts.outfit(
                              color: AppTheme.accentAmber,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ]
                ],
              ),
              const SizedBox(height: 20),

              // Description
              Text(
                'Descrizione',
                style: GoogleFonts.playfairDisplay(
                  color: AppTheme.textCream,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                item.description,
                style: GoogleFonts.outfit(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),

              // Ingredients
              Text(
                'Ingredienti & Dettagli',
                style: GoogleFonts.playfairDisplay(
                  color: AppTheme.textCream,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: item.ingredients.map((ing) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.cardDark,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Text(
                      ing,
                      style: GoogleFonts.outfit(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),

              // Dismiss button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentGold,
                    foregroundColor: AppTheme.backgroundDark,
                  ),
                  child: const Text('CHIUDI DETTAGLIO'),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'IL MENÙ',
          style: GoogleFonts.playfairDisplay(
            color: AppTheme.textCream,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
        actions: const [AppBarLogo()],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
              style: GoogleFonts.outfit(color: AppTheme.textCream),
              decoration: InputDecoration(
                hintText: 'Cerca piatti o ingredienti...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.accentGold),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppTheme.accentGold),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
              ),
            ),
          ),

          // Horizontal Category Pills
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
                      if (selected) {
                        setState(() {
                          _selectedCategory = cat;
                        });
                      }
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

          // Menu Items List
          Expanded(
            child: StreamBuilder<List<MenuItem>>(
              stream: FirestoreService().menuItemsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Errore nel caricamento del menù',
                      style: GoogleFonts.outfit(color: AppTheme.textCream),
                    ),
                  );
                }

                final List<MenuItem> rawList = snapshot.data ?? [];
                
                // Filter by category & search query
                final List<MenuItem> filteredList = rawList.where((item) {
                  final matchesCategory = item.category == _selectedCategory;
                  final matchesSearch = _searchQuery.isEmpty ||
                      item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                      item.ingredients.any((ing) => ing.toLowerCase().contains(_searchQuery.toLowerCase()));
                  return matchesCategory && matchesSearch;
                }).toList();

                if (filteredList.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 60, color: AppTheme.textMuted.withOpacity(0.5)),
                        const SizedBox(height: 12),
                        Text(
                          'Nessun elemento trovato per la ricerca',
                          style: GoogleFonts.outfit(color: AppTheme.textMuted, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
                  physics: const BouncingScrollPhysics(),
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    final item = filteredList[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      decoration: AppTheme.glassCard(
                        borderColor: item.isSignature
                            ? AppTheme.accentGold.withOpacity(0.5)
                            : AppTheme.accentGold.withOpacity(0.15),
                      ),
                      child: InkWell(
                        onTap: () => _showItemDetails(item),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              // Category Icon or Image
                              if (item.imageUrl != null)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: CachedNetworkImage(
                                    imageUrl: item.imageUrl!,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(width: 50, height: 50, color: AppTheme.cardDark, child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))),
                                    errorWidget: (context, url, error) => _buildFallbackIcon(item),
                                  ),
                                )
                              else
                                _buildFallbackIcon(item),
                              const SizedBox(width: 16),

                              // Title and Description
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item.name,
                                            style: GoogleFonts.playfairDisplay(
                                              color: AppTheme.textCream,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (item.isSignature) ...[
                                          const SizedBox(width: 6),
                                          const Icon(
                                            Icons.star,
                                            color: AppTheme.accentAmber,
                                            size: 14,
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.description,
                                      style: GoogleFonts.outfit(
                                        color: AppTheme.textSecondary,
                                        fontSize: 12,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Price tag
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${item.price.toStringAsFixed(2)}€',
                                    style: GoogleFonts.playfairDisplay(
                                      color: AppTheme.accentGold,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Icon(
                                    Icons.chevron_right,
                                    color: AppTheme.textMuted,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
