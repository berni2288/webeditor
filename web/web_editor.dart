part of webeditor;


class WebEditor {
	DomNode editable;
	/*
	 * Only set when the editable has focus
	 */
	DomNode endBreak;

	Cursor cursor;

	/*
	 * A list of HTML elements that can be removed by the backspace button
	 */
	List deletableElements = ["br", "img", "table"];

	WebEditor(String selector) {
		Element editableElement = querySelector(selector);
		this.editable = new DomNode(editableElement);

		editableElement
			..onKeyDown.listen(this.handleOnKeyDown)
			..onKeyPress.listen(this.handleOnKeyPress)
			..onFocus.listen(handleOnFocus)
			..onBlur.listen(handleOnBlur);

		// Create a new cursor
		this.cursor = new Cursor(editable);
	}

	handleOnKeyDown(KeyboardEvent keyboardEvent)
	{
		DomNode domNode = new DomNode(keyboardEvent.target);
		int keyCode = keyboardEvent.keyCode;

		switch (keyCode) {
			case KeyCode.BACKSPACE:
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

	insertTextAtCursor(String text) {
		Map cursorPosition = this.cursor.getPosition();

		if (cursorPosition == null) {
			return;
//			DomNode lastTextNode = getLastTextNode(this.editable, true);
//
//			if (lastTextNode == null) {
//				DomNode textNode = new DomNode(new Text(text));
//				endBreak.insertBefore(textNode);
//
//				// Position the cursor
//				cursor.setPosition(textNode, textNode.getTextContent().length);
//			} else {
//				String newText = lastTextNode.getTextContent() + text;
//				lastTextNode.setTextContent(newText);
//
//				// Position the cursor
//				cursor.setPosition(lastTextNode, newText.length);
//			}
		}

		DomNode textNode = cursorPosition['node'];
		int offset       = cursorPosition['offset'];

		// Insert text into text node
		textNode.insertText(text, offset);

		// Move the cursor forward
		cursor.setPosition(textNode, offset + text.length);
	}

	insertDomNodeAtCursor(DomNode domNode)
	{
		Map cursorPosition = this.cursor.getPosition();

		DomNode textNode = cursorPosition['node'];
		int offset       = cursorPosition['offset'];

		String currentText = textNode.getTextContent();
		String preText  = currentText.substring(0, offset);
		String postText = currentText.substring(offset);

		textNode.setTextContent(preText + currentText + postText);

		// Move the cursor forward
		cursor.setPosition(textNode, offset + currentText.length);
	}

	deleteText(DomNode domNode) {
		// Create a Treewalker that filters walks elements and text
		TreeWalker treeWalker = new TreeWalker(domNode.getRawNode(),
				NodeFilter.SHOW_ELEMENT | NodeFilter.SHOW_TEXT);

		Node node                   = treeWalker.lastChild();
		DomNode currentChildDomNode = node == null ? null : new DomNode(node);
        		DomNode domNodeToDelete;

		bool visibleCharacterOrElementDeleted = false;
		bool noMoreThingsToDelete             = false;
		bool whiteSpaceDeleted                = false;

		while (!visibleCharacterOrElementDeleted && currentChildDomNode != null) {
			if (!isInternalDomNode(currentChildDomNode)) {
				if (currentChildDomNode.getType() == Node.ELEMENT_NODE) {
					if (deletableElements.contains(currentChildDomNode.getNodeName())) {
						currentChildDomNode.remove();
						visibleCharacterOrElementDeleted = true;
					}
				} else if (currentChildDomNode.getType() == Node.TEXT_NODE) {
					String textContent = currentChildDomNode.getTextContent();
					int textContentLength = textContent.length;

					for (int i = textContentLength - 1; i >= 0; i--) {
						if (isCharacterHtmlWhiteSpace(textContent[i])) {
							whiteSpaceDeleted = true;
						} else {
							visibleCharacterOrElementDeleted = true;

							// Not whitespace
							if (whiteSpaceDeleted) {
								// Whitespace has already been deleted, that means we don't have
								// to delete this character and can cancel the iteration.
								break;
							}
						}

						// Delete one character from the end (will be actually done after the loop)
						textContentLength--;

						if (visibleCharacterOrElementDeleted) {
							break;
						}
					}

					// If the string would be empty, just deleted the TEXT_NODE
					if (textContentLength == 0) {
						// We can't delete it now because then the relation to the previous
						// node (treewalker) would become invalid, so we delete it afterwards.
						domNodeToDelete = currentChildDomNode;
					} else {
						// Cut the TEXT_NDOE
						textContent = textContent.substring(0, textContentLength);
						currentChildDomNode.setTextContent(textContent);
					}
				}
			}

			// Go to the previous node in the DOM hierarchy
			node = treeWalker.previousNode();
			currentChildDomNode = node == null ? null : new DomNode(node);

			if (domNodeToDelete != null) {
				domNodeToDelete.remove();
				domNodeToDelete = null;
			}
		}
	}

	bool isCharacterHtmlWhiteSpace(String character) {
		return (" \t\r\n".indexOf(character) != -1);
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
			} else if (atEndOnly && deletableElements.contains(childNode.getNodeName()
					)) {
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

	bool isInternalDomNode(DomNode domNode) {
		if (domNode.getType() != Node.ELEMENT_NODE) {
			return false;
		}

		return (domNode.getRawNode() as Element).dataset["webeditor-internal"] ==
				"true";
	}

	handleBackSpace(DomNode domNode) {
		deleteText(domNode);
	}

	handleEnter(DomNode domNode) {
		Map cursorPosition = this.cursor.getPosition();
		DomNode textNode = cursorPosition['node'];
		int offset       = cursorPosition['offset'];

		DomNode newBreak = new DomNode(new Element.br());
		textNode.insertNode(newBreak, offset);
	}

	handleNoneFunctionalButton(DomNode domNode, charCode) {
		String char = new String.fromCharCode(charCode);
		if (char.isNotEmpty) {
			insertTextAtCursor(char);
		}
	}
}
