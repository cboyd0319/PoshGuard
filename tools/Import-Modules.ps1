#!/usr/bin/env pwsh
#requires -Version 5.1

$engineRoot = $PSScriptRoot

Import-Module "$engineRoot/../modules/Core/Core.psm1" -Force
Import-Module "$engineRoot/../modules/Configuration/Configuration.psm1"
Import-Module "$engineRoot/../modules/FileSystem/FileSystem.psm1"
Import-Module "$engineRoot/../modules/Analysis/Analysis.psm1"
Import-Module "$engineRoot/../modules/Fixing/Fixing.psm1"
Import-Module "$engineRoot/../modules/Reporting/Reporting.psm1"
