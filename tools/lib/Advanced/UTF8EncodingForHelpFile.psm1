# UTF8EncodingForHelpFile.psm1
# Implements PSUseUTF8EncodingForHelpFile auto-fix
# Converts help files to UTF-8 encoding

function Invoke-UTF8EncodingForHelpFileFix {
  <#
    .SYNOPSIS
        Converts help files to UTF-8 encoding.
    
    .DESCRIPTION
        Detects help files (*.help.txt, *-help.xml, about_*.help.txt) that are not
        encoded in UTF-8 and converts them to UTF-8 with BOM.
    
    .PARAMETER FilePath
        The path to the file to check and convert.
    
    .PARAMETER ScriptContent
        The content of the file (for consistency with other fix functions).
        For this rule, we primarily work with FilePath.
    
    .EXAMPLE
        Invoke-UTF8EncodingForHelpFileFix -FilePath "C:\Module\en-US\about_MyModule.help.txt"
    
    .NOTES
        Rule: PSUseUTF8EncodingForHelpFile
        Severity: Warning
        Category: Best Practices / Documentation
        
        Only processes files that match help file patterns:
        - *.help.txt
        - *-help.xml
        - about_*.help.txt
    #>
  [CmdletBinding()]
  [OutputType([string])]
  param(
    [Parameter(Mandatory = $false)]
    [string]$FilePath,
        
    [Parameter(Mandatory = $false)]
    [AllowEmptyString()]
    [string]$ScriptContent
  )
    
  # This rule requires a file path to work with
  if ([string]::IsNullOrWhiteSpace($FilePath)) {
    return $ScriptContent
  }
    
  # Check if this is a help file
  if (-not (Test-IsHelpFile -FilePath $FilePath)) {
    return $ScriptContent
  }
    
  try {
    # Check if file exists
    if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
      Write-Warning "File not found: $FilePath"
      return $ScriptContent
    }
        
    # Detect current encoding
    $currentEncoding = Get-FileEncoding -FilePath $FilePath
        
    # If already UTF-8, no action needed
    if ($currentEncoding.BodyName -eq 'utf-8') {
      Write-Verbose "File is already UTF-8: $FilePath"
      return $ScriptContent
    }
        
    Write-Verbose "Converting $FilePath from $($currentEncoding.EncodingName) to UTF-8"
        
    # Read content with current encoding
    $content = Get-Content -Path $FilePath -Raw -Encoding $currentEncoding
        
    # Write back as UTF-8 with BOM
    $utf8Encoding = New-Object System.Text.UTF8Encoding($true)
    [System.IO.File]::WriteAllText($FilePath, $content, $utf8Encoding)
        
    Write-Verbose "Successfully converted to UTF-8: $FilePath"
        
    # Return the content (now in UTF-8)
    return $content
        
  } catch {
    Write-Warning "Failed to convert file encoding for ${FilePath}: $_"
    return $ScriptContent
  }
}

function Test-IsHelpFile {
  <#
    .SYNOPSIS
        Tests if a file is a PowerShell help file.
    
    .PARAMETER FilePath
        The file path to test.
    
    .OUTPUTS
        [bool] True if the file is a help file, False otherwise.
    #>
  [CmdletBinding()]
  [OutputType([bool])]
  param(
    [Parameter(Mandatory = $true)]
    [string]$FilePath
  )
    
  $fileName = [System.IO.Path]::GetFileName($FilePath)
    
  # Check for common help file patterns
  $helpFilePatterns = @(
    '*.help.txt',
    '*-help.xml',
    'about_*.help.txt',
    'about_*.txt'
  )
    
  foreach ($pattern in $helpFilePatterns) {
    if ($fileName -like $pattern) {
      return $true
    }
  }
    
  return $false
}

function Get-FileEncoding {
  <#
    .SYNOPSIS
        Detects the encoding of a file.
    
    .PARAMETER FilePath
        The file to analyze.
    
    .OUTPUTS
        [System.Text.Encoding] The detected encoding.
    #>
  [CmdletBinding()]
  [OutputType([System.Text.Encoding])]
  param(
    [Parameter(Mandatory = $true)]
    [string]$FilePath
  )
    
  try {
    # Read first few bytes to detect BOM
    $bytes = New-Object byte[] 4
    $fileStream = [System.IO.File]::OpenRead($FilePath)
    $null = $fileStream.Read($bytes, 0, 4)
    $fileStream.Close()
        
    # Check for BOM signatures
    # UTF-8 BOM: EF BB BF
    if ($bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
      return [System.Text.Encoding]::UTF8
    }
        
    # UTF-16 BE BOM: FE FF
    if ($bytes[0] -eq 0xFE -and $bytes[1] -eq 0xFF) {
      return [System.Text.Encoding]::BigEndianUnicode
    }
        
    # UTF-16 LE BOM: FF FE
    if ($bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) {
      return [System.Text.Encoding]::Unicode
    }
        
    # UTF-32 LE BOM: FF FE 00 00
    if ($bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE -and $bytes[2] -eq 0x00 -and $bytes[3] -eq 0x00) {
      return [System.Text.Encoding]::UTF32
    }
        
    # No BOM detected - use StreamReader to detect encoding
    $reader = New-Object System.IO.StreamReader($FilePath, $true)
    $reader.ReadToEnd() | Out-Null
    $encoding = $reader.CurrentEncoding
    $reader.Close()
        
    return $encoding
        
  } catch {
    Write-Warning "Failed to detect encoding for ${FilePath}: $_"
    # Default to ASCII if detection fails
    return [System.Text.Encoding]::ASCII
  }
}

Export-ModuleMember -Function Invoke-UTF8EncodingForHelpFileFix
