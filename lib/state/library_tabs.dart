import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

class LibraryTabs extends ChangeNotifier {
  var index = 0;

  void select(int index) {
    this.index = index;
    notifyListeners();
  }
}

void goToLibraryTab(BuildContext context, int index) {
  context.read<LibraryTabs>().select(index);
  Navigator.of(context).popUntil((route) => route.isFirst);
}
