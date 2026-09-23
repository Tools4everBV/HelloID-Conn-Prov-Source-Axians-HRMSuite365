########################################################################
# HelloID-Conn-Prov-Source-Axians-HRMSuite365-Persons
#
# Version: 2.0.0
########################################################################

$config = $configuration | ConvertFrom-Json
$contractRetentionPeriod = (Get-Date).AddDays( - [int]$($config.HistoricalDays)).ToString('yyyy-MM-dd')
$contractFuturePeriod = (Get-Date).AddDays([int]$($config.FutureDays)).ToString('yyyy-MM-dd')
$today = (Get-Date).ToString('yyyy-MM-dd')

$translationPersonMapping = @{
    '1'        = 'Person_ExternalId_1'
    '2'        = 'Person_FirstName_2'
    '4'        = 'Person_PrefixAndLastName_4'
    '5'        = 'Person_Initials_5'
    '6'        = 'Person_FunctionName_6'
    '14'       = 'Person_Mobile_Private_14'
    '15'       = 'Person_Mail_Private_15'
    '26'       = 'Person_Manager_26'
    '50'       = 'Person_Mail_Work_50'
    '11020715' = 'Person_Convention_11020715'
    '11020721' = 'Person_LastName_11020721'
    '11020722' = 'Person_Prefix_11020722'
    '11020738' = 'Person_OR_11020738'
    '11020739' = 'Person_OR_Function_11020739'
    '11020740' = 'Person_OR_StartDate_11020740'
    '11020741' = 'Person_OR_EndDate_11020741'
    '11020767' = 'Person_Mobile_Work_11020767'
    '11020771' = 'Person_FullName_11020771'
}

$translationPartnerMapping = @{
    '1'        = 'Partner_ExternalId_1'
    '2'        = 'Partner_Id_2'
    '3'        = 'Partner_Type_3'
    '11020700' = 'Partner_PartnerBool_11020700'
    '11020721' = 'Partner_LastName_11020721'
    '11020722' = 'Partner_Prefix_11020722'
}

$translationEmploymentMapping = @{
    '1'  = 'Employment_ExternalId_1'
    '2'  = 'Employment_EmploymentNumber_2'
    '11' = 'Employment_Description_11'
    '12' = 'Employment_StartDate_12'
    '13' = 'Employment_EndDate_13'
    '32' = 'Employment_ContractType_32'
    '33' = 'Employment_Company_33'
}

$translationFormationMapping = @{
    '1'  = 'Formation_FunctionCode_1'
    '2'  = 'Formation_Sequence_2'
    '12' = 'Formation_ExternalId_12'
    '21' = 'Formation_StartDate_21'
    '22' = 'Formation_EndDate_22'
    '24' = 'Formation_FunctionName_24'
}

$translationPersonComponentMapping = @{
    '1'  = 'Component_Id_1'
    '2'  = 'Component_Company_2'
    '3'  = 'Component_ExternalId_3'
    '4'  = 'Component_EmploymentNumber_4'
    '7'  = 'Component_FieldName_7'
    '8'  = 'Component_StartDate_8'
    '9'  = 'Component_Sequence_9'
    '11' = 'Component_EndDate_11'
    '21' = 'Component_Value_21'
}

$translationEmploymentComponentMapping = @{
    '1'  = 'Component_Id_1'
    '2'  = 'Component_Company_2'
    '3'  = 'Component_ExternalId_3'
    '4'  = 'Component_EmploymentNumber_4'
    '7'  = 'Component_FieldName_7'
    '8'  = 'Component_StartDate_8'
    '9'  = 'Component_Sequence_9'
    '11' = 'Component_EndDate_11'
    '21' = 'Component_Value_21'
}

#region functions
function Resolve-Axians-HRMSuite365Error {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [object]
        $ErrorObject
    )
    process {
        $httpErrorObj = [PSCustomObject]@{
            ScriptLineNumber = $ErrorObject.InvocationInfo.ScriptLineNumber
            Line             = $ErrorObject.InvocationInfo.Line
            ErrorDetails     = $ErrorObject.Exception.Message
            FriendlyMessage  = $ErrorObject.Exception.Message
        }
        if (-not [string]::IsNullOrEmpty($ErrorObject.ErrorDetails.Message)) {
            $httpErrorObj.ErrorDetails = $ErrorObject.ErrorDetails.Message
        }
        elseif ($ErrorObject.Exception.GetType().FullName -eq 'System.Net.WebException') {
            if ($null -ne $ErrorObject.Exception.Response) {
                $streamReaderResponse = [System.IO.StreamReader]::new($ErrorObject.Exception.Response.GetResponseStream()).ReadToEnd()
                if (-not [string]::IsNullOrEmpty($streamReaderResponse)) {
                    $httpErrorObj.ErrorDetails = $streamReaderResponse
                }
            }
        }
        Write-Output $httpErrorObj
    }
}


function Invoke-MercashFuncGetPageData {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]
        $webPage,

        [Parameter()]
        [hashtable]
        $FieldTranslation = @{},

        [Parameter()]
        [string]
        $employeeNr = $null
    )
    try {
        $securePassword = ConvertTo-SecureString -String $config.Password -AsPlainText -Force
        $credential = [pscredential]::new($config.Username, $securePassword)
        $webPageXml = $webPage
        $employeeXml = $employeeNr

        $headers = @{
            SOAPAction = 'urn:microsoft-dynamics-schemas/codeunit/MercashWebserviceEXT:FuncGetPageData'
        }

        $soapBody = @"
<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <FuncGetPageData xmlns="urn:microsoft-dynamics-schemas/codeunit/MercashWebserviceEXT">
      <parMenu></parMenu>
      <parWebPage>$webPageXml</parWebPage>
      <parEmployeeNo>$employeeXml</parEmployeeNo>
      <parXMLData></parXMLData>
    </FuncGetPageData>
  </soap:Body>
</soap:Envelope>
"@
        $requestParameters = @{
            Uri         = $config.BaseUrl
            Method      = 'Post'
            Credential  = $credential
            Headers     = $headers
            ContentType = 'text/xml; charset=utf-8'
            Body        = $soapBody
        }
        # 
        [xml]$response = Invoke-RestMethod @requestParameters

        [xml]$responseObject = $response.Envelope.Body.FuncGetPageData_Result.parXMLData

        $records = @(
            $responseObject.SelectNodes("//*[local-name()='records']/*[local-name()='record']")
        )

        if ([string]::IsNullOrWhiteSpace($records)) {
            throw 'No response received from the web service'
        }

        $object = [system.Collections.Generic.List[Object]]::new()
        foreach ($record in $records) {
            $properties = [pscustomobject]@{}
            $fields = @($record.SelectNodes("./*[local-name()='fields']/*[local-name()='field']"))
            foreach ($field in $fields) {
                $originalFieldName = [string]$field.No
                $fieldValue = [string]$field.currentvalue

                if ($FieldTranslation.ContainsKey($originalFieldName)) {
                    $fieldName = $FieldTranslation[$originalFieldName]
                }
                else {
                    $fieldName = $originalFieldName
                    # Write-Warning "No translation found for field [$originalFieldName] [$webPage] [$employeeNr]." # Log unkown fields
                }

                $properties | Add-Member -MemberType NoteProperty -Name $fieldName -Value $fieldValue
            }
            $object.add($properties)
        }
        Write-Output $object
    }
    catch {
        $PSCmdlet.ThrowTerminatingError($_)    
    }
}
#endregion

try {
    $actionMessage = 'retrieving persons from Mercash'
    $splatParmGetEmployee = @{
        webPage          = 'EXT_WERK'
        FieldTranslation = $translationPersonMapping
        # employeeNr       = '1234' # Debug 1 person
    }

    $persons = Invoke-MercashFuncGetPageData @splatParmGetEmployee
    Write-Information "Persons retrieved: $($persons.Count)"

    
    $actionMessage = 'retrieving partners from Mercash'
    $splatParmGetPartners = @{
        webPage          = 'EXT_PART'
        FieldTranslation = $translationPartnerMapping
        # employeeNr       = '1234' # Debug 1 person
    }

    $partners = Invoke-MercashFuncGetPageData @splatParmGetPartners

    $partnersGrouped = $partners | Group-Object -Property Partner_ExternalId_1 -AsHashTable
    Write-Information "Partners retrieved: $($partners.Count)"
    # Clean memory
    $partners = $null


    $actionMessage = 'retrieving employments from Mercash'
    $splatParmGetEmployments = @{
        webPage          = 'EXT_DVB'
        FieldTranslation = $translationEmploymentMapping
        # employeeNr       = '1234' # Debug 1 person
    }

    $employmentsUnfiltered = Invoke-MercashFuncGetPageData @splatParmGetEmployments

    Write-Information "Employments retrieved: $($employmentsUnfiltered.Count)"
    $employmentsFiltered = $employmentsUnfiltered | Where-Object { $_.Employment_StartDate_12 -le $contractFuturePeriod -and ($null -eq $_.Employment_EndDate_13 -or $_.Employment_EndDate_13 -ge $contractRetentionPeriod) }
    Write-Information "Employments retrieved: $($employmentsFiltered.Count) (filtered by retention period future [$($config.FutureDays)] and historical [$($config.HistoricalDays)])"
    $employmentsFiltered | Add-Member -MemberType NoteProperty -Name "ContractExternalId" -Value $null -Force
    $employmentsFiltered | Add-Member -MemberType NoteProperty -Name "TypeCode" -Value '1' -Force
    $employmentsFiltered | Add-Member -MemberType NoteProperty -Name "TypeDescription" -Value 'Employment' -Force
    $employmentsGrouped = $employmentsFiltered | Group-Object -Property Employment_ExternalId_1 -AsHashTable
    # Clean memory
    $employmentsUnfiltered = $null
    $employmentsFiltered = $null


    $actionMessage = "retrieving formations from Mercash"
    $splatParmGetFormation = @{
        webPage          = 'EXT_FORM'
        FieldTranslation = $translationFormationMapping
        # employeeNr       = '0250'
    }      
        
    $formationsUnfiltered = Invoke-MercashFuncGetPageData @splatParmGetFormation
    
    Write-Information "Formations retrieved: $($formationsUnfiltered.Count)"
    $formationsFiltered = $formationsUnfiltered | Where-Object { $_.Formation_StartDate_21 -le $contractFuturePeriod -and ($null -eq $_.Formation_EndDate_22 -or $_.Formation_EndDate_22 -ge $contractRetentionPeriod) }
    $formationsFiltered | Add-Member -MemberType NoteProperty -Name "ContractExternalId" -Value $null -Force
    $formationsFiltered | Add-Member -MemberType NoteProperty -Name "TypeCode" -Value '2' -Force
    $formationsFiltered | Add-Member -MemberType NoteProperty -Name "TypeDescription" -Value 'Formation' -Force
    $formationsGrouped = $formationsFiltered | Group-Object -Property Formation_ExternalId_12 -AsHashTable
    Write-Information "Formations retrieved: $($formationsFiltered.Count) (filtered by retention period future [$($config.FutureDays)] and historical [$($config.HistoricalDays)])"
    # Clean memory
    $formationsUnfiltered = $null
    $formationsFiltered = $null


    $actionMessage = "enhancing and exporting person objects to HelloID"
    $persons | Add-Member -MemberType NoteProperty -Name "ExternalId" -Value $null -Force
    $persons | Add-Member -MemberType NoteProperty -Name "DisplayName" -Value $null -Force
    $persons | Add-Member -MemberType NoteProperty -Name "PartnerLastName" -Value '' -Force
    $persons | Add-Member -MemberType NoteProperty -Name "PartnerPrefix" -Value '' -Force
    $persons | Add-Member -MemberType NoteProperty -Name "Contracts" -Value $null -Force

    foreach ($person in $persons) {
        $actionMessage = "enhancing person object for person with ExternalId [$($person.Person_ExternalId_1)]"
        $person.ExternalId = $person.Person_ExternalId_1
        $person.DisplayName = $person.Person_FullName_11020771 + ' (' + $person.ExternalId + ')'
        $personPartner = $partnersGrouped[$person.ExternalId]

        if ($personPartner) {
            $latestPartner = $personPartner | Sort-Object -Property { [int]$_.Partner_Id_2 } -Descending | Select-Object -First 1
            if ($latestPartner.Partner_PartnerBool_11020700 -eq 'true') {
                $person.PartnerLastName = $latestPartner.Partner_LastName_11020721
                $person.PartnerPrefix = $latestPartner.Partner_Prefix_11020722
            }
        }

        $contractsList = [System.Collections.ArrayList]::new()
        $employments = $employmentsGrouped[$person.ExternalId]
        # Skip persons without employments
        if ($null -eq $employments) {
            $countSkippedPersons++
            continue
        }

        $employments | Add-Member -MemberType NoteProperty -Name "Person_Manager" -Value $person.Person_Manager_26 -Force

        $actionMessage = "retrieving person components for person with ExternalId [$($person.ExternalId)]"
        $splatParmGetComponentW = @{
            webPage          = 'EXT_COMP_W'
            FieldTranslation = $translationPersonComponentMapping
            employeeNr       = $person.ExternalId
        }

        $personComponents = Invoke-MercashFuncGetPageData @splatParmGetComponentW
        $personComponents = $personComponents | Where-Object { $_.Component_Value_21 -ne $null }

        if ($null -ne $personComponents) {
            $groupedComponents = $personComponents | Group-Object -Property Component_FieldName_7

            foreach ($component in $groupedComponents) {
                $latestComponent = $component.Group | Where-Object { $_.Component_StartDate_8 -le $today } | Sort-Object Component_StartDate_8 -Descending | Select-Object -First 1

                # If no active component is found, take one in the future
                if ($null -eq $latestComponent) {
                    $latestComponent = $component.Group | Sort-Object Component_StartDate_8 | Select-Object -First 1
                }

                $person | Add-Member -MemberType NoteProperty -Name "Component_$($component.Name)_StartDate" -Value $latestComponent.Component_StartDate_8 -Force
                $person | Add-Member -MemberType NoteProperty -Name "Component_$($component.Name)" -Value $latestComponent.Component_Value_21 -Force
            }
        }

        $actionMessage = "retrieving employment components for person with ExternalId [$($person.ExternalId)]"
        $splatParmGetComponents = @{
            webPage          = 'EXT_COMP'
            FieldTranslation = $translationEmploymentComponentMapping
            employeeNr       = $person.ExternalId
        }      
        
        $employmentsComponents = Invoke-MercashFuncGetPageData @splatParmGetComponents
        $employmentsComponents = $employmentsComponents | Where-Object { $_.Component_Value_21 -ne $null }

        $actionMessage = "enhancing employments for person with ExternalId [$($person.ExternalId)]"
        foreach ($employment in $employments) {
            $employment.ContractExternalId = $employment.Employment_EmploymentNumber_2
            $employmentComponents = $employmentsComponents | Where-Object { $_.Component_EmploymentNumber_4 -eq $employment.Employment_EmploymentNumber_2 }
            $groupedComponents = $employmentComponents | Group-Object -Property Component_FieldName_7

            foreach ($component in $groupedComponents) {
                $latestComponent = $component.Group | Where-Object { $_.Component_StartDate_8 -le $today } | Sort-Object Component_StartDate_8 -Descending | Select-Object -First 1

                # If no active component is found, take one in the future
                if ($null -eq $latestComponent) {
                    $latestComponent = $component.Group | Sort-Object Component_StartDate_8 | Select-Object -First 1
                }

                if (($component.Name -eq 'HM_UREN_MIN') -and ($null -ne $latestComponent)) {
                    $latestComponent.Component_Value_21 = $latestComponent.Component_Value_21.Replace(',', '.')
                }
                
                $employment | Add-Member -MemberType NoteProperty -Name "Component_$($component.Name)_StartDate" -Value $latestComponent.Component_StartDate_8 -Force
                $employment | Add-Member -MemberType NoteProperty -Name "Component_$($component.Name)" -Value $latestComponent.Component_Value_21 -Force
            }

            [void]$contractsList.Add($employment)
        }

        $actionMessage = "retrieving formations for person with ExternalId [$($person.ExternalId)]"
        $formations = $formationsGrouped[$person.ExternalId]
        foreach ($formation in $formations) {
            $formation.ContractExternalId = $formation.Formation_ExternalId_12 + '-' + $formation.Formation_FunctionCode_1.replace(' ', '') + '-' + $formation.Formation_Sequence_2
            [void]$contractsList.Add($formation)
        }

        $person.Contracts = $contractsList
        Write-Output $person | ConvertTo-Json -Depth 10
        $exportedPersons++
    }

    write-Information "Persons retrieved: $exportedPersons"
    Write-Information "Persons skipped: $countSkippedPersons (because no employments found)"
}
catch {
    $ex = $PSItem
    if ($($ex.Exception.GetType().FullName -eq 'Microsoft.PowerShell.Commands.HttpResponseException') -or
        $($ex.Exception.GetType().FullName -eq 'System.Net.WebException')) {
        $errorObj = Resolve-Axians-HRMSuite365Error -ErrorObject $ex
        Write-Warning "Error at Line '$($errorObj.ScriptLineNumber)': $($errorObj.Line). Error: $($errorObj.ErrorDetails)"
        Write-Error "Error $($actionMessage). Error: $($errorObj.FriendlyMessage)"
    }
    else {
        Write-Warning "Error at Line '$($ex.InvocationInfo.ScriptLineNumber)': $($ex.InvocationInfo.Line). Error: $($ex.Exception.Message)"
        Write-Error "Error $($actionMessage). Error: $($ex.Exception.Message)"
    }
}