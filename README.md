# Guia de Comandos Básicos do PowerShell

Este guia contém comandos básicos do PowerShell para iniciantes. Use-os para navegar, gerenciar arquivos e executar tarefas simples no terminal.

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

----

## Outros Comandos Úteis

#### cls (Clear Screen)
Limpa a tela do console.  
**Exemplo:**
```powershell
cls
```

#### echo
Exibe uma mensagem no console.  
**Exemplo:**
```powershell
echo Olá, Mundo!
```

#### Get-Help
Mostra a ajuda para um comando específico.  
**Exemplo:**
```powershell
Get-Help cd
```

----

## Como Usar
1. Abra o PowerShell no Windows (pressione Win + X e selecione "Windows PowerShell").
2. Digite os comandos conforme necessário.
3. Use `Get-Help <comando>` para obter mais informações sobre qualquer comando.
