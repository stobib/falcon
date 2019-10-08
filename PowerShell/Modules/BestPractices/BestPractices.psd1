#
# Module manifest for module 'BestPractices'
#
# Generated by: Microsoft Corporation
#
# Generated on: 10/04/2010
#

@{

# These modules will be processed when the module manifest is loaded.
NestedModules = 'Microsoft.BestPractices.Cmdlets.dll'

# This GUID is used to uniquely identify this module.
GUID = '5551ea86-919d-499b-948f-87305e4f2344'

# The author of this module.
Author = 'Microsoft Corporation'

# The company or vendor for this module.
CompanyName = 'Microsoft Corporation'

# The copyright statement for this module.
Copyright = '© Microsoft Corporation. All rights reserved.'

# The version of this module.
ModuleVersion = '1.0'

# The minimum version of PowerShell needed to use this module.
PowerShellVersion = '3.0'

# The CLR version required to use this module.
CLRVersion = '4.0'

# This is a list of other modules that this module depends on.
RequiredModules = @()

# Cmdlets to export from this module
CmdletsToExport = "Get-BpaModel","Get-BpaResult","Invoke-BpaModel","Set-BpaResult"

# The type files (.ps1xml) loaded by this module.
TypesToProcess = 'Microsoft.BestPractices.Types.ps1xml'

# The format files (.ps1xml) loaded by this module.
FormatsToProcess = 'Microsoft.BestPractices.Cmdlets.Formats.ps1xml'

# A list of assemblies that must be loaded before this module can work.
RequiredAssemblies = @()

# Module specific private data can be passed via this member.
PrivateData = ''

# BPA Help Infor Uri
HelpInfoUri="http://go.microsoft.com/fwlink/?LinkId=390754"

}

