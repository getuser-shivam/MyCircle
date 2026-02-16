$installer = 'C:\Program Files (x86)\Microsoft Visual Studio\Installer\vs_installer.exe'
$instanceId = 'ee393365'
$components = @(
    'Microsoft.VisualStudio.Workload.NativeDesktop',
    'Microsoft.VisualStudio.Component.VC.v142.x86.x64',
    'Microsoft.VisualStudio.Component.Windows10SDK.19041',
    'Microsoft.VisualStudio.Component.VC.CMake.Project'
)
$args = @('modify', '--instanceId', $instanceId, '--includeRecommended', '--passive', '--norestart')
foreach ($c in $components) { 
    $args += '--add'
    $args += $c 
}
Write-Host "Starting VS Installer for instance $instanceId with components: $($components -join ', ')"
Start-Process -FilePath $installer -ArgumentList $args -Verb RunAs -Wait
Write-Host "Installer finished."
