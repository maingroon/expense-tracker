import 'package:expense_tracker/models/category_model.dart';
import 'package:expense_tracker/screens/widgets/buttons_presets.dart';
import 'package:expense_tracker/services/theme_provider.dart';
import 'package:flutter/material.dart';

class SaveCategoryWidget extends StatefulWidget {
  const SaveCategoryWidget({
    required this.category,
    required this.onSave,
    super.key,
  });

  final Category category;
  final void Function(Category category) onSave;

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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 15,
        left: 15,
        right: 15,
        bottom: 15 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
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
              horizontal: 25,
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
                  icon: Icons.apps_rounded,
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
                  icon: Icons.palette,
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => CategoryColorDialodWidget(
                        onClorSelected: (color) {
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
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: FilledButton(
              onPressed: () {
                widget.onSave(
                  Category(
                    id: widget.category.id,
                    name: _nameController.text,
                    icon: _selectedIcon,
                    color: _selectedColor,
                    type: _selectedType,
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
                'Types',
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

  final void Function(IconData icon) onIconSelected;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(),
    );
  }
}

class CategoryColorDialodWidget extends StatelessWidget {
  const CategoryColorDialodWidget({
    required this.onClorSelected,
    super.key,
  });

  final void Function(Color color) onClorSelected;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(),
    );
  }
}
