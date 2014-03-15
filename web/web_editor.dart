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
		this.editable           = new DomNode(editableElement);

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
		int keyCode     = keyboardEvent.keyCode;

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

		DomNode domNode    = new DomNode(focusEvent.target);
		this.endBreak      = new DomNode(new Element.br());
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
		DomNode textNode = cursor.getCurrentSelectedDomNode();
		int offset       = cursor.getCurrentTextOffset();

		if (textNode == null) {
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

		// Insert text into text node
		textNode.insertText(text, offset);

		// Move the cursor forward
		cursor.setPosition(textNode, offset + text.length);
	}

	insertDomNodeAtCursor(DomNode domNode)
	{
		DomNode textNode = this.cursor.getCurrentSelectedDomNode();
		int offset       = this.cursor.getCurrentTextOffset();

		String currentText = textNode.getText();
		String preText  = currentText.substring(0, offset);
		String postText = currentText.substring(offset);

		textNode.setText(preText + currentText + postText);

		// Move the cursor forward
		cursor.setPosition(textNode, offset + currentText.length);
	}

	deleteTextAtCursor()
	{
		DomNode textNode = this.cursor.getCurrentSelectedDomNode();
		int offset       = this.cursor.getCurrentTextOffset();

		if (textNode == null) {
			return;
		}

		// Create a Treewalker that filters walks elements and text
		TreeWalker treeWalker = new TreeWalker(this.editable.getRawNode(),
				NodeFilter.SHOW_ELEMENT | NodeFilter.SHOW_TEXT);

		Node node                   = treeWalker.currentNode = textNode.getRawNode();
		DomNode currentChildDomNode = node == null ? null : new DomNode(node);
        		DomNode domNodeToDelete;

		bool visibleCharacterOrElementDeleted = false;
		bool noMoreThingsToDelete             = false;
		bool whiteSpaceDeleted                = false;

		int currentOffset;
		Map currentCursorPosition;

		while (!visibleCharacterOrElementDeleted && currentChildDomNode != null) {
			if (!isInternalDomNode(currentChildDomNode)) {
				if (currentChildDomNode.getType() == Node.ELEMENT_NODE) {
					if (deletableElements.contains(currentChildDomNode.getNodeName())) {
						currentChildDomNode.remove();
						visibleCharacterOrElementDeleted = true;
					}
				} else if (currentChildDomNode.getType() == Node.TEXT_NODE) {
					String textContent = currentChildDomNode.getText();
					int textContentLength = textContent.length;
					int textContentOffset = textContentLength;

					if (currentChildDomNode.isEqualTo(textNode)) {
						textContentOffset = offset;
					}

					for (int i = textContentOffset - 1; i >= 0; i--) {
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
						String originalText    = textContent;
						int offsetWhereToCut   = textContentOffset
								- (originalText.length - textContentLength);

						String pretextContent  = originalText.substring(0, offsetWhereToCut);
						String textContentPost = originalText.substring(textContentOffset);
						currentChildDomNode.setText(pretextContent + textContentPost);

						// Position the cursor
						//cursor.setPosition(currentChildDomNode, offsetWhereToCut);
						currentOffset = offsetWhereToCut;
						cursor.setPosition(currentChildDomNode, currentOffset);
					}
				}
			}

			// Go to the previous node in the DOM hierarchy
			node = treeWalker.previousNode();
			currentChildDomNode = (node == null ? null : new DomNode(node));

			if (domNodeToDelete != null) {
				domNodeToDelete.remove();
				domNodeToDelete = null;

				// Position the cursor
//				if (currentChildDomNode != null) {
//					cursor.setPosition(currentChildDomNode,
//							currentChildDomNode.getTextContent().length);
//				}
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

			if (parentNode.getText().isEmpty) {
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
		deleteTextAtCursor();
	}

	handleEnter(DomNode domNode) {
		DomNode textNode = this.cursor.getCurrentSelectedDomNode();
		int offset       = this.cursor.getCurrentTextOffset();

		DomNode newBreak = new DomNode(new Element.br());
		textNode.insertNode(newBreak, offset);

		DomNode nodeAfterBreak = newBreak.getNext();
		if (nodeAfterBreak.getType() != Node.TEXT_NODE) {
			// Where there is no text node after the new break, create a new one
			nodeAfterBreak = new DomNode(new Text(""));
			newBreak.insertAfter(nodeAfterBreak);
		}

		// Position the cursor in the text node
		cursor.setPosition(nodeAfterBreak, 0);
	}

	handleNoneFunctionalButton(DomNode domNode, charCode) {
		String char = new String.fromCharCode(charCode);
		if (char.isNotEmpty) {
			insertTextAtCursor(char);
		}
	}
}
