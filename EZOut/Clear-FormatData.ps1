function Clear-FormatData
{
    <#
    .Synopsis
        Clears formatting to the current session.
    .Description
        The Clear-FormatData command removes the formatting data for the current session.
        The formatting data must have been added with Add-FormatData
    .Example
        Clear-FormatData
    .Link
        Add-FormatData
    .Link
        Remove-FormatData
    #>
    [OutputType([Nullable])]
    param()

    #region Clear module and reset data     
    $FormatModules.Values | Remove-Module
    $Script:FormatModules = @{}   
    #endregion Clear module and reset data
}
