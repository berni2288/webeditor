part of webeditor;


class EditNodeTraverser
{
	findPreVisiblePosition(
			DomNode containerDomNode,
			DomNode referenceDomNode,
			int currentOffset,
			int shiftOffset)
	{
		// Create a Treewalker that walks element and text nodes
		TreeWalker treeWalker = new TreeWalker(containerDomNode.getRawNode(),
				NodeFilter.SHOW_ELEMENT | NodeFilter.SHOW_TEXT);

		Node currentNode       = referenceDomNode.getRawNode();
		treeWalker.currentNode = currentNode;
		DomNode currentDomNode = null;
		int unitsLeftToShift   = shiftOffset;
		int inNodeOffset       = currentOffset;

		do {
			DomNode currentDomNode = new DomNode(currentNode);

			if (webEditor.isInternalDomNode(currentDomNode)) {
				continue;
			}

			Map returnValues;
			switch (currentDomNode.getType()) {
				case Node.ELEMENT_NODE: {
					returnValues = shiftUnitsInElement(currentDomNode, unitsLeftToShift);
				} break;

				case Node.TEXT_NODE: {
					returnValues = shiftUnitsinText(currentDomNode, unitsLeftToShift);
				} break;
			}

			if (returnValues != null) {
				unitsLeftToShift -= returnValues['unitsShifted'];

				if (unitsLeftToShift == 0) {
					// When the shifting is completed, save the new offset.
					inNodeOffset = returnValues['newOffset'];
				}
			}

			// Go to the previous node in the DOM hierarchy
		} while (unitsLeftToShift > 0 && (currentNode = treeWalker.previousNode()) != null);
	}

	Map shiftUnitsInElement(DomNode domNode, int unitsToShift)
	{
		return {
			'unitsShifted': 0,
			'newOffset': 0
		};
	}

	Map shiftUnitsinText(DomNode domNode, int unitsToShift)
	{
		int unitsLeftToShift = unitsToShift;

		return {
			'unitsShifted': 0,
			'newOffset': 0
		};
	}

	findPostVisiblePosition(
			DomNode containerDomNode,
			DomNode referenceDomNode,
			int currentOffset,
			int shiftOffset)
	{
		// Code
	}
}
