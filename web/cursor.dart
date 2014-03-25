part of webeditor;


class Cursor
{
	DomNode cursorDomNode;
	DomNode editable;

	/*
	 * Contains the properties 'node' and 'offset', can be null.
	 */
	DomNode currentDomNode;
	int currentTextOffset;


	Cursor(DomNode editable)
	{
		this.editable = editable;
		Element rawElement = (editable.getRawNode() as Element);
		document.onSelectionChange.listen(onSelectionChange);

		createElement();
	}

	getDomNode()
	{
		return this.cursorDomNode;
	}

	createElement()
	{
		this.cursorDomNode = DomNode.createElement("div");

		Element cursorElement = this.cursorDomNode.getRawNode();
		cursorElement.classes.add("webeditor-cursor webeditor-internal");
		cursorElement.style.display = "none";

		querySelector("body").append(cursorElement);

		return this.cursorDomNode;
	}

	getCurrentSelectedDomNode()
	{
		return this.currentDomNode;
	}

	getCurrentTextOffset()
	{
		return this.currentTextOffset;
	}

	setPosition(DomNode domNode, int offset)
	{
		this.currentDomNode = domNode;
		this.currentTextOffset = offset;

		Selection selection = window.getSelection();
		selection.setPosition(domNode.getRawNode(), offset);
		positionCursorAtCurrentSelection();
	}

	onSelectionChange(Event event)
	{
		positionCursorAtCurrentSelection();
	}

	positionCursorAtCurrentSelection()
	{
		Selection selection = window.getSelection();

		if (!selection.isCollapsed) {
			(this.cursorDomNode.getRawNode() as Element).style.display = "none";
			return;
		}

		// Don't continue if the selection goes over multiple characters/elements
		if (selection.anchorNode == null) {
			return;
		}

		DomNode anchorNode = new DomNode(selection.anchorNode);
		int anchorOffset = selection.anchorOffset;

		// Check if we actually care about this
		if (!anchorNode.isContainedBy(this.editable)) {
			return;
		}

		// Sanitize selection
		// If the user clicked behind a text node, we set the selection to the end of the text node
		if (anchorOffset > 0 && anchorNode.getType() == Node.ELEMENT_NODE) {
			List<DomNode> childNodesOfDomNode = anchorNode.getChildNodes();
			DomNode actualDomNode = childNodesOfDomNode[anchorOffset - 1];

			if (actualDomNode.getType() == Node.TEXT_NODE) {
				// If the cursor if after a text node, it can't be used for direct positioning
				// In this case, we have to find a previous element or text node where the cursor
				// can be positioned.
				DomNode nearestNode = getNearestTextNodeOrElementBeforeDomNode(actualDomNode);

				if (nearestNode == null) {
					return;
				} else if (nearestNode.getType() == Node.TEXT_NODE) {
					anchorNode = nearestNode;
					anchorOffset = nearestNode.getText().length;
				} else {
					anchorNode = nearestNode.getParentNode();
					anchorOffset = nearestNode.getChildIndex() + 1;
				}

				selection.setPosition(anchorNode.getRawNode(), anchorOffset);
				anchorNode = new DomNode(selection.anchorNode);
				anchorOffset = selection.anchorOffset;
			}
		}

		print("Clicked into node \"" + anchorNode.getText().substring(0,
				anchorNode.getText().length < 32 ? anchorNode.getText().length : 32)
        					+ "\" | offset #" + anchorOffset.toString()
        					+ " | node-type: " + anchorNode.getType().toString()
        					+ " | element: <" + anchorNode.getNodeName() + ">");

		Map offsets;
		if (anchorNode.getType() == Node.ELEMENT_NODE) {
			offsets = getCursorPostionForElement(anchorNode, anchorOffset);
		} else if (anchorNode.getType() == Node.TEXT_NODE) {
			offsets = getCursorPostionForTextNode(selection.getRangeAt(0));
		}

		if (offsets == null) {
			return;
		}

		DomNode styleNode = anchorNode;
		if (offsets.containsKey("domNode")) {
			styleNode = offsets['domNode'];
		}

		positionAndstyleTheCursor(offsets, styleNode);

		// Update the cursor display in the toolbar
		webEditor.toolbar.updateCursorDisplay(anchorNode, anchorOffset);

		// We can't use this.setPosition here, because that would cause an infinite loop...
		this.currentDomNode    = anchorNode;
		this.currentTextOffset = anchorOffset;
	}

	positionAndstyleTheCursor(Map offsets, DomNode styleDomNode)
	{
		Element cursorElement = this.cursorDomNode.getRawNode();

		// Set the font-size and the color for our cursor
		CssStyleDeclaration computedStyle = null;
		int yOffset = 0;

		if (styleDomNode.getType() == Node.TEXT_NODE) {
			computedStyle = (styleDomNode.getParentNode().getRawNode() as Element).getComputedStyle();
			cursorElement.style.height = computedStyle.getPropertyValue("font-size");
			yOffset = 3;
		} else {
			computedStyle = (styleDomNode.getRawNode() as Element).getComputedStyle();
			cursorElement.style.height = computedStyle.getPropertyValue("height");
		}

		cursorElement.style.left            = offsets['x'].toString() + "px";
		cursorElement.style.top             = (offsets['y'] + yOffset).toString() + "px";
		cursorElement.style.display         = "block";
		cursorElement.style.backgroundColor = computedStyle.getPropertyValue("color");
	}

	Map getCursorPostionForElement(DomNode domNode, int offset)
	{
		DomNode actualDomNode = domNode;
		Rectangle rectangle   = null;

		if (offset == 0) {
			List<Rectangle<dynamic>> rectangleList = (domNode.getRawNode() as Element).getClientRects();

			if (rectangleList.length == 0) {
				return null;
			}

			rectangle = rectangleList[0];
		} else {
			List<DomNode> childNodesOfDomNode = domNode.getChildNodes();
			actualDomNode = childNodesOfDomNode[offset - 1];

			if (actualDomNode.getType() == Node.TEXT_NODE) {
				throw "Tried getting the position of a text node, this is not supported.";
			}

			rectangle = (actualDomNode.getRawNode() as Element).getBoundingClientRect();
		}

		double xPosition;
		if (offset == 0) {
			// When the cursor is inside an empty element, position it to the left
			xPosition = rectangle.left;
		} else {
			xPosition = rectangle.right;
		}

		xPosition += window.scrollX + 1;

		return {
			'x':       xPosition,
			'y':       rectangle.top + window.scrollY,
			'domNode': actualDomNode
		};
	}

	Map getCursorPostionForTextNode(Range range)
	{
		List<Rectangle<dynamic>> rectangleList = range.getClientRects();
		Rectangle rectangle = rectangleList[0];

		return {
			'x': rectangle.left + window.scrollX,
			'y': rectangle.top  + window.scrollY
		};
	}

	DomNode getNearestTextNodeOrElementBeforeDomNode(DomNode domNode)
	{
		// Create a Treewalker that filters walks elements and text
		TreeWalker treeWalker = new TreeWalker(this.editable.getRawNode(),
				NodeFilter.SHOW_ELEMENT | NodeFilter.SHOW_TEXT);

		treeWalker.currentNode = domNode.getRawNode();

		DomNode currentNode = new DomNode(treeWalker.previousNode());
		while (currentNode != null) {
			if (!webEditor.isInternalDomNode(domNode)) {
				if (currentNode.getType() == Node.TEXT_NODE && !currentNode.containsWhitespaceOnly()) {
					return currentNode;
				}

				if (currentNode.getType() == Node.ELEMENT_NODE
						&& !HtmlElementRules.isSupportTextEditingElementContainer(currentNode.getNodeName())) {
					return currentNode;
				}
			}

			Node node = treeWalker.previousNode();
			currentNode = (node == null ? null : new DomNode(node));
		}

		return null;
	}
}
