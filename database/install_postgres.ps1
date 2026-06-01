# -------------------------------------------
# PostgreSQL + pgAdmin Silent Installer Script for Windows
# -------------------------------------------
# PostgreSQL Settings
$pgVersion = "16.2"
$pgInstallerUrl = "https://get.enterprisedb.com/postgresql/postgresql-$pgVersion-1-windows-x64.exe"
$pgInstallerPath = "$env:TEMP\postgresql_installer.exe"
$installDir = "C:\PostgreSQL\$pgVersion"
$dataDir = "$installDir\data"
$pgPassword = "postgres123"
$pgPort = 5432

# Download and install PostgreSQL
Write-Host "Downloading PostgreSQL $pgVersion installer..."
Invoke-WebRequest -Uri $pgInstallerUrl -OutFile $pgInstallerPath

Write-Host "Installing PostgreSQL silently..."
Start-Process -Wait -FilePath $pgInstallerPath -ArgumentList `
    "--mode", "unattended", `
    "--superpassword", "$pgPassword", `
    "--prefix", "`"$installDir`"", `
    "--datadir", "`"$dataDir`"", `
    "--serverport", "$pgPort", `
    "--servicename", "postgresql-$pgVersion"

Remove-Item $pgInstallerPath
Write-Host "PostgreSQL installed at $installDir"
Write-Host ("Connect with username: postgres | password: " + $pgPassword)


# pgAdmin 4 Installer Script (Stable v9.6)

$pgAdminVersion = "9.6"
$pgAdminUrl = "https://ftp.postgresql.org/pub/pgadmin/pgadmin4/v$pgAdminVersion/windows/pgadmin4-$pgAdminVersion-x64.exe"
$pgAdminPath = "$env:TEMP\pgadmin_installer.exe"

Write-Host "Downloading pgAdmin 4 v$pgAdminVersion..."
Invoke-WebRequest -Uri $pgAdminUrl -OutFile $pgAdminPath

Write-Host "Installing pgAdmin 4..."
Start-Process -Wait -FilePath $pgAdminPath -ArgumentList "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART"

Remove-Item $pgAdminPath
Write-Host "pgAdmin 4 v$pgAdminVersion installation complete. Launch from Start Menu."



