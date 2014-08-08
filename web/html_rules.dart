part of webeditor;


class HtmlRules
{
	/*
	 * A list of elements we support for text editing
	 * Template: https://developer.mozilla.org/en-US/docs/Web/Guide/HTML/HTML5/HTML5_element_list
	 */
	static List supportedTextEditingElements = [
		// Sections
		"body",        // Represents the content of an HTML document. There is only one <body> element in a document.
		"section",     // This element has been added in HTML5	Defines a section in a document.
		"nav",         // This element has been added in HTML5	Defines a section that contains only navigation links.
		"article",     // This element has been added in HTML5	Defines self-contained content that could exist independently of the rest of the content.
		"aside",       // This element has been added in HTML5	Defines some content loosely related to the page content. If it is removed, the remaining content still makes sense.
		"h1",          // -""-
		"h2",          // -""-
		"h3",          // -""-
		"h4",          // -""-
		"h5",          // -""-
		"h6",          // Heading elements implement six levels of document headings; <h1> is the most important and <h6> is the least. A heading element briefly describes the topic of the section it introduces.
		"header",      // This element has been added in HTML5	Defines the header of a page or section. It often contains a logo, the title of the Web site, and a navigational table of content.
		"footer",      // This element has been added in HTML5	Defines the footer for a page or section. It often contains a copyright notice, some links to legal information, or addresses to give feedback.
		"address",     // Defines a section containing contact information.
		"main",        // This element has been added in HTML5	Defines the main or important content in the document. There is only one <main> element in the document.

		// Grouping content
		"p",           // Defines a portion that should be displayed as a paragraph.
        "blockquote",  // Represents a content that is quoted from another source.
        "li",          // Defines a item of an enumeration list.
        "dt",          // Represents a term defined by the next <dd>.
        "dd",          // Represents the definition of the terms immediately listed before it.
        "figure",      // This element has been added in HTML5	Represents a figure illustrated as part of the document.
        "figcaption",  // This element has been added in HTML5	Represents the legend of a figure.
        "div",         // Represents a generic container with no special meaning.

        // Text-level semantics
        "a",           // Represents a hyperlink , linking to another resource.
        "em",          // Represents emphasized text, like a stress accent.
        "strong",      // Represents especially important text.
        "small",       // Represents a side comment , that is, text like a disclaimer or a copyright, which is not essential to the comprehension of the document.
        "s",           // Represents content that is no longer accurate or relevant .
        "cite",        // Represents the title of a work .
        "q",           // Represents an inline quotation .
        "dfn",         // Represents a term whose definition is contained in its nearest ancestor content.
        "abbr",        // Represents an abbreviation or an acronym ; the expansion of the abbreviation can be represented in the title attribute.
        "data",        // This element has been added in HTML5	Associates to its content a machine-readable equivalent . (This element is only in the WHATWG version of the HTML standard, and not in the W3C version of HTML5).
        "time",        // This element has been added in HTML5	Represents a date and time value; the machine-readable equivalent can be represented in the datetime attribute.
        "code",        // Represents computer code .
        "var",         // Represents a variable, that is, an actual mathematical expression or programming context, an identifier representing a constant, a symbol identifying a physical quantity, a function parameter, or a mere placeholder in prose.
        "samp",        // Represents the output of a program or a computer.
        "kbd",         // Represents user input , often from the keyboard, but not necessarily; it may represent other input, like transcribed voice commands.
        "sub",         // Represent a subscript , or a superscript.
        "sup",         // Represent a subscript , or a superscript.
        "i",           // Represents some text in an alternate voice or mood, or at least of different quality, such as a taxonomic designation, a technical term, an idiomatic phrase, a thought, or a ship name.
        "b",           // Represents a text which to which attention is drawn for utilitarian purposes . It doesn't convey extra importance and doesn't imply an alternate voice.
        "u",           // Represents a non-textual annoatation for which the conventional presentation is underlining, such labeling the text as being misspelt or labeling a proper name in Chinese text.
        "mark",        // This element has been added in HTML5	Represents text highlighted for reference purposes, that is for its relevance in another context.
        "ruby",        // This element has been added in HTML5	Represents content to be marked with ruby annotations , short runs of text presented alongside the text. This is often used in conjunction with East Asian language where the annotations act as a guide for pronunciation, like the Japanese furigana .
        "rt",          // This element has been added in HTML5	Represents the text of a ruby annotation .
        "rp",          // This element has been added in HTML5	Represents parenthesis around a ruby annotation, used to display the annotation in an alternate way by browsers not supporting the standard display for annotations.
        "bdi",         // This element has been added in HTML5	Represents text that must be isolated from its surrounding for bidirectional text formatting. It allows embedding a span of text with a different, or unknown, directionality.
        "bdo",         // Represents the directionality of its children, in order to explicitly override the Unicode bidirectional algorithm.
        "span",        // Represents text with no specific meaning. This has to be used when no other text-semantic element conveys an adequate meaning, which, in this case, is often brought by global attributes like class, lang, or dir.

        // Edits
		"ins",         // Defines an addition to the document.
		"del",         // Defines a removal from the document.

		// Tabular data
		"caption",     // Represents the title of a table.
		"td",          // Represents a data cell in a table.
		"th",          // Represents a header cell in a table.

		// Interactive elements
		"details",     // This element has been added in HTML5	Represents a widget from which the user can obtain additional information or controls.
        "summary",     // This element has been added in HTML5	Represents a summary , caption , or legend for a given <details>.
        "menuitem",    // This element has been added in HTML5	Represents a command that the user can invoke.
        "menu"         // This element has been added in HTML5	Represents a list of commands .
	];

	/*
	 * A list of HTML elements that can't contain text nodes directly, but can contain other
	 * elements that can actually contain text.
	 * This is an extension list of the list supportedTextEditingElements.
	 */
	static List supportedTextEditingElementContainers = [
		"ol",          // Defines an ordered list of items.
		"ul",          // Defines an unordered list of items.
		"dl",          // Defines a definition list, that is, a list of terms and their associated definitions.

		// Tabular data
		"table",       // Represents data with more than one dimension.
		"colgroup",    // Represents a set of one or more columns of a table.
		"col",         // Represents a column of a table.
		"tbody",       // Represents the block of rows that describes the concrete data of a table.
		"thead",       // Represents the block of rows that describes the column labels of a table.
		"tfoot",       // Represents the block of rows that describes the column summaries of a table
		"tr"           // Represents a row of cells in a table.
	];

	static List breakableWhitespaceCharacters = [
    	" ",
    	"\t",
    	"\r",
    	"\n"
	];


	static bool isSupportedTextEditingElement(String elementName)
	{
		return supportedTextEditingElements.contains(elementName);
	}

	static bool isSupportedTextEditingContainer(String elementName)
	{
		return supportedTextEditingElementContainers.contains(elementName);
	}

	static bool isSupportedTextEditingContainerOrElement(String elementName)
	{
		return isSupportedTextEditingElement(elementName)
				|| isSupportedTextEditingContainer(elementName);
	}

	static bool isBreakableWhitespace(String character)
	{
		return breakableWhitespaceCharacters.contains(character);
	}

	static bool isCharacterRendered(String previousCharacter)
	{
		return isBreakableWhitespace(previousCharacter);
	}
}
