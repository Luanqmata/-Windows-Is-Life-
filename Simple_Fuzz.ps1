# script_fuzzing_teste.ps1

# Função ScanHTML (modificada para sempre retornar as palavras)
function ScanHTML {
    param ([string]$url)
    
    try {
        Write-Host "`n[SCAN HTML] Obtendo palavras do codigo fonte..." -ForegroundColor Yellow
        
        # Simula um delay de processamento
        Start-Sleep -Seconds 2

        # Faz a requisicao para obter o HTML
        $response = Invoke-WebRequest -Uri $url
        $htmlContent = $response.Content

        Write-Host "[SCAN HTML] HTML obtido com sucesso! Processando conteudo..." -ForegroundColor Green

        # Extrai palavras do HTML
        $palavras = ($htmlContent -split '[^\p{L}0-9_\-]+') |
                    Where-Object { 
                        $_.Length -gt 2 -and 
                        -not $_.StartsWith('#') -and 
                        -not $_.StartsWith('//') -and
                        -not $_.StartsWith('/*') -and
                        -not $_.EndsWith('*/')
                    } |
                    Select-Object -Unique |
                    Sort-Object

        # Remove palavras comuns
        $commonWords = @('the', 'and', 'for', 'are', 'but', 'not', 'you', 'all', 'can', 'your', 'has', 'had', 'how', 'was', 'why', 'who', 'its')
        $palavras = $palavras | Where-Object { $commonWords -notcontains $_.ToLower() }

        Write-Host "[SCAN HTML] Total de palavras unicas encontradas: $($palavras.Count)" -ForegroundColor Cyan
        
        if ($palavras.Count -gt 0) {
            Write-Host "`n[SCAN HTML] Exemplo das primeiras 10 palavras:" -ForegroundColor Yellow
            $palavras | Select-Object -First 10 | ForEach-Object {
                Write-Host "   -> $_" -ForegroundColor White
            }

            # Pergunta se quer salvar as palavras
            Write-Host "`n[SCAN HTML] Deseja salvar as palavras em um arquivo para fuzzing?" -ForegroundColor Yellow
            $save = Read-Host "   (S) Sim / (N) Nao [Padrao: N]"
            
            $savedFilePath = $null

            if ($save -eq 'S' -or $save -eq 's' -or $save -eq 'Sim' -or $save -eq 'sim') {
                $fuzzingDir = "Fuzz_files"
                if (-not (Test-Path $fuzzingDir)) {
                    New-Item -ItemType Directory -Path $fuzzingDir -Force | Out-Null
                    Write-Host "`n[SCAN HTML] Diretorio criado: $fuzzingDir" -ForegroundColor Green
                }

                $defaultName = "wordlist_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
                $filePath = Read-Host "`n   Nome do arquivo [Padrao: $defaultName]"
                
                if ([string]::IsNullOrWhiteSpace($filePath)) {
                    $filePath = $defaultName
                }
                
                # Garante que tem extensao .txt
                if (-not $filePath.EndsWith('.txt')) {
                    $filePath += '.txt'
                }
                
                $fullPath = Join-Path $fuzzingDir $filePath
                $palavras | Out-File -FilePath $fullPath -Encoding UTF8
                
                Write-Host "`n[SCAN HTML] OK Palavras salvas em: $fullPath" -ForegroundColor Green
                Write-Host "[SCAN HTML] Caminho completo: $((Get-Item $fullPath).FullName)" -ForegroundColor Gray
                
                $savedFilePath = $fullPath
            } else {
                Write-Host "`n[SCAN HTML] Palavras nao salvas (serao usadas apenas na memoria)" -ForegroundColor Yellow
            }
            
            # Retorna tanto as palavras quanto o caminho do arquivo (se salvou)
            return @{
                Words = $palavras
                SavedFilePath = $savedFilePath
                TotalWords = $palavras.Count
            }
            
        } else {
            Write-Host "[SCAN HTML] X Nenhuma palavra relevante encontrada no HTML." -ForegroundColor Red
            return @{
                Words = @()
                SavedFilePath = $null
                TotalWords = 0
            }
        }

    } catch {
        Write-Host "[SCAN HTML] X Erro ao processar HTML: $($_.Exception.Message)" -ForegroundColor Red
        return @{
            Words = @()
            SavedFilePath = $null
            TotalWords = 0
        }
    }
}

function Start-Fuzzing {
    param(
        [string]$url,
        [string]$wordlist,
        [int]$delay = 100
    )
    
    try {
        Write-Host "`n[FUZZING] Iniciando varredura..." -ForegroundColor Yellow
        
        $wordsToUse = @()
        $usingFile = $false

        # Verifica se vai usar arquivo ou palavras da memoria
        if ($wordlist -and (Test-Path $wordlist)) {
            Write-Host "[FUZZING] Usando wordlist do arquivo: $wordlist" -ForegroundColor Cyan
            $wordsToUse = Get-Content $wordlist
            $usingFile = $true
        } else {
            Write-Host "[FUZZING] X Arquivo de wordlist nao encontrado: $wordlist" -ForegroundColor Red
            return
        }
        
        $totalWords = $wordsToUse.Count
        
        if ($totalWords -eq 0) {
            Write-Host "[FUZZING] X Nenhuma palavra disponivel para fuzzing." -ForegroundColor Red
            return
        }

        Write-Host "[FUZZING] Alvo: $url" -ForegroundColor White
        Write-Host "[FUZZING] Total de palavras: $totalWords" -ForegroundColor White
        Write-Host "[FUZZING] Delay entre requisicoes: ${delay}ms" -ForegroundColor White
        Write-Host "[FUZZING] Iniciando...`n" -ForegroundColor Green
        
        $results = @()
        $counter = 0

        foreach ($word in $wordsToUse) {
            $counter++
            $percentComplete = [math]::Round(($counter / $totalWords) * 100, 2)
            
            # Barra de progresso
            Write-Progress -Activity "Fuzzing em andamento" `
                         -Status "Testando: $word ($counter/$totalWords - $percentComplete%)" `
                         -PercentComplete $percentComplete `
                         -CurrentOperation "Alvo: $($url.Split('/')[2])"
            
            # Constrói a URL para teste
            $testUrl = "$url/$word"
            
            try {
                # Faz requisicao HEAD (mais rapida)
                $response = Invoke-WebRequest -Uri $testUrl -Method Head -TimeoutSec 5 -ErrorAction Stop
                
                $statusCode = $response.StatusCode
                $contentLength = $response.Headers['Content-Length']
                
                # Filtra respostas interessantes (nao 404)
                if ($statusCode -ne 404) {
                    $result = [PSCustomObject]@{
                        URL = $testUrl
                        StatusCode = $statusCode
                        ContentLength = $contentLength
                        Word = $word
                    }
                    
                    $results += $result
                    
                    # Mostra resultados com cores
                    $color = switch ($statusCode) {
                        { $_ -ge 200 -and $_ -lt 300 } { "Green"; break }
                        { $_ -ge 300 -and $_ -lt 400 } { "Yellow"; break }
                        { $_ -ge 400 -and $_ -lt 500 } { "Red"; break }
                        { $_ -ge 500 } { "DarkRed"; break }
                        default { "White" }
                    }
                    
                    Write-Host "  [$statusCode] $testUrl" -ForegroundColor $color
                }
                
            } catch {
                # Ignora erros 404 (paginas nao encontradas)
                # Pode adicionar logging de outros erros se quiser
            }
            
            # Delay para nao sobrecarregar o servidor
            if ($delay -gt 0) {
                Start-Sleep -Milliseconds $delay
            }
        }
        
        Write-Progress -Activity "Fuzzing" -Completed
        
        # Resumo final
        Write-Host "`n[FUZZING] OK Varredura concluida!" -ForegroundColor Green
        Write-Host "[FUZZING] Total de palavras testadas: $totalWords" -ForegroundColor White
        Write-Host "[FUZZING] Resultados interessantes encontrados: $($results.Count)" -ForegroundColor Cyan
        
        if ($results.Count -gt 0) {
            Write-Host "`n[FUZZING] RESULTADOS ENCONTRADOS:" -ForegroundColor Yellow
            $results | Format-Table URL, StatusCode, ContentLength -AutoSize
            
            # Pergunta se quer salvar os resultados
            Write-Host "`n[FUZZING] Deseja salvar os resultados em arquivo?" -ForegroundColor Yellow
            $saveResults = Read-Host "   (S) Sim / (N) Nao [Padrao: N]"
            
            if ($saveResults -eq 'S' -or $saveResults -eq 's') {
                $fuzzingDir = "Fuzz_files"
                if (-not (Test-Path $fuzzingDir)) {
                    New-Item -ItemType Directory -Path $fuzzingDir -Force | Out-Null
                }
                
                $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
                $outputFile = Join-Path $fuzzingDir "fuzzing_results_$timestamp.csv"
                $results | Export-Csv -Path $outputFile -NoTypeInformation -Encoding UTF8
                
                Write-Host "`n[FUZZING] OK Resultados salvos em: $outputFile" -ForegroundColor Green
            }
        } else {
            Write-Host "[FUZZING] Nenhum resultado interessante encontrado." -ForegroundColor Gray
        }
        
    } catch {
        Write-Host "[FUZZING] X Erro durante fuzzing: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# FUNCAO PRINCIPAL - TESTE COMPLETO
function Testar-FuzzingCompleto {
    Write-Host "==============================================" -ForegroundColor Cyan
    Write-Host "    TESTE DE FUZZING AUTOMATIZADO" -ForegroundColor Cyan
    Write-Host "==============================================" -ForegroundColor Cyan
    
    # URL de teste - businesscorp.com.br
    $urlTeste = "http://businesscorp.com.br"
    Write-Host "`nAlvo de teste: $urlTeste" -ForegroundColor White
    
    # PASSO 1: Scan HTML para extrair palavras
    Write-Host "`n--- PASSO 1: Extraindo palavras do HTML ---" -ForegroundColor Yellow
    $resultadoScan = ScanHTML -url $urlTeste
    
    if ($resultadoScan.TotalWords -eq 0) {
        Write-Host "X Nao foi possivel extrair palavras. Abortando teste." -ForegroundColor Red
        return
    }
    
    # PASSO 2: Decidir como fazer o fuzzing
    Write-Host "`n--- PASSO 2: Configurando Fuzzing ---" -ForegroundColor Yellow
    
    $caminhoWordlist = $null
    
    if ($resultadoScan.SavedFilePath) {
        Write-Host "OK Arquivo de wordlist salvo: $($resultadoScan.SavedFilePath)" -ForegroundColor Green
        $usarArquivo = Read-Host "`nDeseja usar o arquivo salvo para fuzzing? (S) Sim / (N) Nao [Padrao: S]"
        
        if ($usarArquivo -eq 'N' -or $usarArquivo -eq 'n') {
            Write-Host "X Fuzzing cancelado pelo usuario." -ForegroundColor Yellow
            return
        } else {
            $caminhoWordlist = $resultadoScan.SavedFilePath
        }
    } else {
        Write-Host "I Nenhum arquivo salvo. E necessario salvar as palavras para fazer fuzzing." -ForegroundColor Yellow
        return
    }
    
    # PASSO 3: Executar Fuzzing
    Write-Host "`n--- PASSO 3: Executando Fuzzing ---" -ForegroundColor Yellow
    
    # Configura delay (mais lento para teste)
    $delay = Read-Host "Delay entre requisicoes (ms) [Padrao: 200]"
    if (-not $delay -or -not ($delay -as [int])) {
        $delay = 200
    }
    
    Write-Host "`nIniciando fuzzing em 3 segundos..." -ForegroundColor Cyan
    Start-Sleep -Seconds 3
    
    # Executa o fuzzing
    Start-Fuzzing -url $urlTeste -wordlist $caminhoWordlist -delay $delay
    
    Write-Host "`n==============================================" -ForegroundColor Cyan
    Write-Host "    TESTE CONCLUIDO" -ForegroundColor Cyan
    Write-Host "==============================================" -ForegroundColor Cyan
}

# EXECUTA O TESTE COMPLETO
Testar-FuzzingCompleto

# Tambem disponibiliza as funcoes individualmente
Write-Host "`n`nFuncoes disponiveis:" -ForegroundColor Green
Write-Host "- ScanHTML -url URL" -ForegroundColor White
Write-Host "- Start-Fuzzing -url URL -wordlist caminho-arquivo [-delay ms]" -ForegroundColor White
Write-Host "- Testar-FuzzingCompleto" -ForegroundColor White
