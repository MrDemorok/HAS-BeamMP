$ErrorActionPreference = "Stop"

$repository = "MrDemorok/HAS-BeamMP"
$serverRootInput = Read-Host "Enter the BeamMP server directory or the path to BeamMP-Server.exe"
$serverPath = [System.IO.Path]::GetFullPath($serverRootInput.Trim('"'))
$serverRoot = $serverPath
if (Test-Path -LiteralPath $serverPath -PathType Leaf) {
	$serverRoot = Split-Path -Parent $serverPath
}
$resourcesPath = Join-Path $serverRoot "Resources"

if (-not (Test-Path -LiteralPath $serverRoot -PathType Container)) {
	throw "Server directory not found: $serverRoot"
}
if (-not (Test-Path -LiteralPath $resourcesPath -PathType Container)) {
	throw "Resources directory not found: $resourcesPath"
}

$serverResources = Join-Path $resourcesPath "Server"
$clientResources = Join-Path $resourcesPath "Client"
New-Item -ItemType Directory -Path $serverResources, $clientResources -Force | Out-Null

$workingDirectory = Join-Path ([System.IO.Path]::GetTempPath()) ("HAS-install-" + [Guid]::NewGuid().ToString("N"))
$archivePath = Join-Path $workingDirectory "HAS-BeamMP.zip"
$extractPath = Join-Path $workingDirectory "extracted"
$clientZipPath = Join-Path $clientResources "HAS.zip"
$temporaryClientZipPath = Join-Path $clientResources ("HAS-" + [Guid]::NewGuid().ToString("N") + ".zip")

try {
	New-Item -ItemType Directory -Path $workingDirectory, $extractPath -Force | Out-Null
	[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
	$repositoryArchive = "https://github.com/$repository/archive/refs/heads/main.zip"
	Invoke-WebRequest -Uri $repositoryArchive -OutFile $archivePath -UseBasicParsing
	Expand-Archive -LiteralPath $archivePath -DestinationPath $extractPath -Force

	$repositoryRoot = Get-ChildItem -LiteralPath $extractPath -Directory -Recurse |
		Where-Object {
			(Test-Path -LiteralPath (Join-Path $_.FullName "Server\HAS") -PathType Container) -and
			(Test-Path -LiteralPath (Join-Path $_.FullName "Client") -PathType Container)
		} |
		Select-Object -First 1

	if (-not $repositoryRoot) {
		throw "The downloaded archive does not contain the expected Server\HAS and Client directories."
	}

	$sourceServer = Join-Path $repositoryRoot.FullName "Server\HAS"
	$sourceClient = Join-Path $repositoryRoot.FullName "Client"
	$destinationServer = Join-Path $serverResources "HAS"

	New-Item -ItemType Directory -Path $destinationServer -Force | Out-Null
	Get-ChildItem -LiteralPath $sourceServer | Copy-Item -Destination $destinationServer -Recurse -Force

	Add-Type -AssemblyName System.IO.Compression
	Add-Type -AssemblyName System.IO.Compression.FileSystem
	$clientArchive = [System.IO.Compression.ZipFile]::Open(
		$temporaryClientZipPath,
		[System.IO.Compression.ZipArchiveMode]::Create
	)
	try {
		Get-ChildItem -LiteralPath $sourceClient -File -Recurse | ForEach-Object {
			$entryName = $_.FullName.Substring($sourceClient.Length).TrimStart('\').Replace('\', '/')
			[System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
				$clientArchive,
				$_.FullName,
				$entryName,
				[System.IO.Compression.CompressionLevel]::Optimal
			) | Out-Null
		}
	}
	finally {
		$clientArchive.Dispose()
	}
	Move-Item -LiteralPath $temporaryClientZipPath -Destination $clientZipPath -Force

	Write-Host "HAS was installed:"
	Write-Host "  Server: $destinationServer"
	Write-Host "  Client: $clientZipPath"
}
finally {
	if (Test-Path -LiteralPath $temporaryClientZipPath) {
		Remove-Item -LiteralPath $temporaryClientZipPath -Force
	}
	if (Test-Path -LiteralPath $workingDirectory) {
		Remove-Item -LiteralPath $workingDirectory -Recurse -Force
	}
}
