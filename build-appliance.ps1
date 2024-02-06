# Copyright 2022 Carnegie Mellon University.
# Released under a BSD (SEI)-style license, please see LICENSE.md in the
# project root or contact permission@sei.cmu.edu for full terms.


# Initialize variables
$onlyVar = ""
$packerArgs = @()

# Check if the first argument is used for onlyVar
if ($args.Count -gt 0 -and $args[0] -notlike "-*") {
    $targets = $args[0] -split ","
    foreach ($i in $targets) {
        $onlyVar += "$i*,"
    }
    $onlyVar = $onlyVar.TrimEnd(',')

    # If there's more than one argument, rebuild packerArgs to exclude the first
    # Otherwise, if there's only one argument used for onlyVar, leave packerArgs empty
    if ($args.Count -gt 1) {
        $packerArgs = $args[1..($args.Length - 1)]
    }
} else {
    # If the first argument isn't processed for onlyVar, include all arguments
    $packerArgs = $args
}

# Git repository check and variable assignments
$versionTag = $gitBranch = $gitHash = $null
if (git rev-parse --git-dir > $null 2>&1) {
    $versionTag = git tag --points-at HEAD
    $gitBranch = git branch --show-current
    $gitHash = git rev-parse --short HEAD
}

$buildVersion = "custom-" + (Get-Date -Format "yyyyMMdd") # Default build version
if ($versionTag) {
    $buildVersion = $versionTag
} elseif ($env:GITHUB_PULL_REQUEST) {
    $buildVersion = "PR$env:GITHUB_PULL_REQUEST-$gitHash"
} elseif ($gitHash) {
    $buildVersion = "$gitBranch-$gitHash"
}

# Packer command execution
if ($onlyVar) {
    & packer build -only="$onlyVar" -var "appliance_version=$buildVersion" @packerArgs .
} else {
    & packer build -var "appliance_version=$buildVersion" @packerArgs .
}
