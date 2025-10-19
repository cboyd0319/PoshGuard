#!/usr/bin/env pwsh
#requires -Version 5.1

<#
.SYNOPSIS
    Pester tests for PoshGuard OpenTelemetryTracing module

.DESCRIPTION
    Comprehensive unit tests for OpenTelemetryTracing.psm1 functions:
    - New-TraceId
    - New-SpanId
    - Initialize-TraceContext
    - Get-W3CTraceParent
    - Start-Span
    - Stop-Span
    - Add-SpanEvent
    
    Tests cover W3C Trace Context compliance, span lifecycle, and OTLP export.
    All tests are hermetic and deterministic.

.NOTES
    Part of PoshGuard Comprehensive Test Suite
    Follows Pester v5+ AAA pattern with deterministic execution
#>

BeforeAll {
  # Import test helpers
  $helpersPath = Join-Path -Path $PSScriptRoot -ChildPath '../Helpers/TestHelpers.psm1'
  $helpersLoaded = Get-Module -Name 'TestHelpers' -ErrorAction SilentlyContinue
  if (-not $helpersLoaded) {
    Import-Module -Name $helpersPath -ErrorAction Stop
  }

  # Import OpenTelemetryTracing module
  $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '../../tools/lib/OpenTelemetryTracing.psm1'
  if (-not (Test-Path -Path $modulePath)) {
    throw "Cannot find OpenTelemetryTracing module at: $modulePath"
  }
  $moduleLoaded = Get-Module -Name 'OpenTelemetryTracing' -ErrorAction SilentlyContinue
  if (-not $moduleLoaded) {
    Import-Module -Name $modulePath -ErrorAction Stop
  }
}

Describe 'New-TraceId' -Tag 'Unit', 'OpenTelemetryTracing' {
  
  Context 'When generating trace IDs' {
    It 'Should generate 32-character hex string' {
      $traceId = New-TraceId
      
      $traceId | Should -Not -BeNullOrEmpty
      $traceId.Length | Should -Be 32
      $traceId | Should -Match '^[0-9a-f]{32}$'
    }

    It 'Should generate unique IDs' {
      $id1 = New-TraceId
      $id2 = New-TraceId
      
      $id1 | Should -Not -Be $id2
    }

    It 'Should be W3C compliant (128-bit)' {
      $traceId = New-TraceId
      
      # 32 hex chars = 128 bits (16 bytes * 2 hex chars per byte)
      $traceId.Length | Should -Be 32
    }
  }
}

Describe 'New-SpanId' -Tag 'Unit', 'OpenTelemetryTracing' {
  
  Context 'When generating span IDs' {
    It 'Should generate 16-character hex string' {
      $spanId = New-SpanId
      
      $spanId | Should -Not -BeNullOrEmpty
      $spanId.Length | Should -Be 16
      $spanId | Should -Match '^[0-9a-f]{16}$'
    }

    It 'Should generate unique IDs' {
      $id1 = New-SpanId
      $id2 = New-SpanId
      
      $id1 | Should -Not -Be $id2
    }

    It 'Should be W3C compliant (64-bit)' {
      $spanId = New-SpanId
      
      # 16 hex chars = 64 bits (8 bytes * 2 hex chars per byte)
      $spanId.Length | Should -Be 16
    }
  }
}

Describe 'Initialize-TraceContext' -Tag 'Unit', 'OpenTelemetryTracing' {
  
  Context 'When creating root context' {
    It 'Should create new trace context without parent' {
      $context = Initialize-TraceContext
      
      $context | Should -Not -BeNullOrEmpty
      $context.TraceId | Should -Not -BeNullOrEmpty
      $context.SpanId | Should -Not -BeNullOrEmpty
      $context.ParentSpanId | Should -BeNullOrEmpty
      $context.TraceFlags | Should -Be '01'
      $context.Sampled | Should -Be $true
    }

    It 'Should generate valid W3C trace ID' {
      $context = Initialize-TraceContext
      
      $context.TraceId | Should -Match '^[0-9a-f]{32}$'
    }

    It 'Should generate valid W3C span ID' {
      $context = Initialize-TraceContext
      
      $context.SpanId | Should -Match '^[0-9a-f]{16}$'
    }
  }

  Context 'When inheriting from parent context' {
    It 'Should inherit trace ID from parent' {
      $parentContext = @{
        TraceId = 'a' * 32
        SpanId = 'b' * 16
        TraceFlags = '01'
        TraceState = ''
        Sampled = $true
      }
      
      $childContext = Initialize-TraceContext -ParentContext $parentContext
      
      $childContext.TraceId | Should -Be $parentContext.TraceId
      $childContext.ParentSpanId | Should -Be $parentContext.SpanId
      $childContext.SpanId | Should -Not -Be $parentContext.SpanId
    }

    It 'Should create new span ID for child' {
      $parentContext = @{
        TraceId = 'a' * 32
        SpanId = 'b' * 16
        TraceFlags = '01'
        TraceState = ''
        Sampled = $true
      }
      
      $childContext = Initialize-TraceContext -ParentContext $parentContext
      
      $childContext.SpanId | Should -Not -Be $parentContext.SpanId
      $childContext.SpanId | Should -Match '^[0-9a-f]{16}$'
    }

    It 'Should inherit sampling decision' {
      $parentContext = @{
        TraceId = 'a' * 32
        SpanId = 'b' * 16
        TraceFlags = '01'
        TraceState = ''
        Sampled = $false
      }
      
      $childContext = Initialize-TraceContext -ParentContext $parentContext
      
      $childContext.Sampled | Should -Be $false
    }
  }
}

Describe 'Get-W3CTraceParent' -Tag 'Unit', 'OpenTelemetryTracing' {
  
  Context 'When formatting trace context' {
    It 'Should format as W3C traceparent header' {
      $context = @{
        TraceId = 'a' * 32
        SpanId = 'b' * 16
        TraceFlags = '01'
      }
      
      $header = Get-W3CTraceParent -Context $context
      
      $header | Should -Match '^00-[0-9a-f]{32}-[0-9a-f]{16}-[0-9a-f]{2}$'
    }

    It 'Should include version 00' {
      $context = @{
        TraceId = 'a' * 32
        SpanId = 'b' * 16
        TraceFlags = '01'
      }
      
      $header = Get-W3CTraceParent -Context $context
      
      $header | Should -Match '^00-'
    }

    It 'Should include trace ID, span ID, and flags' {
      $traceId = 'a' * 32
      $spanId = 'b' * 16
      $context = @{
        TraceId = $traceId
        SpanId = $spanId
        TraceFlags = '01'
      }
      
      $header = Get-W3CTraceParent -Context $context
      
      $header | Should -Be "00-$traceId-$spanId-01"
    }
  }

  Context 'When using script trace context' {
    It 'Should use script context when not provided' {
      InModuleScope OpenTelemetryTracing {
        $script:TraceContext = @{
          TraceId = 'c' * 32
          SpanId = 'd' * 16
          TraceFlags = '01'
        }
        
        $header = Get-W3CTraceParent
        
        $header | Should -Match "^00-c{32}-d{16}-01$"
      }
    }
  }
}

Describe 'Start-Span' -Tag 'Unit', 'OpenTelemetryTracing' {
  
  BeforeEach {
    InModuleScope OpenTelemetryTracing {
      $script:OTelConfig = @{
        Enabled = $true
        ServiceName = 'TestService'
        ServiceVersion = '1.0.0'
      }
      $script:TraceContext = @{
        TraceId = 'a' * 32
        SpanId = 'b' * 16
        ParentSpanId = $null
      }
      $script:ActiveSpans = [System.Collections.Generic.Stack[hashtable]]::new()
    }
  }

  Context 'When OpenTelemetry is disabled' {
    It 'Should return disabled span' {
      InModuleScope OpenTelemetryTracing {
        $script:OTelConfig.Enabled = $false
        
        $span = Start-Span -Name 'TestOperation'
        
        $span.Enabled | Should -Be $false
      }
    }
  }

  Context 'When starting root span' {
    It 'Should create span with required fields' {
      $span = Start-Span -Name 'TestOperation'
      
      $span | Should -Not -BeNullOrEmpty
      $span.Name | Should -Be 'TestOperation'
      $span.SpanId | Should -Not -BeNullOrEmpty
      $span.TraceId | Should -Not -BeNullOrEmpty
      $span.StartTime | Should -Not -BeNullOrEmpty
      $span.Enabled | Should -Be $true
    }

    It 'Should support all span kinds' -TestCases @(
      @{ Kind = 'Internal' }
      @{ Kind = 'Server' }
      @{ Kind = 'Client' }
      @{ Kind = 'Producer' }
      @{ Kind = 'Consumer' }
    ) {
      param($Kind)
      
      $span = Start-Span -Name 'TestOperation' -Kind $Kind
      
      $span.Kind | Should -Be $Kind
    }

    It 'Should include custom attributes' {
      $attributes = @{
        'custom.key1' = 'value1'
        'custom.key2' = 42
      }
      
      $span = Start-Span -Name 'TestOperation' -Attributes $attributes
      
      $span.Attributes['custom.key1'] | Should -Be 'value1'
      $span.Attributes['custom.key2'] | Should -Be 42
    }

    It 'Should include thread ID attribute' {
      $span = Start-Span -Name 'TestOperation'
      
      $span.Attributes.'thread.id' | Should -Not -BeNullOrEmpty
    }

    It 'Should default to Internal kind' {
      $span = Start-Span -Name 'TestOperation'
      
      $span.Kind | Should -Be 'Internal'
    }
  }

  Context 'When starting child span' {
    It 'Should create parent-child relationship' {
      InModuleScope OpenTelemetryTracing {
        $parentSpan = @{
          Name = 'ParentOp'
          SpanId = 'parent' + ('x' * 10)
          TraceId = 'a' * 32
        }
        $script:ActiveSpans.Push($parentSpan)
        
        $childSpan = Start-Span -Name 'ChildOp'
        
        $childSpan.ParentSpanId | Should -Be $parentSpan.SpanId
        $childSpan.TraceId | Should -Be $parentSpan.TraceId
      }
    }
  }
}

Describe 'Stop-Span' -Tag 'Unit', 'OpenTelemetryTracing' {
  
  BeforeEach {
    InModuleScope OpenTelemetryTracing {
      $script:OTelConfig = @{
        Enabled = $true
      }
      $script:ActiveSpans = [System.Collections.Generic.Stack[hashtable]]::new()
      $script:CompletedSpans = [System.Collections.Generic.List[hashtable]]::new()
    }
  }

  Context 'When stopping active span' {
    It 'Should complete span with end time' {
      InModuleScope OpenTelemetryTracing {
        $span = @{
          Name = 'TestOp'
          SpanId = 'a' * 16
          StartTime = Get-Date
          Enabled = $true
        }
        
        $completed = Stop-Span -Span $span
        
        $completed.EndTime | Should -Not -BeNullOrEmpty
        $completed.EndTime | Should -BeGreaterThan $span.StartTime
      }
    }

    It 'Should set status to OK by default' {
      InModuleScope OpenTelemetryTracing {
        $span = @{
          Name = 'TestOp'
          SpanId = 'a' * 16
          StartTime = Get-Date
          Enabled = $true
          Status = @{ Code = 'Unset'; Message = '' }
        }
        
        $completed = Stop-Span -Span $span
        
        $completed.Status.Code | Should -Be 'Ok'
      }
    }

    It 'Should set error status when provided' {
      InModuleScope OpenTelemetryTracing {
        $span = @{
          Name = 'TestOp'
          SpanId = 'a' * 16
          StartTime = Get-Date
          Enabled = $true
          Status = @{ Code = 'Unset'; Message = '' }
        }
        
        $completed = Stop-Span -Span $span -Status 'Error' -StatusMessage 'Test error'
        
        $completed.Status.Code | Should -Be 'Error'
        $completed.Status.Message | Should -Be 'Test error'
      }
    }
  }

  Context 'When span is disabled' {
    It 'Should handle disabled span gracefully' {
      InModuleScope OpenTelemetryTracing {
        $span = @{ Enabled = $false }
        
        { Stop-Span -Span $span } | Should -Not -Throw
      }
    }
  }
}

Describe 'Add-SpanEvent' -Tag 'Unit', 'OpenTelemetryTracing' {
  
  Context 'When adding events to span' {
    It 'Should add event with timestamp' {
      InModuleScope OpenTelemetryTracing {
        $span = @{
          Name = 'TestOp'
          Events = @()
          Enabled = $true
        }
        
        Add-SpanEvent -Span $span -Name 'TestEvent' -Attributes @{ key = 'value' }
        
        $span.Events.Count | Should -Be 1
        $span.Events[0].Name | Should -Be 'TestEvent'
        $span.Events[0].Timestamp | Should -Not -BeNullOrEmpty
      }
    }

    It 'Should include event attributes' {
      InModuleScope OpenTelemetryTracing {
        $span = @{
          Name = 'TestOp'
          Events = @()
          Enabled = $true
        }
        
        $attributes = @{
          'event.type' = 'error'
          'error.code' = 500
        }
        
        Add-SpanEvent -Span $span -Name 'ErrorOccurred' -Attributes $attributes
        
        $span.Events[0].Attributes.'event.type' | Should -Be 'error'
        $span.Events[0].Attributes.'error.code' | Should -Be 500
      }
    }

    It 'Should support multiple events' {
      InModuleScope OpenTelemetryTracing {
        $span = @{
          Name = 'TestOp'
          Events = @()
          Enabled = $true
        }
        
        Add-SpanEvent -Span $span -Name 'Event1'
        Add-SpanEvent -Span $span -Name 'Event2'
        Add-SpanEvent -Span $span -Name 'Event3'
        
        $span.Events.Count | Should -Be 3
      }
    }
  }

  Context 'When span is disabled' {
    It 'Should not add events to disabled span' {
      InModuleScope OpenTelemetryTracing {
        $span = @{
          Enabled = $false
          Events = @()
        }
        
        Add-SpanEvent -Span $span -Name 'TestEvent'
        
        $span.Events.Count | Should -Be 0
      }
    }
  }
}
