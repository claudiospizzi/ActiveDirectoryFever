
function New-ADChangeObject
{
    param
    (
        [Parameter(Mandatory=$true)]
        [DateTime] $Timestamp,

        [Parameter(Mandatory=$true)]
        [AllowEmptyString()]
        [String] $ObjectClass,

        [Parameter(Mandatory=$true)]
        [Guid] $ObjectGuid,

        [Parameter(Mandatory=$true)]
        [System.Security.Principal.SecurityIdentifier] $ObjectSid,

        [Parameter(Mandatory=$true)]
        [String] $Identity,

        [Parameter(Mandatory=$true)]
        [String] $Account,

        [Parameter(Mandatory=$true)]
        [ValidateSet("CREATE", "DELETE", "RESTORE", "MOVE", "MODIFY", "MEMBER-ADD", "MEMBER-REMOVE", "MEMBEROF-ADD", "MEMBEROF-REMOVE", "CUSTOM-ADD", "CUSTOM-REMOVE", "UNKNOWN")]
        [String] $Action,

        [Parameter(Mandatory=$true)]
        [String] $Field,

        [Parameter(Mandatory=$true)]
        [AllowEmptyCollection()]
        [AllowEmptyString()]
        [AllowNull()]
        [Object] $Value
    )

    process
    {
        # Create an output object
        $Object = New-Object -TypeName PSObject -Property @{
            Timestamp   = $Timestamp
            ObjectClass = $(try { $ObjectClass.Substring(3).Split(",")[0] } catch { $ObjectClass })
            ObjectGuid  = [String] $ObjectGuid
            ObjectSid   = [String] $ObjectSid
            Identity    = $Identity
            Account     = $Account
            Action      = $Action
            Field       = $Field
            Value       = @()
        }

        # Check if the value has content
        if ($Value -is [System.DirectoryServices.ResultPropertyValueCollection])
        {
            foreach ($Entry in $Value)
            {
                if ($Entry -is [System.Byte[]] -and $Field -eq "objectsid")
                {
                    # Security Identifier Field
                    $Object.Value += [String] (New-Object -TypeName System.Security.Principal.SecurityIdentifier -ArgumentList ($Entry, 0))
                }
                elseif ($Entry -is [System.Byte[]] -and $Field -eq "ntsecuritydescriptor")
                {
                    # Security Descriptor Field
                    $SecurityDescriptor = New-Object -TypeName System.DirectoryServices.ActiveDirectorySecurity
                    $SecurityDescriptor.SetSecurityDescriptorBinaryForm($Entry)
                    $Object.Value += $SecurityDescriptor
                }
                else
                {
                    # Other Collection
                    $Object.Value += $Entry
                }
            }
        }
        else
        {
            # Simple Object (String, Integer)
            $Object.Value += $Value
        }

        $Object.PSTypeNames.Insert(0, "ActiveDirectoryFever.GetADUpdate.Result")

        Write-Output $Object
    }
}
