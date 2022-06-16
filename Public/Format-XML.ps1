Function Format-XML {
	[CmdLetBinding()]
	Param (
		[Parameter(ParameterSetName = 'File')]
			[String]$File,
		[Parameter(ParameterSetName = 'XML')]
			[XML]$XML,
		[Parameter(ParameterSetName = 'File')]
		[Parameter(ParameterSetName = 'XML')]
			[Int]$Indent = 4,
		[Parameter(ParameterSetName = 'File')]
		[Parameter(ParameterSetName = 'XML')]
			[String]$OutPath = "$Env:UserProfile\Documents\Formatted_XML.xml"
	)
	
	If ($PSCmdLet.ParameterSetName = 'File') {
		$XML = [XML](Get-Content -Path $File)
	}
	
    $StringWriter 			= [System.IO.StringWriter]::new()
    $XmlWriter 				= [System.XMl.XmlTextWriter]::new($StringWriter)
    
	$XmlWriter.Formatting 	= “indented”
    $XmlWriter.Indentation	= $Indent
    
	$Xml.WriteContentTo($XmlWriter)
    
	$XmlWriter.Flush()
    $StringWriter.Flush()
    
	$StringWriter.ToString() | 
		Out-File -FilePath $OutPath -Force
}