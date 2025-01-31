# Guia de Comandos Básicos do PowerShell

Este guia contém comandos básicos do PowerShell para iniciantes. Use-os para navegar, gerenciar arquivos, executar tarefas simples e iniciar a programação com scripts.

----

## Comandos Básicos

### Navegação entre Diretórios

#### cd (Change Directory)
Navega para um diretório específico.  
**Exemplo:**
```powershell
cd C:\Pasta
```

#### cd ..
Volta para o diretório pai (um nível acima).  
**Exemplo:**
```powershell
cd ..
```

#### pwd (Print Working Directory)
Exibe o diretório atual em que você está.  
**Exemplo:**
```powershell
pwd
```

----

## Listagem de Arquivos e Pastas

#### dir (Directory Listing)
Lista os arquivos e pastas no diretório atual.  
**Exemplo:**
```powershell
dir
```

Lista os arquivos e pastas no diretório especificado.  
**Exemplo:**
```powershell
dir C:\Pasta
```

----

## Gerenciamento de Arquivos e Pastas

#### mkdir (Make Directory)
Cria uma nova pasta no diretório atual.  
**Exemplo:**
```powershell
mkdir NovaPasta
```

#### rmdir (Remove Directory)
Remove uma pasta vazia.  
**Exemplo:**
```powershell
rmdir Pasta
```

#### copy
Copia um arquivo para outro diretório.  
**Exemplo:**
```powershell
copy arquivo.txt C:\Destino
```

#### move
Move um arquivo para outro diretório.  
**Exemplo:**
```powershell
move arquivo.txt C:\Destino
```

#### del (Delete)
Exclui um arquivo.  
**Exemplo:**
```powershell
del arquivo.txt
```

#### Criar Arquivo
Cria um novo arquivo vazio.  
**Exemplo:**
```powershell
New-Item -Path "novo_arquivo.txt" -ItemType File
```

#### Criar Arquivo com Conteúdo
Cria um arquivo e adiciona um texto dentro dele.  
**Exemplo:**
```powershell
Set-Content -Path "novo_arquivo.txt" -Value "Este é um arquivo criado via PowerShell."
```

#### Adicionar Conteúdo a um Arquivo Existente
Adiciona texto ao final de um arquivo existente.  
**Exemplo:**
```powershell
Add-Content -Path "novo_arquivo.txt" -Value "Nova linha adicionada."
```

#### Ler o Conteúdo de um Arquivo
Exibe o conteúdo de um arquivo no console.  
**Exemplo:**
```powershell
Get-Content -Path "novo_arquivo.txt"
```

----

## Estruturas de Controle

### Loop `for`
Executa um bloco de código várias vezes.  
**Exemplo:**
```powershell
for ($i=1; $i -le 5; $i++) {
    Write-Host "Número: $i"
}
```

### Loop `while`
Executa um bloco de código enquanto uma condição for verdadeira.  
**Exemplo:**
```powershell
$i = 1
while ($i -le 5) {
    Write-Host "Contador: $i"
    $i++
}
```

### Loop `foreach`
Percorre cada item de uma lista.  
**Exemplo:**
```powershell
$nomes = @("Alice", "Bob", "Carlos")
foreach ($nome in $nomes) {
    Write-Host "Nome: $nome"
}
```

----

## Condicionais

### If-Else
Executa comandos diferentes com base em uma condição.  
**Exemplo:**
```powershell
$idade = 18
if ($idade -ge 18) {
    Write-Host "Você é maior de idade."
} else {
    Write-Host "Você é menor de idade."
}
```

### Switch
Permite testar múltiplas condições.  
**Exemplo:**
```powershell
$opcao = "B"
switch ($opcao) {
    "A" { Write-Host "Você escolheu A" }
    "B" { Write-Host "Você escolheu B" }
    "C" { Write-Host "Você escolheu C" }
    default { Write-Host "Opção inválida" }
}
```

----

## Criando e Executando Scripts PowerShell

#### Criar um Script PowerShell
Crie um novo arquivo `.ps1` para armazenar comandos.  
**Exemplo:**
```powershell
New-Item -Path "meu_script.ps1" -ItemType File
```

Abra o arquivo com um editor de texto e adicione comandos como:
```powershell
Write-Host "Olá, Mundo!"
```

#### Executar um Script PowerShell
Execute um script com:  
```powershell
.\meu_script.ps1
```

#### Permitir a Execução de Scripts
Se scripts não estiverem sendo executados, use:  
```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

----

## Trabalhando com Variáveis

#### Declarar e Atribuir Valor a uma Variável
**Exemplo:**
```powershell
$nome = "João"
$idade = 25
Write-Host "Nome: $nome, Idade: $idade"
```

#### Variáveis Numéricas
```powershell
$a = 10
$b = 20
$soma = $a + $b
Write-Host "A soma de $a e $b é $soma"
```

#### Arrays
Criação de uma lista de valores.  
**Exemplo:**
```powershell
$frutas = @("Maçã", "Banana", "Laranja")
Write-Host "Primeira fruta: $frutas[0]"
```

----

## Funções

Criação de uma função personalizada.  
**Exemplo:**
```powershell
function Saudacao {
    param ($nome)
    Write-Host "Olá, $nome!"
}
Saudacao "Carlos"
```

----

## Trabalhando com Processos

#### Listar Processos em Execução
```powershell
Get-Process
```

#### Finalizar um Processo
```powershell
Stop-Process -Name "notepad" -Force
```

----

## Trabalhando com Serviços

#### Listar Serviços em Execução
```powershell
Get-Service
```

#### Iniciar um Serviço
```powershell
Start-Service -Name "wuauserv"
```

#### Parar um Serviço
```powershell
Stop-Service -Name "wuauserv"
```

----

## Como Usar
1. Abra o PowerShell no Windows (pressione `Win + X` e selecione "Windows PowerShell").
2. Digite os comandos conforme necessário.
3. Crie scripts `.ps1` para automatizar tarefas.
4. Use `Get-Help <comando>` para obter mais informações sobre qualquer comando.

