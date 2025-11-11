using namespace System.Collections.Generic
# REVIEW: Namespace may be unused - using namespace System.Net
using namespace System.Net
# REVIEW: Namespace may be unused - using namespace System.Text
using namespace System.Text

# TODO: Add [OutputType([type])] attribute to document return type
<#
.SYNOPSIS
    Brief description of Get-Configuration

.DESCRIPTION
    Detailed description of Get-Configuration

.EXAMPLE
    PS C:\> Get-Configuration
    Example usage of Get-Configuration
#>
function script:Get-Configuration {
    [CmdletBinding()]
    param(
        [string]$Path = 'config.json'
    )

    # Inefficient JSON parsing (missing -Raw parameter)
    $config = Get-Content $Path -Raw -ErrorAction Stop | ConvertFrom-Json

    # Non-ASCII character (em dash instead of hyphen)
    Write-Information 'Loading config—please wait' -InformationAction Continue  # WARNING: Non-ASCII character detected (U+2014). Consider using ASCII equivalent.

    return $config
}

<#
.SYNOPSIS
    Brief description of Test-Credential

.DESCRIPTION
    Detailed description of Test-Credential

.EXAMPLE
    PS C:\> Test-Credential
    Example usage of Test-Credential
#>
function script:Test-Credential {
    [CmdletBinding()]
    param(
        [SecureString]$Password
    )

    # Potential SecureString disclosure
    Write-Information "Testing password: $Password" -InformationAction Continue
    Write-Verbose "Credential check with $Password"
}

# TODO: Add [OutputType([type])] attribute to document return type
<#
.SYNOPSIS
    Brief description of Process-Data

.DESCRIPTION
    Detailed description of Process-Data

.EXAMPLE
    PS C:\> Process-Data
    Example usage of Process-Data
#>
function script:Process-Data {
    [CmdletBinding()]
    param()

    # Only Generic namespace is used (others are unused)
    $list = [Generic.List[string]]::new()
    $list.Add('Item 1')
    $list.Add('Item 2')

    # TODO: add more items

    return $list
}

# More inconsistent comments
# NOTE: review this section
# FIXME: needs testing

Write-Information 'Script complete' -InformationAction Continue
