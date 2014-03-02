import 'dart:html';
import 'dom_node.dart';


class WebEditor {
	WebEditor(String selector)
	{
		querySelector(selector)
    		..onKeyDown.listen(this.handleOnKeyDown)
    		..onKeyPress.listen(this.handleOnKeyPress);
	}

	void handleOnKeyDown(KeyboardEvent keyboardEvent)
	{
		// Tell the browser to not handle this button
		keyboardEvent.preventDefault();
	}

	void handleOnKeyPress(KeyboardEvent keyboardEvent)
	{
		DomNode domNode = new DomNode(keyboardEvent.target);
		int keyCode     = keyboardEvent.keyCode;

		print("handleOnKeyPress: " + keyCode.toString());

		switch (keyCode) {
			case KeyCode.BACKSPACE:
				handleBackSpace(domNode);
				break;
			case KeyCode.ENTER:
				handleCarriageReturn(domNode);
				break;
			default:
				if (keyCode >= 32) {
					handleNoneFunctionalButton(domNode, keyCode);
				}
		}

		// Tell the browser to not handle this button
		keyboardEvent.preventDefault();
	}

	void addHtmlAndProcessLinebreak(domNode, html)
	{
		List<DomNode> childNodes = domNode.getChildNodes();
		int length = childNodes.length;
		if (length >= 2
				&& childNodes[length - 2].getNodeName() == "br"
				&& childNodes[length - 1].getNodeName() == "br") {
			childNodes[length - 1].remove();
		}

		if (childNodes.length == 1
				&& childNodes[0].getType() == Node.TEXT_NODE
				&& domNode.getInnerHtml().length == 1) {
			domNode.setInnerHtml('<br />');
		}

		String newHtml = domNode.getInnerHtml() + html;
		domNode.setInnerHtml(newHtml);
	}

	DomNode getLastFilledTextNode(domNode)
	{
		DomNode lastTextNode = null;

		if (domNode.getType() == Node.TEXT_NODE) {
			return domNode;
		}

		List<DomNode> childNodes = domNode.getChildNodes();
		for (var i = childNodes.length - 1; i >= 0; i--) {
			DomNode childNode = childNodes[i];
			if (childNode.getType() == Node.TEXT_NODE) {
				return domNode;
			} else {
				getLastFilledTextNode(childNode);
			}
		}

		return null;
	}

	void handleBackSpace(domNode)
	{
		DomNode lastTextNode = getLastFilledTextNode(domNode);
		DomNode lastChild = domNode.getLastChild();

		String currentText = domNode.getInnerHtml();
		String newText = currentText.substring(0, currentText.length - 1);
		domNode.setInnerHtml(newText);
	}

	void handleCarriageReturn(domNode)
	{
		DomNode lastChild = domNode.getLastChild();

		String htmlToAdd = null;
		if (lastChild.getNodeName() == 'br') {
			htmlToAdd = '<br />';
		} else {
			htmlToAdd = '<br /><br />';
		}

		String newHtml = domNode.getInnerHtml() + htmlToAdd;
		domNode.setInnerHtml(newHtml);
	}

	void handleNoneFunctionalButton(domNode, charCode)
	{
		addHtmlAndProcessLinebreak(domNode, new String.fromCharCode(charCode));
	}
}
