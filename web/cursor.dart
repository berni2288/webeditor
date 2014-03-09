part of webeditor;


class Cursor
{
	DomNode cursorDomNode;
	DomNode editable;
	DomNode currentSelectedDomNode;
	DomNode currentSelectedOffset;


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

	Map getPosition()
	{
		if (currentSelectedDomNode == null) {
			return null;
		}

		return {
			'node':   this.currentSelectedDomNode,
			'offset': this.currentSelectedOffset
		};
	}

	onClick(MouseEvent mouseEvent)
	{
		positionCursor();
	}

	positionCursor()
	{
		Selection selection = window.getSelection();

		if (!selection.isCollapsed) {
			print("Error: is not collapsed");
			return;
		}

		DomNode anchorNode = new DomNode(selection.anchorNode);
		int anchorOffset = selection.anchorOffset;

		Map cursorOffsets;
		if (anchorNode.getType() == Node.ELEMENT_NODE) {
			cursorOffsets = positionCursorForElement(anchorNode, anchorOffset);
		} else if (anchorNode.getType() == Node.TEXT_NODE) {
			print("Clicked into textnode \"" + anchorNode.getTextContent()
					+ "\" at character #" + anchorOffset.toString());
			cursorOffsets = positionCursorForTextNode(anchorNode, anchorOffset);
		}

		if (cursorOffsets == null) {
			return;
		}

		Element cursorElement = this.cursorDomNode.getRawNode();

		cursorElement.style.left    = cursorOffsets['x'].toString() + "px";
		cursorElement.style.top     = cursorOffsets['y'].toString() + "px";
		cursorElement.style.display = "block";
	}

	Map positionCursorForElement(DomNode domNode, int anchorOffset)
	{
		TreeWalker treeWalker = new TreeWalker(domNode.getRawNode(),
        				NodeFilter.SHOW_TEXT);

		DomNode lastTextNode = new DomNode(treeWalker.lastChild());

		if (lastTextNode == null) {
			return null;
		}

		return positionCursorForTextNode(lastTextNode, lastTextNode.getTextContent().length);
	}

	Map positionCursorForTextNode(DomNode domNode, int anchorOffset)
	{
		Map offsets = determineCharacterPosition(domNode, anchorOffset);
		print("Offset: x: " + offsets['x'].toString() + " y: " + offsets['y'].toString());

		return offsets;
	}

	Map determineCharacterPosition(DomNode domNode, int offset)
	{
		// Create a new empty span
		// We need this to get the position of the current cursor
		// Otherwise we would have to do complex tricks I don't wanna do.
		DomNode span = DomNode.createElement("span");
		domNode.insertAfter(span);

		String anchorNodeText = domNode.getTextContent();
		String preText  = anchorNodeText.substring(0, offset);
		String postText = anchorNodeText.substring(offset);

		domNode.setTextContent(preText);

		// We also need a second text node
		DomNode textNode = new DomNode(new Text(postText));
		span.insertAfter(textNode);
		// Set a none breakable space, so it's not empty
		span.setTextContent(new String.fromCharCode(160));

		Map offsets = span.getOffsets();

		span.remove();
		domNode.normalizeText();

		return offsets;
	}
}
