import 'package:expense_tracker/models/category_model.dart';
import 'package:expense_tracker/screens/widgets/buttons_presets.dart';
import 'package:expense_tracker/services/theme_provider.dart';
import 'package:flutter/material.dart';

class SaveCategoryWidget extends StatefulWidget {
  const SaveCategoryWidget({
    required this.category,
    required this.onDelete,
    required this.onSave,
    required this.saveMode,
    super.key,
  });

  final Category category;
  final void Function(Category category) onDelete;
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

  List<Shadow> _getCategoryIconShadows() {
    if (ThemeProvider().getCurrentBrightness() == Brightness.light) {
      return const [
        Shadow(
          blurRadius: 5,
          color: Colors.grey,
          offset: Offset(1, 1),
        ),
      ];
    } else {
      return [];
    }
  }

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
                      shadows: _getCategoryIconShadows(),
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
    Icons.category,
    Icons.food_bank,
    Icons.fastfood,
    Icons.local_drink,
    Icons.shopping_cart,
    Icons.local_mall,
    Icons.local_gas_station,
    Icons.local_hospital,
    Icons.local_laundry_service,
    Icons.local_pharmacy,
    Icons.local_offer,
    Icons.local_parking,
    Icons.local_play,
    Icons.local_see,
    Icons.local_shipping,
    Icons.local_taxi,
    Icons.local_atm,
    Icons.local_bar,
    Icons.local_cafe,
    Icons.local_car_wash,
    Icons.local_convenience_store,
    Icons.local_dining,
    Icons.local_drink,
    Icons.local_fire_department,
    Icons.local_florist,
    Icons.local_grocery_store,
    Icons.local_hospital,
    Icons.local_hotel,
    Icons.local_library,
    Icons.local_movies,
    Icons.local_pizza,
    Icons.local_police,
    Icons.local_post_office,
    Icons.local_printshop,
    Icons.local_car_wash,
    Icons.local_convenience_store,
    Icons.local_dining,
    Icons.local_drink,
    Icons.local_fire_department,
    Icons.local_florist,
    Icons.local_grocery_store,
    Icons.local_hospital,
    Icons.local_hotel,
    Icons.local_library,
    Icons.local_movies,
    Icons.local_pizza,
    Icons.local_police,
    Icons.local_post_office,
    Icons.local_printshop,
    Icons.local_shipping,
    Icons.local_taxi,
    Icons.local_atm,
    Icons.local_bar,
    Icons.local_cafe,
    Icons.local_car_wash,
    Icons.local_convenience_store,
    Icons.local_dining,
    Icons.local_drink,
    Icons.local_fire_department,
    Icons.local_florist,
    Icons.local_grocery_store,
    Icons.local_hospital,
    Icons.local_hotel,
    Icons.local_library,
    Icons.local_movies,
    Icons.local_pizza,
    Icons.local_police,
    Icons.local_post_office,
    Icons.local_printshop,
    Icons.local_shipping,
    Icons.local_taxi,
    Icons.local_atm,
    Icons.local_bar,
    Icons.local_cafe,
    Icons.local_car_wash,
    Icons.local_convenience_store,
    Icons.local_dining,
    Icons.local_drink,
    Icons.local_fire_department,
    Icons.local_florist,
    Icons.local_grocery_store,
    Icons.local_hospital,
    Icons.local_hotel
  ];

  final void Function(IconData icon) onIconSelected;

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
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
    Colors.blueGrey,
  ];

  final void Function(Color color) onColorSelected;

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
