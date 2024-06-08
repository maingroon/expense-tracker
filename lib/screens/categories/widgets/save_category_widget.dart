import 'package:expense_tracker/models/category_model.dart';
import 'package:expense_tracker/screens/widgets/buttons_presets.dart';
import 'package:expense_tracker/services/theme_provider.dart';
import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category.name);
    _selectedType = widget.category.type;
    _selectedIcon = widget.category.icon;
    _selectedColor = widget.category.color;
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
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
        onPressed: () {
          widget.onSave(
            Category(
              id: widget.category.id,
              name: _nameController.text,
              icon: _selectedIcon,
              color: _selectedColor,
              type: _selectedType,
              position: widget.category.position,
            ),
          );
        },
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
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
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(
                    Radius.circular(10),
                  ),
                ),
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
                      builder: (context) => CategoryTypeDialodWidget(
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
                      builder: (context) => CategoryIconDialodWidget(
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
                      builder: (context) => CategoryColorDialodWidget(
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

class CategoryTypeDialodWidget extends StatelessWidget {
  const CategoryTypeDialodWidget({
    required this.onTypeSelected,
    super.key,
  });

  final void Function(CategoryType type) onTypeSelected;

  @override
  Widget build(BuildContext context) {
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
                      shadows: ThemeProvider().getIconsShadows(),
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

class CategoryIconDialodWidget extends StatelessWidget {
  const CategoryIconDialodWidget({
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

class CategoryColorDialodWidget extends StatelessWidget {
  const CategoryColorDialodWidget({
    required this.onColorSelected,
    super.key,
  });

  static List<Color> availableColors = [
    Colors.red,
    Colors.redAccent,
    Colors.pink,
    Colors.pinkAccent,
    Colors.purple,
    Colors.purpleAccent,
    Colors.deepPurple,
    Colors.deepPurpleAccent,
    Colors.indigo,
    Colors.indigoAccent,
    Colors.blue,
    Colors.blueAccent,
    Colors.blueGrey,
    Colors.lightBlue,
    Colors.lightBlueAccent,
    Colors.cyan,
    Colors.cyanAccent,
    Colors.teal,
    Colors.tealAccent,
    Colors.green,
    Colors.greenAccent,
    Colors.lightGreen,
    Colors.lightGreenAccent,
    Colors.lime,
    Colors.limeAccent,
    Colors.yellow,
    Colors.yellowAccent,
    Colors.amber,
    Colors.amberAccent,
    Colors.orange,
    Colors.orangeAccent,
    Colors.deepOrange,
    Colors.deepOrangeAccent,
    Colors.brown,
    Colors.grey,
    Colors.black26,
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
                    child: GestureDetector(
                      onTap: () {
                        onColorSelected(color);
                        Navigator.pop(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color,
                        ),
                      ),
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
