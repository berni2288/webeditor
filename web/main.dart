library webeditor;


import 'dart:html';


part 'dom_node.dart';
part 'cursor.dart';
part 'web_editor.dart';


WebEditor webEditor;


void main()
{
	webEditor = new WebEditor("#editable");
}
