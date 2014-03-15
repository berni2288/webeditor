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
		rawElement.onClick.listen(onClick);

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
		if (domNode.getType() != Node.TEXT_NODE) {
			return;
		}

		this.currentDomNode = domNode;
		this.currentTextOffset = offset;

		Selection selection = window.getSelection();
		selection.setPosition(domNode.getRawNode(), offset);
		positionCursorAtCurrentSelection();
	}

	onClick(MouseEvent mouseEvent)
	{
		positionCursorAtCurrentSelection();
	}

	positionCursorAtCurrentSelection()
	{
		Selection selection = window.getSelection();

		if (!selection.isCollapsed) {
			return;
		}

		if (selection.anchorNode == null) {
			return;
		}

		DomNode anchorNode = new DomNode(selection.anchorNode);
		int anchorOffset = selection.anchorOffset;

		Map offsets;
		if (anchorNode.getType() == Node.ELEMENT_NODE) {
			offsets = positionCursorForElement(anchorNode, anchorOffset);
		} else if (anchorNode.getType() == Node.TEXT_NODE) {
			print("Clicked into textnode \"" + anchorNode.getText()
					+ "\" at character #" + anchorOffset.toString());
			offsets = positionCursorForTextNode(anchorNode, anchorOffset);
		}

		if (offsets == null) {
			return;
		}

		Element cursorElement = this.cursorDomNode.getRawNode();
		cursorElement.style.left    = offsets['x'].toString() + "px";
		cursorElement.style.top     = offsets['y'].toString() + "px";
		cursorElement.style.display = "block";

		// We can't use this.setPosition here, because that would cause an infinite loop...
		this.currentDomNode    = anchorNode;
		this.currentTextOffset = anchorOffset;
	}

	Map positionCursorForElement(DomNode domNode, int anchorOffset)
	{
		TreeWalker treeWalker = new TreeWalker(domNode.getRawNode(),
        				NodeFilter.SHOW_TEXT);

		DomNode lastTextNode = new DomNode(treeWalker.lastChild());

		if (lastTextNode == null) {
			return null;
		}

		return positionCursorForTextNode(lastTextNode, lastTextNode.getText().length);
	}

	Map positionCursorForTextNode(DomNode domNode, int anchorOffset)
	{
		Map offsets = determineCharacterPosition(domNode, anchorOffset);
		print("Offset: x: " + offsets['x'].toString()
				+ " y: " + offsets['y'].toString());

		return offsets;
	}

	Map determineCharacterPosition(DomNode domNode, int offset)
	{
		// Create a new empty span
		// We need this to get the position of the current cursor
		// Otherwise we would have to do complex tricks I don't wanna do.
		DomNode span = DomNode.createElement("span");
		// Set a none breakable space, so it's not empty
		span.setText(new String.fromCharCode(160));
		DomNode secondTextNode = domNode.insertNode(span, offset);

		Map offsets = span.getDocumentOffsets();

		span.remove();

		// Normalize the text nodes again (= merge them)
		domNode.setText(domNode.getText() + secondTextNode.getText());
		secondTextNode.remove();

		return offsets;
	}
}
