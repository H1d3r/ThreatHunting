FUNCTION Hunt-Hotfixes {
<#
.Synopsis 
    Gets the hotfixes applied to a given system.

.Description 
    Gets the hotfixes applied to a given system. Get-Hotfix returns only OS-level hotfixes, this one grabs em all.

.Parameter Computer  
    Computer can be a single hostname, FQDN, or IP address.

.Example 
    Hunt-Hotfixes 
    Hunt-Hotfixes SomeHostName.domain.com
    Get-Content C:\hosts.csv | Hunt-Hotfixes
    Hunt-Hotfixes $env:computername
    Get-ADComputer -filter * | Select -ExpandProperty Name | Hunt-Hotfixes

.Notes 
    Updated: 2017-10-10

    Contributing Authors:
        Anthony Phipps
        
    LEGAL: Copyright (C) 2017
    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.
    
    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#>

    PARAM(
    	[Parameter(ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
        $Computer
    );

	BEGIN{

        $datetime = Get-Date -Format "yyyy-MM-dd_hh.mm.ss.ff";
        Write-Verbose "Started at $datetime"

        $stopwatch = New-Object System.Diagnostics.Stopwatch;
        $stopwatch.Start();

        $total = 0;
	}

    PROCESS{

        $output = [PSCustomObject]@{
            Name = $Computer
            PSComputerName = ""
            Operation = ""
            ResultCode = ""
            HResult = ""
            Date = ""
            Title = ""
            Description = ""
            UnmappedResultCode = ""
            ClientApplicationID = ""
            ServerSelection = ""
            ServiceID = ""
            UninstallationNotes = ""
            SupportUrl = ""
        };

        $Hotfixes = invoke-command -Computer $Computer -scriptblock {

            $Session = New-Object -ComObject "Microsoft.Update.Session";
            $Searcher = $Session.CreateUpdateSearcher();
            $historyCount = $Searcher.GetTotalHistoryCount();
            $Searcher.QueryHistory(0, $historyCount) | Select-Object PSComputerName, Operation, ResultCode, HResult, Date, Title, Description, UnmappedResultCode, ClientApplicationID, ServerSelection, ServiceID, UninstallationNotes, SupportUrl | Where-Object Title -ne $null;
        };

        if ($Hotfixes){
            
            $Hotfixes | ForEach-Object {

                $output.PSComputerName = $_.PSComputerName;
                $output.Operation = $_.Operation;
                $output.ResultCode = $_.ResultCode;
                $output.HResult = $_.HResult;
                $output.Date = $_.Date;
                $output.Title = $_.Title;
                $output.Description = $_.Description;
                $output.UnmappedResultCode = $_.UnmappedResultCode;
                $output.ClientApplicationID = $_.ClientApplicationID;
                $output.ServerSelection = $_.ServerSelection;
                $output.ServiceID = $_.ServiceID;
                $output.UninstallationNotes = $_.UninstallationNotes;
                $output.SupportUrl = $_.SupportUrl;

                $output.PsObject.Members | ForEach-Object {$output.PsObject.Members.Remove($_.Name)};
                return $output;
            };
        }
        else {
            
            Write-Verbose ("{0}: System failed." -f $Computer);
            if ($Fails) {
                
                $total++;
                Add-Content -Path $Fails -Value ("$Computer");
            }
            else {
                
                $output = $null;
                $output = [ArpCache]::new();

                $output.Computer = $Computer;
                $output.DateScanned = Get-Date -Format u;
                
                $total++;
                return $output;
            };
        };
    };

    end {

        $elapsed = $stopwatch.Elapsed;

        Write-Verbose ("Total Systems: {0} `t Total time elapsed: {1}" -f $total, $elapsed);
    };
};