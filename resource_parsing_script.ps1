<#
.SYNOPSIS
    Generate a tree view of FiveM resources in depth 1 and display their status based on the server configuration file.
.DESCRIPTION
    This script retrieves a list of folder and subfolders in the FiveM resources folder and generates a tree view of resources in depth 1. It also displays the status of each resource based on the server configuration file.
.NOTES
    Author: Ryszard Kaczmarek
    Date: $(Get-Date)
    Version: 1.0
#>



#region variables
# Définition des variables
$serverconfig = "D:\Adrenaline\Serveurs\Officiel\server-data\server.cfg"
$resource_folder = "D:\Adrenaline\Serveurs\Officiel\server-data\resources\"
#endregion

# Récupération des lignes du fichier de configuration contenant le mot-clé "ensure"
$lines = get-content -Path $serverconfig | ? {$_ -like "*ensure*"}

# Création d'un objet personnalisé contenant le statut et le nom pour chaque plugin trouvé dans le fichier de configuration
$objects = foreach ($line in $lines) {
    $status = if ($line.StartsWith("#ensure")) {"off"} else {"on"}
    $name = $line.Split(" ")[1]
    [pscustomobject]@{
        Status = $status
        Name = $name
    }
}

# Récupération des sous-dossiers dans le dossier de ressources FiveM
$subfolders = Get-ChildItem -LiteralPath $resource_folder -Directory

# Création d'un hashtable pour regrouper les sous-dossiers en fonction de leur index
$hashTable = @{}
foreach ($folder in $subfolders) {
    $group = [regex]::Match($folder.Name, '^\[\s*(\d+)\.').Groups[1].Value
    if ([string]::IsNullOrEmpty($group)) { continue }
    if ($hashTable.ContainsKey($group)) {
        $hashTable[$group] += @($folder.FullName)
    } else {
        $hashTable[$group] = @($folder.FullName)
    }
}

# Création d'un objet personnalisé pour chaque sous-dossier contenant une ressource FiveM
$ht = foreach ($key in $hashTable.Keys) {
    foreach ($folder in $hashTable[$key]) {
        Get-ChildItem -LiteralPath $folder -Directory | ForEach-Object {

            # Récupération du nom du plugin à partir du chemin complet du sous-dossier
            $pluginName = $_.FullName.Split('\')[-1]

            # Récupération du statut correspondant au nom du plugin à partir de la liste des objets personnalisés créés précédemment
            $status = $objects | Where-Object {$_.Name -eq $pluginName} | Select-Object -ExpandProperty Status

            # Affichage d'un message de débogage si le statut correspondant au plugin n'a pas été trouvé dans la liste
            if ([string]::IsNullOrEmpty($status)) {
                Write-Debug "No status found for plugin '$pluginName'"
            }

            # Génération d'un objet personnalisé contenant l'index, le chemin complet de la ressource, le nom du plugin et son statut
            [PSCustomObject]@{
                Index = $key
                Resource = $_.FullName
                Plugin = $pluginName
                Status = $status
            }
        }
    }
}

# Tri des objets personnalisés en fonction de l'index
$htSorted = $ht | Sort-Object -Property @{Expression={[int]$_.Index}}

# Affichage du résultat final
$htSorted | ogv

