#Requires -Modules PSFramework

function Invoke-PlatyPSMarkdownFix {
    param (
        [Alias('FullName')]
        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [ValidateScript({
            (Test-Path $_) -and ((Split-Path $_ -Extension) -eq '.md')
        })]
        [string[]]
        $Path,

        [Parameter(
            Mandatory,
            ParameterSetName = 'Objects'
        )]
        [PSCustomObject[]]
        $ReplacePatterns,

        [Parameter(
            Mandatory,
            ParameterSetName = 'CSV'
        )]
        [ValidateScript({ Test-Path $_ })]
        [string]
        $RegExDefinitionsPath,

        [string[]]
        $RegExFlag = @('m')
    )
    begin {
        if (-Not $ReplacePatterns) {
            Invoke-PSFProtectedCommand -Action 'Import RegEx Definitions' -Target $RegExDefinitionsPath -ScriptBlock {
                $ReplacePatterns = Import-Csv $RegExDefinitionsPath -ErrorAction Stop
            }

            $ReplacePatterns |
                Where-Object ReplacePattern -Match '\\[rn]' |
                    ForEach-Object {
                        $NewPattern = $_.ReplacePattern
                        switch -Regex ($NewPattern) {
                            '\\r' { $NewPattern = $NewPattern -replace '\\r', "`r"}
                            '\\n' { $NewPattern = $NewPattern -replace '\\n', "`n"}
                        }
                        $_.ReplacePattern = $NewPattern
                    }
        }
        # This copy is needed because a PSCustomObject that comes from a parameter is actually an object REFERENCE, see:
        # https://stackoverflow.com/questions/60102320/powershell-function-parameters-by-reference-or-by-value/60102611#60102611
        $UpdatedPatterns = $ReplacePatterns | ForEach-Object { $_.PSObject.Copy() }
        foreach ($Replace in $UpdatedPatterns) {
            if ($RegExFlag) {
                $Replace.Find = "(?$($RegExFlag -join ''))" + $Replace.Find
            }
        }
    }
    process {
        if (Test-PSFFunctionInterrupt) { return }

        foreach ($FilePath in $Path) {
            Invoke-PSFProtectedCommand -Action 'Read file' -Target $FilePath -ScriptBlock {
                $Content = Get-Content -Path $FilePath -Raw -ErrorAction Stop
            } -Continue

            foreach ($Replace in $UpdatedPatterns) {
                Write-PSFMessage -Message "Replacing [$($Replace.Find)] with [$($Replace.ReplacePattern)] to [$($Replace.Description)]" -Target $Content
                $Content = $Content -replace $Replace.Find, $Replace.ReplacePattern
            }

            Invoke-PSFProtectedCommand -Action 'Write out modified file' -Target $FilePath -ScriptBlock {
                $Content | Set-Content -Path $FilePath -NoNewLine -Force -ErrorAction Stop
            }
        }
    }
}
