import 'dart:html';
import 'dom_node.dart';


class WebEditor {
	DomNode editable;
	/*
	 * Only set when the editable has focus
	 */
	DomNode endBreak;

	/*
	 * A list of HTML elements that can be removed by the backspace button
	 */
	List deletableElements = [
		"br",
		"img",
		"table"
	];

	WebEditor(String selector) {
		Element editableElement = querySelector(selector);
		this.editable = new DomNode(editableElement);

		editableElement
				..onKeyDown.listen(this.handleOnKeyDown)
				..onKeyPress.listen(this.handleOnKeyPress)
				..onFocus.listen(handleOnFocus)
				..onBlur.listen(handleOnBlur);
	}

	handleOnKeyDown(KeyboardEvent keyboardEvent) {
		DomNode domNode = new DomNode(keyboardEvent.target);
		int keyCode = keyboardEvent.keyCode;

		switch (keyCode) {
			case KeyCode.BACKSPACE:
				handleBackSpace(domNode);
				break;
			case KeyCode.P:
				handleBackSpace(domNode);
				break;
			case KeyCode.ENTER:
				handleEnter(domNode);
				break;
			default:
				// Don't do anything
				return;
		}

		// Tell the browser to not handle this button
		keyboardEvent.preventDefault();
	}

	handleOnKeyPress(KeyboardEvent keyboardEvent) {
		DomNode domNode = new DomNode(keyboardEvent.target);
		int keyCode = keyboardEvent.keyCode;

		print("handleOnKeyPress: " + keyCode.toString());

		if (keyCode < 32) {
			// We don't handle functional keys in here
			return;
		}

		handleNoneFunctionalButton(domNode, keyCode);

		// Tell the browser to not handle this button
		keyboardEvent.preventDefault();
	}

	handleOnFocus(FocusEvent focusEvent) {
		if (this.endBreak != null) {
			// There is already one
			return;
		}

		DomNode domNode = new DomNode(focusEvent.target);
		this.endBreak = new DomNode(new Element.br());
		Element rawElement = (this.endBreak.getRawNode() as Element);
		rawElement.dataset["webeditor-endbreak"] = "true";
		rawElement.dataset["webeditor-internal"] = "true";

		domNode.append(this.endBreak);
	}

	handleOnBlur(FocusEvent focusEvent) {
		if (this.endBreak != null) {
			this.endBreak.remove();
			this.endBreak = null;
		}
	}

	insertText(DomNode domNode, text) {
		DomNode lastTextNode = getLastTextNode(domNode, true);

		if (lastTextNode == null) {
			Text textNode = new Text(text);
			domNode.insertBefore(new DomNode(textNode), endBreak);
		} else {
			String newText = lastTextNode.getTextContent() + text;
    		lastTextNode.setTextContent(newText);
		}
	}

	deleteText(DomNode domNode) {
		// We first have to find something we can delete.
		// We do that by recursively going through the DOM backwards.
		DomNode lastDeletableNode;

		while ((lastDeletableNode = getLastDeletableNode(domNode)) != null) {
			if (lastDeletableNode.getType() == Node.TEXT_NODE) {
				if (lastDeletableNode.getTextContent().isEmpty) {
					// We found an empty text node, we can delete it,
					// including all empty parents.
					//deleteEmptyNodeAndAllParents(lastDeletableNode);
				} else {
					// Found something to really delete with backspace
					break;
				}
			} else {
				// Found something to really delete with backspace
				break;
			}
		}

		if (lastDeletableNode == null) {
			return;
		}

		// Found something to really delete with backspace
		if (lastDeletableNode.getType() == Node.TEXT_NODE) {
			// Simple text deletion
			String currentText = lastDeletableNode.getTextContent();
			String newText     = currentText.substring(
					0, currentText.length - 1);

			lastDeletableNode.setTextContent(newText);
		} else {
			// If the node is not a text node, just simply remove it.
			lastDeletableNode.remove();
		}
	}

	void deleteEmptyNodeAndAllParents(DomNode domNode) {
		DomNode highestEmptyParentNode = domNode;
		DomNode parentNode;

		while (parentNode == null || !this.editable.isEqualTo(parentNode)) {
			DomNode parentNode = highestEmptyParentNode.getParentNode();
			if (parentNode == null) {
				break;
			}

			if (parentNode.getTextContent().isEmpty) {
				highestEmptyParentNode = parentNode;
			} else {
				break;
			}
		}

		if (highestEmptyParentNode == null) {
			return;
		}

		// Removing (dettaching) this node will also automatically detach all
		// its children automatically. The Dart or Javascript runtime will
		// delete unreferenced objects during garbage collection.
		highestEmptyParentNode.remove();
	}

	DomNode getLastTextNode(DomNode domNode, [bool atEndOnly = false]) {
		Object lastTextNode = _getLastTextNode(domNode, atEndOnly);

		if (lastTextNode == -1) {
			// Deletable element found
			return null;
		}

		return lastTextNode;
	}

	Object _getLastTextNode(DomNode domNode, bool atEndOnly) {
		DomNode lastTextNode;

		List<DomNode> childNodes = domNode.getChildNodes();
		for (var i = childNodes.length - 1; i >= 0; i--) {
			DomNode childNode = childNodes[i];

			if (childNode.isEqualTo(endBreak)) {
				continue;
			}

			if (childNode.getType() == Node.TEXT_NODE) {
				return childNode;
			} else if (atEndOnly
					&& deletableElements.contains(childNode.getNodeName())) {
				// Deletable element found
				return -1;
			} else {
				DomNode lastTextNode = _getLastTextNode(childNode, atEndOnly);

				if (lastTextNode == -1) {
					// Deletable element found
        			return -1;
        		}

				if (lastTextNode != null) {
					return lastTextNode;
				}
			}
		}

		return null;
	}

	DomNode getLastDeletableNode(DomNode domNode) {
		List<DomNode> childNodes = domNode.getChildNodes();
		for (var i = childNodes.length - 1; i >= 0; i--) {
			DomNode childNode = childNodes[i];
			if ((childNode.getType() == Node.TEXT_NODE
					&& childNode.getTextContent().isNotEmpty)
					|| deletableElements.contains(childNode.getNodeName())) {

				// Return the node if it is not an internal element
				if (childNode.getType() != Node.ELEMENT_NODE
						|| !isInternalElement(childNode.getRawNode() as Element)) {
					return childNode;
				}
			}

			DomNode lastDeletableChildNode = getLastDeletableNode(childNode);
			if (lastDeletableChildNode != null) {
				return lastDeletableChildNode;
			}
		}

		return null;
	}

	bool isInternalElement(Element element) {
		return element.dataset["webeditor-internal"] == "true";
	}

	handleBackSpace(DomNode domNode) {
		deleteText(domNode);
	}

	handleEnter(DomNode domNode) {
		DomNode newBreak = new DomNode(new Element.br());
		// Insert a new line break in the editable
		// domNode before our internal endBreak
		domNode.insertBefore(newBreak, endBreak);
	}

	handleNoneFunctionalButton(DomNode domNode, charCode) {
		String char = new String.fromCharCode(charCode);
		if (char.isNotEmpty) {
			insertText(domNode, char);
		}
	}
}
