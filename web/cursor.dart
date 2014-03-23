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

		print("Clicked into node \"" + anchorNode.getText().substring(0,
				anchorNode.getText().length < 32 ? anchorNode.getText().length : 32)
        					+ "\" | offset #" + anchorOffset.toString()
        					+ " | node-type: " + anchorNode.getType().toString()
        					+ " | element: <" + anchorNode.getNodeName() + ">");

		Map offsets;
		if (anchorNode.getType() == Node.ELEMENT_NODE) {
			offsets = positionCursorForElement(anchorNode, anchorOffset);
		} else if (anchorNode.getType() == Node.TEXT_NODE) {
			offsets = positionCursorForTextNode(anchorNode, anchorOffset);
		}

		if (offsets == null) {
			return;
		}

		positionAndstyleTheCursor(offsets, anchorNode);

		// Update the cursor display in the toolbar
		webEditor.toolbar.updateCursorDisplay(anchorNode, anchorOffset);

		// We can't use this.setPosition here, because that would cause an infinite loop...
		this.currentDomNode    = anchorNode;
		this.currentTextOffset = anchorOffset;
	}

	positionAndstyleTheCursor(Map offsets, DomNode styleDomNode)
	{
		Element cursorElement = this.cursorDomNode.getRawNode();
		cursorElement.style.left    = offsets['x'].toString() + "px";
		cursorElement.style.top     = (offsets['y'] + 3).toString() + "px";
		cursorElement.style.display = "block";

		// Set the font-size and the color for our cursor
		CssStyleDeclaration computedStyle = null;
		if (styleDomNode.getType() == Node.TEXT_NODE) {
			computedStyle = (styleDomNode.getParentNode().getRawNode() as Element).getComputedStyle();
			cursorElement.style.height = computedStyle.getPropertyValue("font-size");
		} else {
			computedStyle = (styleDomNode.getRawNode() as Element).getComputedStyle();
			cursorElement.style.height = computedStyle.getPropertyValue("height");
		}

		cursorElement.style.backgroundColor = computedStyle.getPropertyValue("color");
	}

	Map positionCursorForElement(DomNode domNode, int anchorOffset)
	{
		Range range = window.getSelection().getRangeAt(0);
		List<Rectangle<dynamic>> rectangleList = (domNode.getRawNode() as Element).getClientRects();

		if (rectangleList.length > 0) {
			Rectangle rectangle = rectangleList[0];

			return {
				'x': rectangle.left,
				'y': rectangle.top
			};
		}

		return null;
	}

	Map positionCursorForTextNode(DomNode domNode, int anchorOffset)
	{
		return determineCharacterPosition(domNode, anchorOffset);
	}

	Map determineCharacterPosition(DomNode domNode, int offset)
	{
		Range range = window.getSelection().getRangeAt(0);
		List<Rectangle<dynamic>> rectangleList = range.getClientRects();
		Rectangle rectangle = rectangleList[0];

		return {
			'x': rectangle.left + window.scrollX,
			'y': rectangle.top + window.scrollY
		};
	}
}
