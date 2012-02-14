function highlightedCode()
{    
    var codeblock = document.getElementById("codeblock");
	var children = codeblock.childNodes;
	
	styledump = "";
	
	for(var i = 0; i < children.length; i++)
	{		
		var child = children[i];
		
		if(child == undefined || child.tagName != "SPAN")
		{
			continue;
		}
		
		var style = window.getComputedStyle(child);
		var color;
		
		if(style == null)
		{
			color = "rgb(0, 0, 0)";
		}
		else
		{
			color = style.color;
		}
		
		// Colons and stuff! Nobody would actually write that, right?
		
		var code = String(child.innerHTML);
		
		styledump += code + ";;;" + color + ":::\n";
	}
    
	return styledump;
}