part of webeditor;


class WebEditor {
	DomNode editable;
	/*
	 * Only set when the editable has focus
	 */
	DomNode endBreak;

	Cursor  cursor;
	Toolbar toolbar;

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
		this.cursor  = new Cursor(editable);
		this.toolbar = new Toolbar();
	}

	handleOnKeyDown(KeyboardEvent keyboardEvent)
	{
		DomNode domNode = new DomNode(keyboardEvent.target);
		int keyCode = keyboardEvent.keyCode;

		// Key-Function mapping
		Map<int, Function> keyFunctionMap = {
        	KeyCode.BACKSPACE: handleKeyBackSpace,
        	KeyCode.ENTER:     handleKeyEnter,
        	KeyCode.LEFT:      handleKeyLeft,
        	KeyCode.UP:        handleKeyUp,
        	KeyCode.RIGHT:     handleKeyRight,
        	KeyCode.DOWN:      handleKeyDown
		};

		// Call the function if registered
		if (keyFunctionMap.containsKey(keyCode)) {
			if (keyFunctionMap[keyCode](domNode)) {
				// Tell the browser to not handle this button
				keyboardEvent.preventDefault();
			}
		}
	}

	handleOnKeyPress(KeyboardEvent keyboardEvent) {
		DomNode domNode = new DomNode(keyboardEvent.target);
		int keyCode     = keyboardEvent.keyCode;

		print("handleOnKeyPress: " + keyCode.toString());

		if (keyCode < 32) {
			// We don't handle functional keys in here
			return;
		}

		if (handleNoneFunctionalKey(domNode, keyCode)) {
			// Tell the browser to not handle this button
			keyboardEvent.preventDefault();
		}
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
		String textToInsert = text;

		DomNode domNode = cursor.getCurrentSelectedDomNode();
		int offset      = cursor.getCurrentTextOffset();

		if (domNode == null) {
			return;
		}

		DomNode textNode;
		if (domNode.getType() == Node.ELEMENT_NODE) {
			textNode = new DomNode(new Text(text));
			domNode.getChildNodes()[offset -1].insertAfter(textNode);
			offset = 0;
		} else {
			textNode = domNode;

			if (isCharacterHtmlWhiteSpace(text)) {
    			String textNodeText = textNode.getText();

    			if (textNodeText.length > 0
    					&& isCharacterHtmlWhiteSpace(textNodeText[offset - 1])) {
    				textToInsert = new String.fromCharCode(160);
    			}
    		}

    		// Insert text into text node
    		textNode.insertText(textToInsert, offset);
		}

		// Move the cursor forward
		cursor.setPosition(textNode, offset + textToInsert.length);
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

	deletePreviousElementOrVisibleLetterAtCursor()
	{
		DomNode selectedDomNode = this.cursor.getCurrentSelectedDomNode();
		int offset              = this.cursor.getCurrentTextOffset();

		if (selectedDomNode == null) {
			return;
		}

		if (offset > 0 && selectedDomNode.getType() == Node.ELEMENT_NODE) {
			// If the offset is > 0, a node inside selectedDomNode was selected
			List<DomNode> childNodesOfSelectedDomNode = selectedDomNode.getChildNodes();
			selectedDomNode = childNodesOfSelectedDomNode[offset - 1];
			offset = 0;
		}

		// Create a Treewalker that filters walks elements and text
		TreeWalker treeWalker = new TreeWalker(this.editable.getRawNode(),
				NodeFilter.SHOW_ELEMENT | NodeFilter.SHOW_TEXT);

		treeWalker.currentNode                = selectedDomNode.getRawNode();
		DomNode currentChildDomNode           = selectedDomNode;
        DomNode domNodeToDelete               = null;

		bool visibleCharacterOrElementDeleted = false;
		bool noMoreThingsToDelete             = false;
		bool whiteSpaceDeleted                = false;

		int currentOffset;
		Map currentCursorPosition;

		while (!visibleCharacterOrElementDeleted && currentChildDomNode != null) {
			if (!isInternalDomNode(currentChildDomNode)) {
				if (currentChildDomNode.getType() == Node.ELEMENT_NODE) {
					// Don't delete not empty text containers
					if (!HtmlRules.isSupportedTextEditingContainerOrElement(
	                                                          currentChildDomNode.getNodeName())
							|| isTextContainerEmpty(currentChildDomNode)) {

						if (offset == 0) {
    						domNodeToDelete = currentChildDomNode;
    					} else {
    						List<DomNode> childNodes = currentChildDomNode.getChildNodes();
    						if (offset <= childNodes.length) {
    							domNodeToDelete = childNodes[offset];
    						}
    					}

    					if (domNodeToDelete != null) {
    						visibleCharacterOrElementDeleted = true;
    					}
					}
				} else if (currentChildDomNode.getType() == Node.TEXT_NODE) {
					String textContent = currentChildDomNode.getText();
					int textContentLength = textContent.length;
					int textContentOffset = textContentLength;

					if (currentChildDomNode.isEqualTo(selectedDomNode)) {
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

					String originalText    = textContent;
					int offsetWhereToCut   = textContentOffset
							- (originalText.length - textContentLength);

					String pretextContent  = originalText.substring(0, offsetWhereToCut);
					String textContentPost = originalText.substring(textContentOffset);
					currentChildDomNode.setText(pretextContent + textContentPost);

					currentOffset = offsetWhereToCut;
					cursor.setPosition(currentChildDomNode, currentOffset);
				}
			}

			// Go to the previous node in the DOM hierarchy
			Node node = treeWalker.previousNode();
			currentChildDomNode = (node == null ? null : new DomNode(node));
		}

		if (domNodeToDelete != null) {
			domNodeToDelete.remove();

			if (currentChildDomNode != null) {
				if (currentChildDomNode.getType() == Node.TEXT_NODE) {
					cursor.setPosition(currentChildDomNode, currentChildDomNode.getText().length);
				} else {
					cursor.setPosition(currentChildDomNode.getParentNode(),
							currentChildDomNode.getChildIndex());
				}
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
		// its children automatically. The Dart runtime will
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

	bool isTextContainerEmpty(DomNode domNode)
	{
		List<DomNode> childNodesOfDomNode = domNode.getChildNodes();
		for (int i = 0; i < childNodesOfDomNode.length; i++) {
			DomNode child = childNodesOfDomNode[i];

			if (child.getType() == Node.TEXT_NODE) {
				if (!child.containsWhitespaceOnly()) {
					return false;
				}
			} else if (child.getType() == Node.ELEMENT_NODE
					&& HtmlRules.isSupportedTextEditingContainerOrElement(child.getNodeName())) {
				if (!isTextContainerEmpty(child)) {
					return false;
				}
			} else {
				return false;
			}
		}

		return true;
	}

	handleKeyBackSpace(DomNode domNode) {
		deletePreviousElementOrVisibleLetterAtCursor();
		return true;
	}

	handleKeyEnter(DomNode domNode) {
		DomNode textNode = this.cursor.getCurrentSelectedDomNode();
		int offset       = this.cursor.getCurrentTextOffset();

		DomNode newBreak = new DomNode(new Element.br());
		textNode.insertNodeIntoText(newBreak, offset);

		DomNode nodeAfterBreak = newBreak.getNext();
		if (nodeAfterBreak.getType() != Node.TEXT_NODE) {
			// Where there is no text node after the new break, create a new one
			nodeAfterBreak = new DomNode(new Text(""));
			newBreak.insertAfter(nodeAfterBreak);
		}

		// Position the cursor in the text node
		cursor.setPosition(nodeAfterBreak, 0);

		return true;
	}

	handleKeyLeft(DomNode domNode)
	{
		return true;
	}

	handleKeyUp(DomNode domNode)
	{
		return true;
	}

	handleKeyRight(DomNode domNode)
	{
		return true;
	}

	handleKeyDown(DomNode domNode)
	{
		return true;
	}

	handleNoneFunctionalKey(DomNode domNode, charCode) {
		String char = new String.fromCharCode(charCode);
		if (char.isNotEmpty) {
			insertTextAtCursor(char);
			return true;
		}
	}
}
