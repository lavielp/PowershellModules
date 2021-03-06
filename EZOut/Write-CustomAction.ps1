function Write-CustomAction
{
    [CmdletBinding(DefaultParameterSetName='Action')]
    param(
    # The script block used to fill in the contents of a custom control.
    # The script block can either be an arbitrary script, which will be run, or it can include a 
    # number of speicalized commands that will translate into parts of the formatter.
    [Parameter(ParameterSetName='Action',
        Mandatory=$true,
        ValueFromPipelineByPropertyName=$true)]
    [ScriptBlock[]]
    $Action,
    
    # The indentation depth of the custom control    
    [Parameter(ParameterSetName='Action',
        ValueFromPipelineByPropertyName=$true)]
    [int]
    $Indent,

    # If set, the content will be created as a control, which can be used
    [Parameter(ParameterSetName='Action',ValueFromPipelineByPropertyName=$true)]
    [Switch]$AsControl,
    
    # The name of the action
    [Parameter(ParameterSetName='Action',ValueFromPipelineByPropertyName=$true)]    
    [String]$Name,
        
    # The VisibilityCondition parameter is used to add a condition that will determine
    # if the content will be rendered.
    [ScriptBlock[]]$VisibilityCondition = {}
    )
    
    process {
$header = @"
        <CustomControl>
            <CustomEntries>
                <CustomEntry>
                  <CustomItem>
                    <Frame>
                    $(if ($Indent) { "<LeftIndent>$Indent</LeftIndent>" } )
<CustomItem>
"@

$footer = @"
</CustomItem>            
                    </Frame>
                    </CustomItem>
                </CustomEntry>
            </CustomEntries>
        </CustomControl>
"@        


            $c =0
            $middle = foreach ($sb in $Action) {                 
                $VisibilityXml =""                
                if ("$($VisibilityCondition[$c])") {
                    $VisibilityXml = "<ItemSelectionCondition><ScriptBlock>
$([Security.SecurityElement]::Escape($VisibilityCondition[$c]))
</ScriptBlock></ItemSelectionCondition>"
                }
                $c++
                $tokens = @([Management.Automation.PSParser]::Tokenize($sb, [ref]$null) | 
                    Where-Object { "Comment", "NewLine" -notcontains $_.Type })
                Write-Verbose "$($tokens | Out-String)"
                if ($tokens.Count -eq 1) {
                    if ($tokens[0].Type -eq "Command" -and $tokens[0].Content -ieq "Write-Newline") {
                        "<NewLine />"
                    } elseif ($tokens[0].Type -eq "String") {
                        $content = $tokens[0].Content
                        # If the expanded size is the same as the original size, then the string most likely didn't 
                        # contain expansion, and we can write out a text field instead
                        if (-not ($content.Contains('$'))) {
                            "<Text>$([Security.SecurityElement]::Escape($content))</Text>"
                        } else {
                            "<ExpressionBinding>
                                $VisibilityXml
                                <ScriptBlock>`"$([Security.SecurityElement]::Escape($content))`"</ScriptBlock>
                            </ExpressionBinding>"
                        }
                    } else {
                        "<ExpressionBinding>
                            $VisibilityXml
                            <ScriptBlock>$([Security.SecurityElement]::Escape($sb))</ScriptBlock>
                        </ExpressionBinding>"                    
                    }
                } elseif ($tokens[0].Type -eq "Command" -and $tokens[0].Content -eq "Show-CustomAction") {
                    # If the script block was Expand-FormatView go ahead and run it
                    $result = & $sb
                    if ($result) {
                        $result.Insert("<ExpressionBinding>".Length + 1, $VisibilityXml)
                    }
                } else {
                    "<ExpressionBinding>
                        $VisibilityXml
                        <ScriptBlock>$([Security.SecurityElement]::Escape($sb))</ScriptBlock>
                    </ExpressionBinding>"                
                }                
            }
            if (-not $AsControl) {
                $header + $middle + $footer           
            } else {
                if (-not $Name) {
                    Write-Error "Custom Controls must be named"
                    return
                }
                
                "<Control><Name>$Name</Name>" + $header + $middle + $footer + "</Control>"
            }
    }
}