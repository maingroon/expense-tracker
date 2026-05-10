import 'package:expense_tracker/models/category_model.dart';
import 'package:expense_tracker/screens/widgets/buttons_presets.dart';
import 'package:expense_tracker/services/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SaveCategoryWidget extends StatefulWidget {
  const SaveCategoryWidget({
    required this.category,
    required this.onDelete,
    required this.onArchive,
    required this.onSave,
    required this.saveMode,
    super.key,
  });

  final Category category;
  final void Function(Category category) onDelete;
  final void Function(Category category) onArchive;
  final void Function(Category category) onSave;
  final CategorySaveMode saveMode;

  @override
  State<SaveCategoryWidget> createState() {
    return _SaveCategoryWidgetState();
  }
}

class _SaveCategoryWidgetState extends State<SaveCategoryWidget> {
  late TextEditingController _nameController;
  late CategoryType _selectedType;
  late IconData _selectedIcon;
  late Color _selectedColor;
  late bool _nameIsValid;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category.name);
    _selectedType = widget.category.type;
    _selectedIcon = widget.category.icon;
    _selectedColor = widget.category.color;
    _nameIsValid = widget.category.name.trim().isNotEmpty;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  List<Widget> _buildActionButtons() {
    List<Widget> actionButtons = [];
    if (widget.saveMode == CategorySaveMode.edit) {
      actionButtons.add(
        OutlinedButton(
          onPressed: () {
            widget.onDelete(widget.category);
          },
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 10,
            ),
          ),
          child: const Text(
            'Delete',
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
      actionButtons.add(
        OutlinedButton(
          onPressed: () {
            widget.onArchive(widget.category);
          },
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 10,
            ),
          ),
          child: const Text(
            'Archive',
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    actionButtons.add(
      FilledButton(
        onPressed: _nameIsValid
            ? () {
                widget.onSave(
                  Category(
                    id: widget.category.id,
                    name: _nameController.text.trim(),
                    icon: _selectedIcon,
                    color: _selectedColor,
                    type: _selectedType,
                    position: widget.category.position,
                  ),
                );
              }
            : null,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 10,
          ),
        ),
        child: const Text(
          'Save',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );

    return actionButtons;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 15,
        left: 15,
        right: 15,
        bottom: 10 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 10,
              horizontal: 10,
            ),
            child: TextField(
              controller: _nameController,
              keyboardType: TextInputType.text,
              maxLines: 1,
              autofocus: true,
              onChanged: (value) {
                setState(() {
                  _nameIsValid = value.trim().isNotEmpty;
                });
              },
              decoration: InputDecoration(
                labelText: 'Name',
                errorText: _nameIsValid ? null : 'Name cannot be empty',
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 10,
              horizontal: 10,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                GenericOutlinedIconWithLabelButton(
                  icon: CategoryType.getIcon(_selectedType),
                  label: CategoryType.getName(_selectedType),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => CategoryTypeDialogWidget(
                        onTypeSelected: (type) {
                          setState(() {
                            _selectedType = type;
                          });
                        },
                      ),
                    );
                  },
                ),
                GenericOutlinedIconButton(
                  icon: _selectedIcon,
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => CategoryIconDialogWidget(
                        onIconSelected: (icon) {
                          setState(() {
                            _selectedIcon = icon;
                          });
                        },
                      ),
                    );
                  },
                ),
                GenericOutlinedIconButton(
                  icon: Icons.circle,
                  iconColor: _selectedColor,
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => CategoryColorDialogWidget(
                        onColorSelected: (color) {
                          setState(() {
                            _selectedColor = color;
                          });
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 10,
              horizontal: 10,
            ),
            child: Row(
              mainAxisAlignment: widget.saveMode == CategorySaveMode.edit
                  ? MainAxisAlignment.spaceBetween
                  : MainAxisAlignment.end,
              children: _buildActionButtons(),
            ),
          ),
        ],
      ),
    );
  }
}

class CategoryTypeDialogWidget extends StatelessWidget {
  const CategoryTypeDialogWidget({
    required this.onTypeSelected,
    super.key,
  });

  final void Function(CategoryType type) onTypeSelected;

  @override
  Widget build(BuildContext context) {
    final shadows = context.watch<ThemeProvider>().getIconsShadows();
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
        ),
        padding: const EdgeInsets.only(
          top: 10,
          bottom: 20,
          right: 20,
          left: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              alignment: Alignment.topLeft,
              padding: const EdgeInsets.symmetric(
                vertical: 15,
                horizontal: 10,
              ),
              child: const Text(
                'Type',
                style: TextStyle(fontSize: 20),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              itemCount: CategoryType.values.length,
              itemBuilder: (ctx, index) {
                final type = CategoryType.values[index];
                return Card(
                  child: ListTile(
                    leading: Icon(
                      CategoryType.getIcon(type),
                      color: CategoryType.getColor(type),
                      shadows: shadows,
                    ),
                    title: Text(
                      CategoryType.getName(type),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () {
                      onTypeSelected(type);
                      Navigator.pop(context);
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class CategoryIconDialogWidget extends StatelessWidget {
  const CategoryIconDialogWidget({
    required this.onIconSelected,
    super.key,
  });

  static List<IconData> availableIcons = [
    Icons.shopping_cart,
    Icons.payments,
    Icons.shopping_bag,
    Icons.credit_card,
    Icons.receipt,
    Icons.attach_money,
    Icons.storefront,
    Icons.trending_up,
    Icons.trending_down,
    Icons.home,
    Icons.sell,
    Icons.account_balance,
    Icons.work,
    Icons.paid,
    Icons.account_balance_wallet,
    Icons.savings,
    Icons.store,
    Icons.monetization_on,
    Icons.currency_exchange,
    Icons.shopping_basket,
    Icons.currency_bitcoin,
    Icons.schedule,
    Icons.language,
    Icons.lightbulb,
    Icons.question_mark,
    Icons.category,
    Icons.interests,
    Icons.build,
    Icons.mail,
    Icons.call,
    Icons.notifications,
    Icons.chat,
    Icons.smartphone,
    Icons.print,
    Icons.computer,
    Icons.devices,
    Icons.desktop_windows,
    Icons.dns,
    Icons.headphones,
    Icons.memory,
    Icons.tv,
    Icons.watch,
    Icons.laptop_windows,
    Icons.router,
    Icons.devices_other,
    Icons.bed,
    Icons.chair,
    Icons.coffee,
    Icons.checkroom,
    Icons.kitchen,
    Icons.yard,
    Icons.garage,
    Icons.energy_savings_leaf,
    Icons.flatware,
    Icons.restaurant,
    Icons.local_mall,
    Icons.business_center,
    Icons.fastfood,
    Icons.local_hospital,
    Icons.local_gas_station,
    Icons.ev_station,
    Icons.brush,
    Icons.directions_car,
    Icons.directions_bike,
    Icons.directions_boat,
    Icons.directions_bus,
    Icons.train,
    Icons.airplanemode_active,
    Icons.local_taxi,
    Icons.fitness_center,
    Icons.apartment,
    Icons.local_bar,
    Icons.luggage,
    Icons.casino,
    Icons.school,
    Icons.campaign,
    Icons.construction,
    Icons.engineering,
    Icons.volunteer_activism,
    Icons.science,
    Icons.cake,
    Icons.self_improvement,
    Icons.sports_soccer,
    Icons.biotech,
    Icons.hiking,
    Icons.architecture,
    Icons.theaters,
    Icons.subscriptions,
    Icons.video_library,
    Icons.library_music,
    Icons.podcasts,
    Icons.health_and_safety,
    Icons.sports_esports,
  ];

  final void Function(IconData icon) onIconSelected;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 150,
      ),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
        ),
        padding: const EdgeInsets.only(
          top: 10,
          bottom: 20,
          right: 20,
          left: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              alignment: Alignment.topLeft,
              padding: const EdgeInsets.symmetric(
                vertical: 15,
                horizontal: 10,
              ),
              child: const Text(
                'Icon',
                style: TextStyle(fontSize: 20),
              ),
            ),
            Expanded(
              child: GridView.count(
                crossAxisCount: 5,
                shrinkWrap: true,
                children: availableIcons.map((icon) {
                  return Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: GenericOutlinedIconButton(
                      icon: icon,
                      onPressed: () {
                        onIconSelected(icon);
                        Navigator.pop(context);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CategoryColorDialogWidget extends StatelessWidget {
  const CategoryColorDialogWidget({
    required this.onColorSelected,
    super.key,
  });

  // A curated palette of vivid, solid hues that read well on both light and
  // dark surfaces. Ordered by hue so the picker forms a smooth rainbow.
  static const List<Color> availableColors = [
    Color(0xFFE53935), // red
    Color(0xFFEC407A), // pink
    Color(0xFFD81B60), // magenta
    Color(0xFFAB47BC), // purple
    Color(0xFF7E57C2), // light purple
    Color(0xFF5E35B1), // deep purple
    Color(0xFF5C6BC0), // indigo
    Color(0xFF3F51B5), // strong indigo
    Color(0xFF1E88E5), // blue
    Color(0xFF039BE5), // light blue
    Color(0xFF00ACC1), // cyan
    Color(0xFF26A69A), // teal
    Color(0xFF43A047), // green
    Color(0xFF7CB342), // light green
    Color(0xFF558B2F), // dark green
    Color(0xFFC0CA33), // lime
    Color(0xFFFDD835), // yellow
    Color(0xFFFFB300), // amber
    Color(0xFFFB8C00), // orange
    Color(0xFFF4511E), // deep orange
    Color(0xFF8D6E63), // brown
    Color(0xFF6D4C41), // dark brown
    Color(0xFF78909C), // blue grey
    Color(0xFF546E7A), // slate
  ];

  final void Function(Color color) onColorSelected;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 150,
      ),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
        ),
        padding: const EdgeInsets.only(
          top: 10,
          bottom: 20,
          right: 20,
          left: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              alignment: Alignment.topLeft,
              padding: const EdgeInsets.symmetric(
                vertical: 15,
                horizontal: 10,
              ),
              child: const Text(
                'Color',
                style: TextStyle(fontSize: 20),
              ),
            ),
            Expanded(
              child: GridView.count(
                crossAxisCount: 5,
                shrinkWrap: true,
                children: availableColors.map((color) {
                  return Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: _ColorSwatch(
                      color: color,
                      onTap: () {
                        onColorSelected(color);
                        Navigator.pop(context);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({required this.color, required this.onTap});

  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brightness = ThemeData.estimateBrightnessForColor(color);
    final ringColor = brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.35)
        : Colors.black.withValues(alpha: 0.18);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(color: ringColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.35),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
      ),
    );
  }
}
