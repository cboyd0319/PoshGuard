# Formatting issues sample

function Get-Data{  # PSPlaceOpenBrace - missing space before brace
param(
[string]$Path,  # PSUseConsistentIndentation
  [int]$Count  # PSUseConsistentIndentation - inconsistent
        )  # PSPlaceCloseBrace - wrong position

    $result=@()  # PSAlignAssignmentStatement - no spaces around =
    $value  =  10  # PSAlignAssignmentStatement - inconsistent spacing
    
    # PSUseCorrectCasing
    $items=get-childitem $path
    
    if($items.count-gt0){  # PSUseConsistentWhitespace - missing spaces
        foreach($item in $items)  # PSPlaceOpenBrace - missing
        {  # PSPlaceOpenBrace - wrong style
            $result+=$item.name  # PSAlignAssignmentStatement
                    }  # PSPlaceCloseBrace - wrong indentation
    }
    
return $result  # PSUseConsistentWhitespace
}

# PSProvideCommentHelp - missing comment-based help
function Set-Value {
    param($Value)
    $script:data = $Value
}
