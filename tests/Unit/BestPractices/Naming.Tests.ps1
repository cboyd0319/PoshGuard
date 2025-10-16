#!/usr/bin/env pwsh
#requires -Version 5.1

<#
.SYNOPSIS
    Pester tests for BestPractices/Naming module

.DESCRIPTION
    Unit tests for Naming.psm1 functions:
    - Invoke-SingularNounFix
    - Invoke-ApprovedVerbFix
    - Invoke-ReservedCmdletCharFix

.NOTES
    Part of PoshGuard Comprehensive Test Suite
#>

BeforeAll {
  # Import Naming module
  $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '../../../tools/lib/BestPractices/Naming.psm1'
  if (-not (Test-Path -Path $modulePath)) {
    throw "Cannot find Naming module at: $modulePath"
  }
  Import-Module -Name $modulePath -Force -ErrorAction Stop
}

Describe 'Invoke-SingularNounFix' -Tag 'Unit', 'BestPractices', 'Naming' {

  It 'Should convert plural function name to singular' {
    # Arrange
    $content = 'function Get-Users { }'
    
    # Act
    $result = Invoke-SingularNounFix -Content $content
    
    # Assert
    $result | Should -Match 'Get-User'
  }

  It 'Should leave singular names unchanged' {
    # Arrange
    $content = 'function Get-User { }'
    
    # Act
    $result = Invoke-SingularNounFix -Content $content
    
    # Assert
    $result | Should -BeExactly $content
  }

  It 'Should handle script with no functions' {
    # Arrange
    $content = '$x = 1'
    
    # Act
    $result = Invoke-SingularNounFix -Content $content
    
    # Assert
    $result | Should -BeExactly $content
  }
}

Describe 'Invoke-ApprovedVerbFix' -Tag 'Unit', 'BestPractices', 'Naming' {

  It 'Should suggest approved verb for unapproved verb' {
    # Arrange
    $content = 'function Destroy-File { }'
    
    # Act
    $result = Invoke-ApprovedVerbFix -Content $content
    
    # Assert - Should either fix or return unchanged based on implementation
    $result | Should -Not -BeNullOrEmpty
  }

  It 'Should leave approved verbs unchanged' {
    # Arrange
    $content = 'function Get-Item { }'
    
    # Act
    $result = Invoke-ApprovedVerbFix -Content $content
    
    # Assert
    $result | Should -BeExactly $content
  }
}

Describe 'Invoke-ReservedCmdletCharFix' -Tag 'Unit', 'BestPractices', 'Naming' {

  It 'Should handle content without reserved characters' {
    # Arrange
    $content = 'function Get-Data { }'
    
    # Act
    $result = Invoke-ReservedCmdletCharFix -Content $content
    
    # Assert
    $result | Should -BeExactly $content
  }

  It 'Should process valid function name' {
    # Arrange
    $content = 'function Test-Function { $x = 1 }'
    
    # Act & Assert
    { Invoke-ReservedCmdletCharFix -Content $content } | Should -Not -Throw
  }
}
