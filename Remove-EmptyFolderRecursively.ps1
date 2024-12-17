#Requires -Modules PSFramework

function Remove-EmptyFolderRecursively {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(
            Mandatory,
            ValueFromPipeline
        )]
        [string[]]
        $Path
    )

    process {
        foreach ($FolderPath in $Path) {
            if (-Not (Test-Path $FolderPath)) {
                Write-PSFMessage "[$FolderPath] does not exist"
                continue
            }

            Invoke-PSFProtectedCommand -Action 'Get items in folder' -Target $FolderPath -ScriptBlock {
                $FolderContents = Get-ChildItem $FolderPath -ErrorAction Stop
            } -Continue

            if ($FolderContents) {
                Write-PSFMessage "These $($FolderContents.count) items still exist in [$FolderPath]: ['$($FolderContents.Name -join "', '")']"
            } else {
                Invoke-PSFProtectedCommand -Action 'Deleting folder' -Target $FolderPath -ScriptBlock {
                    Remove-Item -LiteralPath $FolderPath -Recurse -Force -ErrorAction Stop
                }

                Remove-EmptyFolderRecursively -Path (Split-Path $FolderPath)
            }
        }
    }
}
