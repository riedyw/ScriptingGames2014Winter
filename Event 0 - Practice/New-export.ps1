﻿#========================================================================
# 
# Created on:   1/5/2014 1:08 PM
# Created by:   Administrator
# Organization: 
# Filename:     
#========================================================================



Function New-Chart {
<#
        .SYNOPSIS
                        New-Chart

        .DESCRIPTION
                        This function creates Charts according to the given parameters. Charts are available as a byte array in the output

        .PARAMETER  Computers
                        This represents the computers object array which shall be analyzed.

        .PARAMETER  Path
                        This represents the path where the charts shall be created at.

        .PARAMETER  Roles
                        Create a chart about the computers Roles like IIS, SQL, Sharepoint or Exchange.

        .PARAMETER  Hardware
                        Create a chart about the computers Hardware such as the Manufacturer, the CPU...

        .PARAMETER  OS
                        Create a chart about the computers OS and Service Pack.

        .EXAMPLE
                        PS C:\> New-Chart -Computers $computers -Path "C:\ps" -Roles -OS -Hardware
                        Path                                                        Title
                        ----                                                        -----
                        C:\ps\Chart-Roles.png                                       Roles
                        C:\ps\CPU.png                                               CPU
                        C:\ps\MemoryGB.png                                          MemoryGB
                        C:\ps\Manufacturer.png                                      Manufacturer
                        C:\ps\Model.png                                             Model
                        C:\ps\ServicePack.png                                       ServicePack
                        ...
                        This example shows how to call the New-Chart function with named parameters.

        .INPUTS
                        TODO: Determine if object or object[]

        .OUTPUTS
                        System.Array

        .NOTES
                        This function rely on the .NET Framework version 4.0 or higher to generate graphical charts, 
                        MS Charts need to be installed for .NET versions which are below 4.0 such as 3.5

        .LINK
                        MS Charts: http://www.microsoft.com/en-us/download/details.aspx?id=14422

        .LINK
                        about_functions_advanced

        .LINK
                        about_comment_based_help

        .LINK
                        about_functions_advanced_parameters

        .LINK
                        about_functions_advanced_methods
#>
    [cmdletbinding()]
    Param(
        [Parameter(
                  Mandatory=$true,
                  Position=0)]
                [object]$Computers,
                
        [Parameter(
                  Mandatory=$true,
                  Position=1)]
                [object]$Path,
                
                [switch]$Roles,
                
                [switch]$Hardware,
                
                [switch]$OS
    )
        
        BEGIN {
                #--- Code: TODO: Check for .NET framework here
                
                Write-Verbose -Message "Loading the Data Visualization assembly"
                #--- Code: TODO: replace with add-type, partialname is meh
                [void][Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms.DataVisualization")
                
                [array]$output = @()
        }
        
        PROCESS {
                #--- Code: The roles need to be graphed
                if ($Roles) {
                        Write-Verbose -Message "Generating a chart for the roles"
                        
                        #--- Code: First, we create the chart object
                        $chart = New-object System.Windows.Forms.DataVisualization.Charting.Chart
                        $chart.BackColor = "White"
                        $chart.Width = 500
                        $chart.Height = 500
                        
                        #--- Code: We name our chart
                        [void]$chart.Titles.Add("Detected Roles")
                        $chart.Titles[0].Alignment = "topLeft"
                        $chart.Titles[0].Font = "Tahoma,13pt"
                        
                        #--- Code: We create the chart area
                        $chartarea = New-Object System.Windows.Forms.DataVisualization.Charting.ChartArea
                        $chartarea.Name = "ChartArea1"
                        # $chartarea.Area3DStyle.Enable3D = $true
                        $chartarea.AxisX.Interval = 1
                        $chartarea.AxisX.MajorGrid.LineColor = "#d1d1d1"
                        $chartarea.AxisX.Title = "Role"
                        $chartarea.AxisY.Interval = 5
                        $chartarea.AxisY.MajorGrid.LineColor = "#d1d1d1"
                        $chartarea.AxisY.Title = "Count"
                        $chartarea.BackColor = "White"
                        $chartarea.BackGradientStyle = "DiagonalRight"
                        $chartarea.BackSecondaryColor = "#d3e6ff"
                        $chart.ChartAreas.Add($chartarea)
                        
                        #--- Code: We create the serie now
                        [void]$chart.Series.Add("Data")
                        $chart.Series["Data"].BorderColor = "#1062ba"
                        $chart.Series["Data"].BorderDashStyle="Solid"
                        $chart.Series["Data"].BorderWidth = 1
                        $chart.Series["Data"].ChartArea = "ChartArea1"
                        $chart.Series["Data"].ChartType = "Column"
                        $chart.Series["Data"].Color = "#6aaef7"
                        $chart.Series["Data"].IsValueShownAsLabel = $true
                        $chart.Series["Data"].IsVisibleInLegend = $true
                        
                        #--- Code: As we're dealing with multiple objects, we're grouping the properties and check which ones are considered true
                        $Computers | Group-Object -Property IISInstalled | Where-Object { $_.Name -eq $true } | ForEach-Object {
                                [void]$chart.Series["Data"].Points.AddXY("IIS", $_.Count) 
                        }
                        $Computers | Group-Object -Property SQLInstalled | Where-Object { $_.Name -eq $true } | ForEach-Object {
                                [void]$chart.Series["Data"].Points.AddXY("SQL", $_.Count) 
                        }
                        $Computers | Group-Object -Property ExchangeInstalled | Where-Object { $_.Name -eq $true } | ForEach-Object {
                                [void]$chart.Series["Data"].Points.AddXY("Exchange", $_.Count) 
                        }
                        $Computers | Group-Object -Property SharepointInstalled | Where-Object { $_.Name -eq $true } | ForEach-Object {
                                [void]$chart.Series["Data"].Points.AddXY("Sharepoint", $_.Count) 
                        }
                        
                        #--- Code: We save the chart now
                        # $stream = New-Object System.IO.MemoryStream
                        # $chart.SaveImage($stream, "png")
                        
                        $chart.SaveImage("$Path\Chart-Roles.png","png")
                        # $output += New-Object PSObject -Property @{Label = "Roles"; Bytes = $stream.GetBuffer()}
                        $output += New-Object PSObject -Property @{Title = "Roles"; Path = "$Path\Chart-Roles.png"}
                        
                        #$today = (Get-Date).ToString("yyyy-MM-dd")
                        # $chart.SaveImage("$Path\Chart-Roles.png","png")
                        #Write-Output "$Path\Chart-Roles-$today.png"
                }
                        
                #--- Code: Either the Hardware or the OS shall be shown
                if ($Hardware -or $OS) {
                        Write-Debug -Message "New object properties may be added below to generate additionals charts"
                        
                        #--- Code: Cast as an array to prevent single elements from showing as an object
                        [array]$properties = @()
                        
                        #--- Code: Nested array (Object property name, Chart title, X Axis label)
                        if ($Hardware) {
                                $properties += @(
                                        New-Object PSObject -Property @{PropertyName = "CPU"; ChartTitle = "CPU Sockets Found"; TitleXAxis = "CPU Sockets"}
                                        New-Object PSObject -Property @{PropertyName = "MemoryGB"; ChartTitle = "Memory Found"; TitleXAxis = "Memory (GB)"}
                                        New-Object PSObject -Property @{PropertyName = "Manufacturer"; ChartTitle = "Manufacturer Found"; TitleXAxis = "Manufacturer Name"}
                                        New-Object PSObject -Property @{PropertyName = "Model"; ChartTitle = "Model Found"; TitleXAxis = "Model Name"}
                                )
                        }
                        
                        if ($OS) {
                                $properties += @(
                                        New-Object PSObject -Property @{PropertyName = "OS"; ChartTitle = "OS Found"; TitleXAxis = "OS"}
                                        New-Object PSObject -Property @{PropertyName = "ServicePack"; ChartTitle = "Service Pack Found"; TitleXAxis = "Service Pack Name"}
                                )
                        }
                        
                        ForEach ($data in $properties) {
                                Try {
                                        #--- Code: Check if the property exists first.
                                        If (($Computers | Get-Member | Select -ExpandProperty Name) -Contains $data.PropertyName) {
                                                Write-Verbose -Message "Generating a chart for the property '$($data.PropertyName)'"
                                                
                                                #--- Code: First, we create the chart object
                                                $chart = New-object System.Windows.Forms.DataVisualization.Charting.Chart
                                                $chart.BackColor = "White"
                                                $chart.Width = 500
                                                $chart.Height = 500
                                                
                                                #--- Code: We name our chart
                                                [void]$chart.Titles.Add($data.ChartTitle)
                                                $chart.Titles[0].Alignment = "topLeft"
                                                $chart.Titles[0].Font = "Tahoma,13pt"
                                                
                                                #--- Code: We create the chart area
                                                $chartarea = New-Object System.Windows.Forms.DataVisualization.Charting.ChartArea
                                                $chartarea.Name = "ChartArea1"
                                                $chartarea.AxisX.Interval = 1
                                                $chartarea.AxisX.MajorGrid.LineColor = "#d1d1d1"
                                                $chartarea.AxisX.Title = $data.TitleXAxis
                                                $chartarea.AxisY.Interval = 5
                                                $chartarea.AxisY.MajorGrid.LineColor = "#d1d1d1"
                                                $chartarea.AxisY.Title = "Count"
                                                $chartarea.BackColor = "White"
                                                $chartarea.BackGradientStyle = "DiagonalRight"
                                                $chartarea.BackSecondaryColor = "#d3e6ff"
                                                $chart.ChartAreas.Add($chartarea)
                                                
                                                #--- Code: We create the serie now
                                                [void]$chart.Series.Add("Role")
                                                $chart.Series["Role"].BorderColor = "#1062ba"
                                                $chart.Series["Role"].BorderDashStyle="Solid"
                                                $chart.Series["Role"].BorderWidth = 1
                                                $chart.Series["Role"].ChartArea = "ChartArea1"
                                                $chart.Series["Role"].ChartType = "Column"
                                                $chart.Series["Role"].Color = "#6aaef7"
                                                $chart.Series["Role"].IsValueShownAsLabel = $true
                                                $chart.Series["Role"].IsVisibleInLegend = $true
                                                
                                                $Computers | Group-Object -Property $data.PropertyName | ForEach-Object {
                                                        [void]$chart.Series["Role"].Points.AddXY($_.Name, $_.Count) 
                                                }
                                                
                                                #--- Code: We save the chart now
                                                # $stream = New-Object System.IO.MemoryStream
                                                # $chart.SaveImage($stream, "png")
                                                
                                                # $output += New-Object PSObject -Property @{Label = $data.PropertyName; Bytes = $stream.GetBuffer()}
                                                $chart.SaveImage("$Path\Chart-$($data.PropertyName).png","png")
                                                $output += New-Object PSObject -Property @{Title = $data.PropertyName; Path = "$Path\Chart-$($data.PropertyName).png"}
                                                
                                                #$today = (Get-Date).ToString("yyyy-MM-dd")
                                                # $chart.SaveImage("$Path\Chart-$($data.PropertyName)-$today.png","png")
                                                #Write-Output "$Path\Chart-$($data.PropertyName)-$today.png"
                                        } Else {
                                                Write-Warning -Message "The property '$($data.PropertyName)' does not exist in the given object"
                                        }
                                } Catch {
                                        
                                }
                        }
                }
        }
        
        END {
                return $output
        }
}

function Export-PowerPoint {
		<#
	.SYNOPSIS
	Exports Charts to PowerPoint format

	.DESCRIPTION
	Export the graphs to a powerpoint presentation.
	
	.PARAMETER  <ExportPath>
	Specifies de export path (must be have either .ppt or pptx as extension).
	
	.PARAMETER  <Debug>
	This parameter is optional, and will if called, activate the deubbing mode wich can help to troubleshoot the script if needed. 

	.NOTES
	-Version 0.1
	-Author : Stéphane van Gulick
	-Creation date: 01/06/2012
	-Creation date: 01/06/2012
	-Script revision history
	##0.1 : Initilisation
	##0.2 : First version
	##0.3 : Added Image possibilities

	.EXAMPLE
	Exportto-html -Data (Get-Process) -Path "d:\temp\export.html" -title "Data export"
	
	Exports data to a HTML file located in d:\temp\export.html with a title "Data export"
	
	.EXAMPLE
	In order to call the script in debugging mode
	Exportto-html  -Image $ByteImage -Data (Get-service) "d:\temp\export.html" -title "Data Service export"
	
	Exports data to a HTML file located in d:\temp\export.html with a title "Data export". Adds also an image in the HTML output.
	#Remark: -image must be  of Byte format.
#>
	
	[cmdletbinding()]
	
		Param(
		
		[Parameter(mandatory=$true)]$Path = $(throw "Path is mandatory, please provide a value."),
		[Parameter(mandatory=$true)]$GraphInfos,
		[Parameter(mandatory=$false)]$title,
		[Parameter(mandatory=$false)]$Subtitle
		
		)

	Begin {
		Add-type -AssemblyName office
		Add-Type -AssemblyName microsoft.office.interop.powerpoint
		#DEfining PowerPoints main variables
			$MSTrue=[Microsoft.Office.Core.MsoTriState]::msoTrue
			$MsFalse=[Microsoft.Office.Core.MsoTriState]::msoFalse
			$slideTypeTitle = [microsoft.office.interop.powerpoint.ppSlideLayout]::ppLayoutTitle
			$SlideTypeChart = [microsoft.office.interop.powerpoint.ppSlideLayout]::ppLayoutChart
			
		#Creating the ComObject
			$Application = New-Object -ComObject powerpoint.application
			#$application.visible = $MSTrue
	}
	Process{
		#Creating the presentation
			$Presentation = $Application.Presentations.add() 
		#Adding the first slide
			$Titleslide = $Presentation.Slides.add(1,$slideTypeTitle)
			$Titleslide.Shapes.Title.TextFrame.TextRange.Text = $Title
			$Titleslide.shapes.item(2).TextFrame.TextRange.Text = $Subtitle
			$Titleslide.BackgroundStyle = 11

		#Adding the charts
		foreach ($Graphinfo in $GraphInfos) {

			#Adding slide
			$slide = $Presentation.Slides.add($Presentation.Slides.count+1,$SlideTypeChart)

			#Defining slide type:
			#http://msdn.microsoft.com/en-us/library/microsoft.office.interop.powerpoint.ppslidelayout(v=office.14).aspx
					$slide.Layout = $SlideTypeChart
					$slide.BackgroundStyle = 11
					$slide.Shapes.Title.TextFrame.TextRange.Text = $Graphinfo.title
			#Adding picture (chart) to presentation:
				#http://msdn.microsoft.com/en-us/library/office/bb230700(v=office.12).aspx
					$Picture = $slide.Shapes.AddPicture($Graphinfo.Path,$mstrue,$msTrue,300,100,350,400)
		}
	}
end {
		$presentation.Saveas($exportPath)
	 	$presentation.Close()
		$Application.quit()
		[gc]::collect()
		[gc]::WaitForPendingFinalizers()
		$Application =  $null
	}
	
}

Function Export-html {
	
	<#
	.SYNOPSIS
	Exports data to HTML format

	.DESCRIPTION
	ExportTo-HTML has a personalized CSS code which make the output nicer then the classical ConvertTo-Html and allows to add images / graphs in the HTML output
	
	.PARAMETER  <Debug>
	This parameter is optional, and will if called, activate the deubbing mode wich can help to troubleshoot the script if needed. 
	
	.NOTES
	-Version 0.1
	-Author : Stéphane van Gulick
	-Creation date: 01/06/2012
	-Creation date: 01/06/2012
	-Script revision history
	##0.1 : Initilisation
	##0.2 : First version
	##0.3 : Added Image possibilities

	
	
	.EXAMPLE
	Exportto-html -Data (Get-Process) -Path "d:\temp\export.html" -title "Data export"
	
	Exports data to a HTML file located in d:\temp\export.html with a title "Data export"
	
	.EXAMPLE
	In order to call the script in debugging mode
	Exportto-html  -Image $ByteImage -Data (Get-service) "d:\temp\export.html" -title "Data Service export"
	
	Exports data to a HTML file located in d:\temp\export.html with a title "Data export". Adds also an image in the HTML output.
	#Remark: -image must be  of Byte format.
#>
	
	[cmdletbinding()]
	
		Param(
		
		[Parameter(mandatory=$true)]$Path = $(throw "Path is mandatory, please provide a value."),
		[Parameter(mandatory=$false)]$Data,
		[Parameter(mandatory=$false)]$title,
		[Parameter(mandatory=$false)]$Subtitle,
		[Parameter(mandatory=$false)]$Image
		
		)
	Begin{
	
		#Preparing HTML header:
		
		$HtmlHeader = @" 
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://
www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="en" xml:lang="en">
<head>
<style type="text/css">
<!--body {
background-color: #66CCFF;
} 
table {
background-color: white;
margin: 5px;
top: 10px;
display: inline-block;
padding: 5px;
border: 1px solid black
}
h2 {
clear: both;
width:500px;
padding:10px;
border:5px solid gray;	
text-align:center;
font-size: 150%;
margin-left: auto;
margin-right: auto;
margin-top: auto;
}
h3 {
clear: both;
color: #FF0000;
font-size: 115%;
margin-left: 10px;
margin-top: 15px;
text-align: center;
}
p {
color: #FF0000;
margin-left: 10px;
margin-top: 15px; 
}
IMG.Graphs {
display: block;
    margin-left: auto;
    margin-right: auto
}
tr:nth-child(odd) {background-color: lightgray}
-->
</style>
</head>
<body>
"@
		
		}
	Process{
	
		
		
                        #If HTML view has been selected, the returned service status will be exported to a HTML file as well
                        Write-Verbose "Exporting object to HTML $($path)"
                         
                          
                       	$htmltitle = "<h2>$($title)</h2>"
						$htmlSubtitle = "<h3>$($Subtitle)</h3>"
                       	$HtmlItem = $Data | ConvertTo-Html -Fragment
                           	
                      	if ($Image){
					$ImageHTML = @"
<IMG class="Graphs" src="data:image/jpg;base64,$($Image)" style="left: 50%" alt="Image01">
"@
			}
                  
	}         
	End{
			$HtmlHeader + $htmltitle + $htmlsubtitle+ $HtmlItem + $ImageHTML| Out-File $Path
		}
}

Function Get-Base64Image {
		<#
	.SYNOPSIS
	Converts an image to Byte type
	
	.DESCRIPTION
	Usefull in oder to add an image byte into HTML code and make the HTML file independant from any other external file.
	
	.PARAMETER <Path>
	File path to the original image file.
	
	.PARAMETER  <Debug>
	This parameter is optional, and will if called, activate the deubbing mode wich can help to troubleshoot the script if needed.
	
	#>
	
	[cmdletbinding()]
		
		Param(
		
		[Parameter(mandatory=$true)]$Path = $(throw "Path is mandatory, please provide a value.")
	)
	begin{}
	process{
		$ImageBytes = [Convert]::ToBase64String((Get-Content $Path -Encoding Byte))
	}
	End{
		return $ImageBytes
	}
}

function New-export {
	
[cmdletbinding()]
	
		Param(
		
		[Parameter(mandatory=$true)]$Path = $(throw "Path is mandatory, please provide a value."), #Full  path ? Or folder path ?
		[Parameter(mandatory=$true)]$Data,
		[Parameter(mandatory=$false)][Validateset("csv", "html", "powerpoint")][String]$Exportype,
		[Parameter(mandatory=$false, ParameterSetName="ppt")]$ArrayImage,
		[Parameter(mandatory=$false)]$title,
		[Parameter(mandatory=$false)]$Subtitle,
		[Parameter(mandatory=$false)]$Image
		
		)
	Begin {
		
		
			switch ($Exportype){
				
					("csv"){
						$FileName = "Export-$($Title).Csv"
						$ExportPath = Join-Path -Path $Path -ChildPath $FileName
						Write-Verbose "exporting the file to $($exportPath)"	
						$Data | Export-Csv -Path $ExportPath -NoTypeInformation
					}
					("Html"){
						$FileName = "Export-$($Title).html"
						$ExportPath = Join-Path -Path $Path -ChildPath $FileName
						Write-Verbose "exporting the file to $($exportPath)"	
						Export-html -Data $Data -title $title -Subtitle $Subtitle -Path $ExportPath
					}
					("PowerPoint"){
						$FileName = "Export-$($Title).pptx"
						$ExportPath = Join-Path -Path $Path -ChildPath $FileName
						Write-Verbose "exporting the file to $($exportPath)"	
						Export-powerPoint -title $Title -Subtitle $SubTitle -Path $ExportPath -GraphInfos $ArrayImage
					
					}
					default {
						Write-Host "none"
					}

			}
	}
	Process{
	
		}
	End{
	}
}

########Testing#############

$cp1 = New-Object PSObject -Property @{
        ComputerName                = "SRV001"
        IISInstalled                = $true
        SQLInstalled                = $true
        ExchangeInstalled        = $false
        SharepointInstalled        = $false
        CPU                                = 4
        MemoryGB                = 6
        Manufacturer        = "Allister Fisto Industries"
        Model                        = "Fistron 2000"
        ServicePack                = "Microsoft Windows Server 2008 R2 Enterprise"
}

$cp2 = New-Object PSObject -Property @{
        ComputerName                = "SRV002"
        IISInstalled                = $true
        SQLInstalled                = $true
        ExchangeInstalled        = $false
        SharepointInstalled        = $true
        CPU                                = 2
        MemoryGB                = 2
        Manufacturer        = "Allister Fisto Industries"
        Model                        = "Fistron 3000"
        ServicePack                = "Microsoft Windows Server 2008 R2 Standard"
}

$cp3 = New-Object PSObject -Property @{
        ComputerName                = "SRV003"
        IISInstalled                = $false
        SQLInstalled                = $false
        ExchangeInstalled        = $true
        SharepointInstalled        = $false
        CPU                                = 4
        MemoryGB                = 8
        Manufacturer        = "Allister Fisto Industries"
        Model                        = "Fistron 2000"
        ServicePack                = "Microsoft Windows Server 2008 Standard"
}

$computers = @($cp1, $cp2, $cp3)
$ByteImage  = Get-Base64Image "E:\Users\Administrator\SkyDrive\Scripting\Githhub\WinterScriptingGames2014\Event 0 - Practice\Charts\Chart-CPU-2014-01-06.png"

######ENDTESTING#####################

$Title  = "Posh-Monks"
$SubTitle = "Winter Scripting Games 2014 - Event:00 (Practice)"


#ExportTo-PowerPoint -Path "D:\temp\plop.pptx" -GraphInfos $a -title $Title -Subtitle $SubTitle
#Exportto-html  -Image $ByteImage -Data (Get-Process) -Path "d:\temp\plop.html" -title $Title -Subtitle  $SubTitle

$Output = New-Chart -Computers $computers -Path "d:\temp" -Roles -OS -Hardware
#Export powerpoint
	New-export -Path "d:\temp\" -Exportype "powerpoint"-title $Title -Subtitle $SubTitle -ArrayImage $output
#Export Html
	#New-export -Path "d:\temp\" -Exportype "html" -title $Title -Subtitle $SubTitle -Data $computers