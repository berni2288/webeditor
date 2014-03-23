library webeditor;


import 'dart:html';


part 'dom_node.dart';
part 'web_editor.dart';
part 'cursor.dart';
part 'toolbar.dart';


WebEditor webEditor;


void main()
{
	webEditor = new WebEditor("#editable");
}
