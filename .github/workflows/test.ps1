$githubRepository = "aaroncorreya/GitHub-Api-test"
$branchName = "script"
$githubAuthToken = "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"
$newResourceBranch = "$branchName-sentinel-deployment"

$header = @{
    "authorization" = "Bearer $githubAuthToken"
}

#Gets all files and commit shas using Get Trees API 
function GetGithubTree {
    Param(
        [string]$branch
    )
    $branchResponse = AttemptInvokeRestMethod "Get" "https://api.github.com/repos/$githubRepository/branches/$branch" $null $null 3
    $treeUrl = "https://api.github.com/repos/$githubRepository/git/trees/" + $branchResponse.commit.sha + "?recursive=true"
    $getTreeResponse = AttemptInvokeRestMethod "Get" $treeUrl $null $null 3
    return $getTreeResponse
}

#Creates new branch using the GitHub API with the name of the branchName + "-sentinel-deployment"
#TODO: Find a point to check if branch already exists, if so then read the csv file from that branch
function TryCreateBranch {
    $getBranchResponse = AttemptInvokeRestMethod "Get" "https://api.github.com/repos/$githubRepository/branches/$branchName" $null $null 3
    $createBranchUrl = "https://api.github.com/repos/$githubRepository/git/refs"
    
    $body = @{
        ref = "refs/heads/$newResourceBranch"
        sha = $getBranchResponse.commit.sha
    } | ConvertTo-Json

    try {
        $response = AttemptInvokeRestMethod "Post" $createBranchUrl $body $null 3
        Write-Host $response
    } catch {
        Write-Host "StatusCode:" $_.Exception.Response.StatusCode.value__ 
    }
        
}

function GetFile {
    Param(
        [string]$path,
        [string]$branch
    )
    $url = "https://api.github.com/repos/$githubRepository/contents/$path?ref=$branch"
    $response = AttemptInvokeRestMethod "Get" $url $null $null 3
    return $response
}


function AttemptInvokeRestMethod($method, $url, $body, $contentTypes, $maxRetries) {
    $Stoploop = $false
    $retryCount = 0
    do {
        try {
            $result = Invoke-RestMethod -Uri $url -Method $method -Headers $header -Body $body -ContentType $contentTypes
            $Stoploop = $true
        }
        catch {
            if ($retryCount -gt $maxRetries) {
                Write-Host "[Error] API call failed after $retryCount retries: $_"
                $Stoploop = $true
            }
            else {
                Write-Host "[Warning] API call failed: $_.`n Conducting retry #$retryCount."
                Start-Sleep -Seconds 5
                $retryCount = $retryCount + 1
            }
        }
    }
    While ($Stoploop -eq $false)
    return $result
}

function main() {
    TryCreateBranch
}

main