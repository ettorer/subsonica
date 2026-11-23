import 'dart:js_interop';

@JS('document')
external _PageDocument get _pageDocument;

extension type _PageDocument(JSObject _) implements JSObject {
  external bool get hidden;
  external void addEventListener(JSString type, JSFunction listener);
}

void watchPageHide(void Function() onHide) {
  _pageDocument.addEventListener(
    'visibilitychange'.toJS,
    ((JSAny? _) {
      if (_pageDocument.hidden) onHide();
    }).toJS,
  );
  _pageDocument.addEventListener(
    'pagehide'.toJS,
    ((JSAny? _) => onHide()).toJS,
  );
}
