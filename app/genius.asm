-- Gênius
-- Valor n! sera gravado em dois barramentos de saida, sera tambem mostrado no display LCD e enviado de volta pela porta serial
---------------------------------------------------------
-- Organização dos registradores para este software:
-- $0 -> 0 (hard), $1 -> 1 (soft)
-- $2,$3,$4,$5 -> área de troca de informações com subrotinas (argumentos e retorno): "temporários"
-- $6,$7, -> "temporários", uma função pode escrever neles sem antes salvá-los
-- $8 -> endereços contantes
-- $9,$10,$11,$12 -> "super registrador" (devem ser preservados pela chamada de uma função)
-- $13 -> stack pointer, "saved"
-- $14 -> data pointer, "saved"
-- $15 -> return address, "empilhável"
---------------------------------------------------------
---- Endereços de periféricos do Anem16 -------------
.constant   EndVetorHabInterrupt  = 65488 -- 16#FFD0#
    --Portas A, B e C
.constant   EndPortaA        = 65489 -- 16#FFD1#
.constant   EndPortaARegZ    = 65490 -- 16#FFD2#
.constant    EndPortaARegInt  = 65491 -- 16#FFD3#
.constant    EndPortaB        = 65492 -- 16#FFD4#
.constant    EndPortaBRegZ    = 65493 -- 16#FFD5#
.constant    EndPortaBRegInt = 65494 -- 16#FFD6#
.constant    EndPortaC        = 65495 -- 16#FFD7# 
.constant    EndPortaCRegZ    = 65496 -- 16#FFD8#
.constant    EndPortaCRegInt  = 65497 -- 16#FFD9#
    --USART
.constant   EndRegTXData    = 65498 -- 16#FFDA#
.constant    EndRegRXData    =  65499 -- 16#FFDB#
.constant    EndRegUARTCfg   =  65500 -- 16#FFDC#
.constant    EndRegUARTBaud  =  65501 -- 16#FFDD#
    --LCD
.constant   EndPortaLCD     =  65502 -- 16#FFDE#
    --Portas D e E
.constant   EndPortaD        =  65503 -- 16#FFDF# 
.constant    EndPortaDRegZ   =  65504 -- 16#FFE0#
.constant    EndPortaDRegInt =  65505 -- 16#FFE1#
.constant    EndPortaE        = 65506 -- 16#FFE2#
.constant    EndPortaERegZ    = 65507 -- 16#FFE3#
.constant    EndPortaERegInt  = 65508 -- 16#FFE4#
    --Timer:
.constant    EndRegConfig    = 65509 -- 16#FFE5#
.constant    EndRegParada0   = 65510 -- 16#FFE6#
.constant    EndRegParada1   = 65511 -- 16#FFE7#
.constant    EndTimer0        = 65512 -- 16#FFE8#
.constant    EndTimer1        = 65513 -- 16#FFE9#
    --Mac
.constant   EndRegMacA0     =  65514 -- 16#FFEA#
.constant    EndRegMacA1     =  65515 -- 16#FFEB#
.constant    EndRegMacBu     =  65516 -- 16#FFEC#
.constant    EndRegMacBs     =  65517 -- 16#FFED#
.constant    EndRegMacC      =  65518 -- 16#FFEE#
   -- constantes ASCII
.constant   ASCII0          = 48
.constant   ASCII1          = 49
.constant   ASCII2          = 50
.constant   ASCII3          = 51
.constant   ASCII4          = 52
.constant   ASCII5          = 53
.constant   ASCII6          = 54
.constant   ASCII7          = 55
.constant   ASCII8          = 56
.constant   ASCII9          = 57
.constant   ASCIIa          = 97
.constant   ASCIIb          = 98
.constant   ASCIIc          = 99
.constant   ASCIId          = 100
.constant   ASCIIe          = 101
.constant   ASCIIf          = 102
.constant   ASCIIg          = 103
.constant   ASCIIh          = 104
.constant   ASCIIi          = 105
.constant   ASCIIj          = 106
.constant   ASCIIk          = 107
.constant   ASCIIl          = 108
.constant   ASCIIm          = 109
.constant   ASCIIn          = 110
.constant   ASCIIo          = 111
.constant   ASCIIp          = 112
.constant   ASCIIq          = 113
.constant   ASCIIr          = 114
.constant   ASCIIs          = 115
.constant   ASCIIt          = 116
.constant   ASCIIu          = 117
.constant   ASCIIv          = 118
.constant   ASCIIw          = 119
.constant   ASCIIx          = 120
.constant   ASCIIy          = 121
.constant   ASCIIz          = 122
.constant   ASCIICAPS       = 32 -- subtrair de uma minuscula para obter uma maiuscula
.constant   ASCIISPACE      = 32 -- subtrair de uma minuscula para obter uma maiuscula
    --Contantes de Configuração:
.constant   timer0          = 66 -- habilita clock mais rapido e reg parada --66 --246 -- habilita o timer0 a contar com o clock mais lento
.constant   timer1          = 16640--256 -- habilita o timer1 para contar sem parar 
.constant   jogada1         = 2048 --8192 -- MUDAR DEPOIS!!!!
.constant   tempoaceso      = 2048
.constant   tempoapagado    = 1024
   -- Variáveis de memória
.constant   DataPointer     = 0
.constant   StackPointer    = 512
.constant   EndContador     = 513 -- em que posicao do jogo o jogador esta
.constant   BotaoApertado   = 514 -- guarda o botão que foi apertado pelo jogador 
.constant   ContadorTemp    = 515 -- guarda o botão que foi apertado pelo jogador 
.constant   tempvar         = 516
.constant   VetorMaquina    = 517 -- enderecos 517, 518, 519 e 520 guardam o superregistrador $9,$10,$11,$12 ao fim da vez da maquina
.constant   LedASerAceso    = 521

-----------------------------------------------
  LIW $1,1 -- sera usado para incrementos e decrementos unitarios
  LIW $13,%StackPointer% -- primeiro endereco da pilha de procedimentos (decresce)
  LIW $14,%DataPointer% -- primeiro endereco dados usado pelo programa (cresce)
  LIW $7,32 -- habilita as seguintes interrupcoes: timer0
  LIW $8,%EndVetorHabInterrupt% -- FFD0
  SW  $7,0($8) -- grava $7 no registrador VetorHabInt (endereco FFD0)
  LIW $8,%EndRegUARTBaud%
  LIW $7,5208
  SW  $7,0($8) -- configura o baudrate da porta serial para 9600 bps
  LIW $8,%EndRegTXData%
  LIW $7,%ASCIIg%
  SW  $7,0($8) -- manda g para testar a UART
  LIW $7,%ASCIIe%
  SW  $7,0($8) -- manda g para testar a UART
  LIW $7,%ASCIIn%
  SW  $7,0($8) -- manda g para testar a UART
  LIW $7,%ASCIIi%
  SW  $7,0($8) -- manda g para testar a UART
  LIW $7,%ASCIIu%
  SW  $7,0($8) -- manda g para testar a UART
  LIW $7,%ASCIIs%
  SW  $7,0($8) -- manda g para testar a UART
  LIW $8,%EndRegUARTCfg%
  LIW $7,38912
  SW  $7,0($8) -- configura a porta serial para enviar qualquer byte colocado no buffer
  JAL %escrevegenius%
-----------------------------------------
------------------INICIO-----------------
inicio: LIW $8,%EndContador%
        SW  $1,0($8) --inicia o contadador com o valor 1
loopInicio: LIW $2,15 -- criando mascara para os botões
        LIW $8,%EndPortaA%
        LW  $3,0($8) --lendo a Porta A
        AND $3,$2 --pegando apenas os 4 botões que serão usados
        BEQ $3,$0,2 --se algum botão for apertado inicia o jogo 
        JAL %gerasequencia%
        J %maquina%        
        J %loopInicio%
-----------------------------------------
--------------VEZ DA MAQUINA-------------   
-- $2 guarda o valor do contador          
maquina:     JAL %escrevemaquinajoga%
             LIW $8,%EndContador%
             LW $2,0($8) -- lendo o contador (determina qual eh a jogada atual)
             LIW $8,%ContadorTemp%
             ADD $2,$1
             SW $2,0($8) -- guarda tb numa variavel temporaria
loopMaquina: LIW $8,%ContadorTemp%
             LW $2,0($8)
             SUB $2,$1
             SW $2,0($8) -- guarda numa variavel temporaria
-- pausa de debug--
--             LIW $8,%EndPortaA%
--loopdebug1:	 LW $3,0($8)
--	  	       BEQ $3,$0,%loopdebug1%
--             LIW $8,%EndPortaD%
--             LIW $3,65280
--             OR $3,$2
--             SW $3,0($8) --escreve nos LEDs
--            LIW $8,%EndPortaA%
--loopdebug2:  LW $3,0($8)
--             BEQ $3,$0,1
--             J %loopdebug2%
-- fim da pausa de debug
             BEQ $2,$0,1
             J %continuar%
             J %jogador%
-- $5 guarda o valor do registrados em que está o número a ser lido
continuar: AND $6,$0
           OR  $6,$2 -- copia o conteudo de $2 para $6 para ser usado temporariamente
           AND $5,$0 -- limpar o registrador que vai guardar o registrador a ser acendido
           LIW $3,8
           SLT $3,$6 --verifica $3 é menor que $6
           BEQ $3,$1,2 -- se for menor pula o pulo
           OR  $5,$12 --copia o conteudo de $12 para o $5
           J %definirposicao%
           LIW $3,8
           SUB $6,$3
           SLT $3,$6 --verifica $3 é menor que $6
           BEQ $3,$1,2 -- se for menor pula o pulo
           OR  $5,$11 --copia o conteudo de $11 para o $5
           J %definirposicao%
           LIW $3,8
           SUB $6,$3
           SLT $3,$6 --verifica $3 é menor que $6
           BEQ $3,$1,2 -- se for menor pula o pulo
           OR  $5,$10 --copia o conteudo de $10 para o $5
           J %definirposicao%
           LIW $3,8
           SUB $6,$3
           OR  $5,$9 -- copia o conteudo do $9 para o $5
definirposicao: AND $7,$0 
                OR  $7,$5 -- copia o valor de 
                LIW $3,1 -- o reg $3 é carregado com o valor a ser comparado
                SLT $3,$6 -- então é visto se a posição no reg $6 é maior que a do $3
                BEQ $3,$1,2 -- se $6 for maior pula o acender LED, pois ainda precisa-se definir a posição correta do vetor
                JAL %acenderled%                
                J %loopMaquina%
                LIW $3,2
                SLT $3,$6
                BEQ $3,$1,3
                SHR $7,2
                JAL %acenderled%
                J %loopMaquina%
                LIW $3,3
                SLT $3,$6
                BEQ $3,$1,3
                SHR $7,4
                JAL %acenderled%
                J %loopMaquina%
                LIW $3,4
                SLT $3,$6
                BEQ $3,$1,3
                SHR $7,6
                JAL %acenderled%
                J %loopMaquina%
                LIW $3,5
                SLT $3,$6
                BEQ $3,$1,3
                SHR $7,8
                JAL %acenderled%
                J %loopMaquina%
                LIW $3,6
                SLT $3,$6
                BEQ $3,$1,3
                SHR $7,10
                JAL %acenderled%
                J %loopMaquina%
                LIW $3,7
                SLT $3,$6
                BEQ $3,$1,3
                SHR $7,12
                JAL %acenderled%
                J %loopMaquina%
                SHR $7,14 --8
                JAL %acenderled%
                SUB $2,$1
                J %loopMaquina%
-----------------------------------------
-----------VEZ DO JOGADOR----------------
jogador:  JAL %escrevehumanojoga%
          LIW $8,%EndContador%
          LW $2,0($8) -- lendo o contador (determina qual eh a jogada atual), sera a variavel de iteracao
loopjog1: LIW $8,%EndPortaA% 
          LIW $6,15 --mascara para os quatro primeiros bits
          LW  $5,0($8) --lendo a portaA
          AND $5,$6 -- seleciona apenas os 4 primeiros bits
          BEQ $5,$0,%loopjog1%
          LIW $8,%BotaoApertado% -- guarda o botão que foi apertado para poder ser comparado se foi o botão correto
          SW  $5,0($8)
          LIW $8,%EndRegTXData%
          SW  $5,0($8)
          BEQ $2,$1,1
          J %loopjog2%
          JAL %configtimergeraseq%
loopjog2: LIW $6,15 --mascara para os quatro primeiros bits
          LIW $8,%EndPortaA%
          LW $5,0($8) --lendo a portaA
          AND $5,$6 -- seleciona apenas os 4 primeiros bits
          LIW $8,%EndPortaD%
          SW $5,0($8) --escreve nos LEDs
          LIW $8,%EndTimer1% --TESTE
          LW  $6,0($8)
          LIW $8,%EndPortaC%
          SW  $6,0($8) -- FIM DO TESTE
          BEQ $5,$0,1
          J   %loopjog2%
          LIW $8,%BotaoApertado%
          LW  $5,0($8)
          LIW $8,%EndRegTXData%
          SW  $5,0($8)
          JAL %comparar%
          SUB $2,$1 -- subtrai um da variavel de iteracao
          BEQ $2,$0,1
          J %loopjog1%
fimhumano:JAL %supershiftleft% 
          JAL %supershiftleft% -- desloca o superegistrador em duas posicoes
          LIW $8,%EndRegConfig%
          SW  $0,0($8)--faz parar o timer1 de contar
          LIW $5,3 --cria mascada para os dois primeiros bits  -- troquei a ordem, pra poder usar o $6
          AND $6,$5 --pega os dois primeiros bits
          --Mostrar o valor soteado para debug
                LIW $8,%EndPortaC% 
                SW  $6,0($8)
	        -- fim do debug
          OR  $12,$6 --salva os dois bits no inicio do superregistrador
          SW  $12,0($8)
          LIW $8,%EndContador%
          LW $2,0($8) -- lendo o contador (determina qual eh a jogada atual)
          ADD $2,$1   -- incrementa o contador de jogadas       
          SW $2,0($8) -- grava na memoria
          J %maquina% -- eh a vez da maquina jogar de novo...
configtimergeraseq: SW  $15,0($13) -- salva o endereco de retorno na pilha
                    SUB $13,$1 -- subtrai um do apontador da pilha
                    HAB -- habilita as interrupcoes
                    LIW $8,%EndRegConfig%
                    LIW $7,%timer1% --habilita o timer1 a ficar contando com um clock muito rapido, mas nao tanto para nao ficar na mesma velocidade do processador (deixaria de ser aleatorio, pois o numero de instrucoes par faria que a resposta fosse sempre par)
                    SW  $7,0($8)--gravando do registrador de configuração do Timer
                    LW  $15,1($13) -- recupera o endereco de retorno da pilha
                    ADD $13,$1 -- adiciona um no apontador da pilha
                    JR  $15 -- retorna para o ponto de chamada da função
-----------------------------------------------
-----------------COMPARAR---------------------- Comparar o valor em $5, com o valor correspondente no superregistrador
comparar: SW  $15,0($13) -- salva o endereco de retorno na pilha
          SUB $13,$1 -- subtrai um do apontador da pilha
          HAB
          -- primeiro salvamos o superregistrador na memoria para poder modifica-lo
            LIW $8,%VetorMaquina%
            SW  $9,0($8)
            SW  $10,1($8)
            SW  $11,2($8)
            SW  $12,3($8)
          LIW $8,%BotaoApertado%
          LW $5,0($8)
          -- determinar quanto precisa deslocar o superregistrador para a direita a fim de obter o valor a ser comparado
            AND $3,$0
            OR  $3,$2
lacodesloc: BEQ $3,$1,%beq0%  -- precisamos deslocar o superregistrador 2*($2-1) vezes para a direita
            SUB $3,$1
            JAL %supershiftright%
            JAL %supershiftright%
            J %lacodesloc%
beq0:     LIW $3,3 -- mascara...
          AND $12,$3 -- pega os 2 ultimos bits de $12
          --Mostrar o valor para debug
                LIW $8,%EndPortaC% 
                SW  $12,0($8)
	        -- fim do debug
          --Mostrar o valor para debug
                LIW $8,%EndPortaB% 
                SW  $5,0($8)
	        -- fim do debug
          LIW $3,2
          BEQ $12,$0,1 -- se o primeiro led eh o que foi aceso...
          J %beq1%
          BEQ $5,$1,1 -- o jogador precisa ter usado o primeiro botao ($5=1)
          J %gameover%
          J %jacertou%
beq1:     BEQ $12,$1,1 -- se o segundo led foi aceso pela maquina...
          J %beq2%
          BEQ $5,$3,1 -- o jogador precisa ter usado o segundo botao ($5=2)
          J %gameover%      
          J %jacertou%
beq2:     BEQ $12,$3,1 -- se o terceiro led foi aceso pela maquina...
          J %beq3%
          SHL $3,1
          BEQ $5,$3,1 -- o jogador precisa ter usado o terceiro botao ($5=4)
          J %gameover%      
          J %jacertou%
beq3:     SHL $3,2
          BEQ $5,$3,1 -- caso contrario, o jogador precisa ter usado o quarto botao ($5=8)
          J %gameover%      
          -- recuperamos o superregistrador ao que era anteriormente
jacertou:   LIW $8,%VetorMaquina%
            LW  $9,0($8)
            LW  $10,1($8)
            LW  $11,2($8)
            LW  $12,3($8)
          LW  $15,1($13) -- recupera o endereco de retorno da pilha
          ADD $13,$1 -- adiciona um no apontador da pilha
          JR  $15 -- retorna para o ponto de chamada da função
----------------------------------------
--------- FIM DE JOGO ------------------
----------------------------------------
-- pausa de debug--
gameover: JAL %escreveGameOver%
          J %gameover%
-----------------------------------------
--------SUB ROTINA ACENDERLED------------
acenderled: SW  $15,0($13) -- salva o endereco de retorno na pilha
            SUB $13,$1 -- subtrai um do apontador da pilha
            LIW $8,%tempvar%            
            SW  $15,0($8)
            HAB -- habilita as interrupcoes
            LIW $3,3
            AND $7,$3
            LIW $3,0 --registrador para comparar
            LIW $4,1 --led que vai acender
            BEQ $3,$7,1 --se o número em $2 for 0 esse LED vai ser ligado
            J %xyz%
            J %acender%
xyz:     ADD $3,$1
         SHL $4,1
         BEQ $3,$7,%acender% --se o número em $2 for 1 esse LED vai ser ligado
         ADD $3,$1
         SHL $4,1
         BEQ $3,$7,%acender% --se for 2...
         SHL $4,1
         LIW $8,%BotaoApertado%
         SW  $4,0($8)
acender: LIW $8,%EndPortaD%
         SW  $4,0($8) --acender o LED
         LIW $8,%EndRegTXData%
         SW  $4,0($8)
         LIW $8,%EndRegParada0%
         LIW $7,%tempoaceso%
         SW  $7,0($8) --grava no registrador de parada o valor o qual é pra contar até ele.
         LIW $7,118--114 
         LIW $8,%EndRegConfig%
         SW  $7,0($8)
         AND $7,$0
         AND $4,$0 -- variavel que vai servir de controle por causa da GAMBIARRA (depois que o problema do link for resolvido torna-se desnecessário)
loop11:  BEQ $7,$1,%retornot%
         LIW $8,%EndTimer0%
         LW  $14,0($8)
         LIW $8,%EndPortaB%
         SW  $14,0($8)
         J   %loop11%
retornot:BEQ $4,$0,1
	 J   %lacabou1%
	 LIW $8,%EndRegTXData%
         SW  $0,0($8)
         AND $4,$0
	 OR  $4,$1
	 LIW $8,%EndPortaD% --- ESTA LINHA CONTÉM UMA GAMBIARRA (ver interrupcao do timer)
         SW  $0,0($8) --apagar todos os LEDs
         LIW $8,%EndRegParada0%
         LIW $7,%tempoapagado%
         SW  $7,0($8) --grava no registrador de parada o valor o qual é pra contar até ele.
         LIW $7,118--114 
         LIW $8,%EndRegConfig%
         SW  $7,0($8)
         AND $7,$0
loop12:  BEQ $7,$1,%lacabou1%
         LIW $8,%EndTimer0%
         LW  $14,0($8)
         LIW $8,%EndPortaB%
         SW  $14,0($8) 
         J   %loop12%
lacabou1:LW  $15,1($13) -- recupera o endereco de retorno da pilha
         ADD $13,$1 -- adiciona um no apontador da pilha
         LIW $8,%tempvar%            
         LW  $15,0($8)
         JR  $15 -- retorna para o ponto de chamada da função
-----------------------------------------
-----SUB ROTINA GERASEQUENCIA------------
--os registradores que precisão ser preservados: nenhum;
gerasequencia:  SW  $15,0($13) -- salva o endereco de retorno na pilha
                SUB $13,$1 -- subtrai um do apontador da pilha
                HAB -- habilita as interrupcoes
                JAL %supershiftleft% 
                JAL %supershiftleft% -- desloca o superegistrador em duas posicoes
                LIW $8,%EndRegConfig%
                LIW $7,%timer1% --habilita o timer1 a ficar contando com um clock muito rapido, mas nao tanto para nao ficar na mesma velocidade do processador (deixaria de ser aleatorio, pois o numero de instrucoes par faria que a resposta fosse sempre par)
                SW  $7,0($8)--gravando do registrador de configuração do Timer
                LIW $2,15 -- criando mascara para os botões
loop:           LIW $8,%EndTimer1% --TESTE
                LW  $6,0($8)
                LIW $8,%EndPortaC%
                SW  $6,0($8) -- FIM DO TESTE
                LIW $8,%EndPortaA%
                LW  $3,0($8) --lendo a Porta A
                AND $3,$2 --pegando apenas os 4 botões que serão usados
--                LIW $8,%EndPortaD%
--                SW $3,0($8) --carregar na PortaD
                BEQ $3,$0,1 --enquanto algum botão for apertado deixar o timer contando
                J %loop%
--                LIW $8,%EndTimer1%
--                LW  $5,0($8) --lê o registrador de saida do timer1 e salva no $5   ---   COMENTEI ISSO AQUI PQ O VALOR JÁ TÁ NO $6 (Geraldo)
                LIW $8,%EndRegConfig%
                SW  $0,0($8)--faz parar o timer1 de contar
                LIW $5,3 --cria mascada para os dois primeiros bits  -- troquei a ordem, pra poder usar o $6
                AND $6,$5 --pega os dois primeiros bits
               --Mostrar o valor soteado para debug
                LIW $8,%EndPortaC% 
                SW  $6,0($8)
	        -- fim do debug
                OR  $12,$6 --salva os dois bits no inicio do superregistrador
                SW  $12,0($8)
                LW  $15,1($13) -- recupera o endereco de retorno da pilha
                ADD $13,$1 -- adiciona um no apontador da pilha
                JR  $15 -- retorna para o ponto de chamada da função
-----------------------------------------
----- SUB SUB ROTINA DE SHIFT ----
-- Função que desloca 1 bit para a esquerda o "super-registrador" composto por $9,$10,$11,$12
supershiftleft: SW  $15,0($13) -- salva o endereco de retorno na pilha
                SUB $13,$1 -- subtrai um do apontador da pilha
                HAB -- re-habilita interrupções
                AND $7,$0
                OR  $7,$10
                SHR $7,15
                SHL $9,1
                OR  $9,$7
                AND $7,$0
                OR  $7,$11
                SHR $7,15
                SHL $10,1
                OR  $10,$7
                AND $7,$0
                OR  $7,$12
                SHR $7,15
                SHL $11,1
                OR  $11,$7
                SHL $12,1
                LW  $15,1($13) -- recupera o endereco de retorno da pilha
                ADD $13,$1 -- adiciona um no apontador da pilha
                JR  $15 -- retorna para o ponto de chamada da função
-- Função que desloca 1 bit para a direita o "super-registrador" composto por $9,$10,$11,$12
supershiftright:SW  $15,0($13) -- salva o endereco de retorno na pilha
                SUB $13,$1 -- subtrai um do apontador da pilha
                HAB -- re-habilita interrupções
                AND $7,$0
                OR  $7,$11
                SHL $7,15
                SHR $12,1
                OR  $12,$7
                AND $7,$0
                OR  $7,$10
                SHL $7,15
                SHR $11,1
                OR  $11,$7
                AND $7,$0
                OR  $7,$9
                SHL $7,15
                SHR $10,1
                OR  $10,$7
                SHR $9,1
                LW  $15,1($13) -- recupera o endereco de retorno da pilha
                ADD $13,$1 -- adiciona um no apontador da pilha
                JR  $15 -- retorna para o ponto de chamada da função
--------------------------------------------------------------------------
--------------------- FUNCOES DE ESCRITA NO LCD --------------------------
--------------------------------------------------------------------------
----- SUB ROTINA ESCREVELCD -----
-- Função que escreve no endereço $2 da ram do LCDDriver, presente na porta $3 a informação em $4
escrevelcd: SW  $15,0($13) -- salva o endereco de retorno na pilha
            SUB $13,$1 -- subtrai um do apontador da pilha
            HAB -- re-habilita interrupções
            LIW $5,255 -- mascara de 1 byte menos significativo
            AND $6,$0
            OR  $6,$2
            SHL $6,8
            AND $4,$5 -- aplica mascara na info para garantir que nao passa de 1 byte
            OR  $6,$4 -- Data = 'a'
            LIW $8,%EndPortaLCD%
            SW  $6,0($8) -- escreve na portaLCD    
            LIW $5,16384 -- Wen = 1, others = 0
            OR  $6,$5 -- Wen = 1
            SW  $6,0($8) -- escreve na portaLCD, ordenando escrita na RAM do LCDDriver
            LW  $15,1($13) -- recupera o endereco de retorno da pilha
            ADD $13,$1 -- adiciona um no apontador da pilha
            JR  $15 -- retorna para o ponto de chamada da função-
-------------------- Escrever "Maquina joga" no LCD --------------------------------
escrevemaquinajoga: 	SW  $15,0($13) -- salva o endereco de retorno na pilha
                      SUB $13,$1 -- subtrai um do apontador da pilha
                      LIW $4,%ASCIIm%
                      LIW $2,%ASCIICAPS%  --  'M'                      
                      SUB $4,$2
                      LIW $2,22 -- endereco do LCD...
                      JAL %escrevelcd% -- escrever $4 no endereco $2 do lcd presente em $3
                      LIW $4,%ASCIIa%
                      ADD $2,$1 -- endereco do LCD...
                      JAL %escrevelcd% -- escrever $4 no endereco $2 do lcd presente em $3
                      LIW $4,%ASCIIq%
                      ADD $2,$1 -- endereco do LCD...
                      JAL %escrevelcd% -- escrever $4 no endereco $2 do lcd presente em $3
                      LIW $4,%ASCIIu%
                      ADD $2,$1 -- endereco do LCD...
                      JAL %escrevelcd% -- escrever $4 no endereco $2 do lcd presente em $3
                      LIW $4,%ASCIIi%
                      ADD $2,$1 -- endereco do LCD...
                      JAL %escrevelcd% -- escrever $4 no endereco $2 do lcd presente em $3
                      LIW $4,%ASCIIn%
                      ADD $2,$1 -- endereco do LCD...
                      JAL %escrevelcd% -- escrever $4 no endereco $2 do lcd presente em $3
                      LIW $4,%ASCIIa%
                      ADD $2,$1 -- endereco do LCD...
                      JAL %escrevelcd% -- escrever $4 no endereco $2 do lcd presente em $3
                      LIW $4,%ASCIISPACE%
                      ADD $2,$1 -- endereco do LCD...
                      JAL %escrevelcd% -- escrever $4 no endereco $2 do lcd presente em $3
                      LIW $4,%ASCIIj%
                      ADD $2,$1 -- endereco do LCD...
                      JAL %escrevelcd% -- escrever $4 no endereco $2 do lcd presente em $3
                      LIW $4,%ASCIIo%
                      ADD $2,$1 -- endereco do LCD...
                      JAL %escrevelcd% -- escrever $4 no endereco $2 do lcd presente em $3
                      LIW $4,%ASCIIg%
                      ADD $2,$1 -- endereco do LCD...
                      JAL %escrevelcd% -- escrever $4 no endereco $2 do lcd presente em $3
                      LIW $4,%ASCIIa%
                      ADD $2,$1 -- endereco do LCD...
                      JAL %escrevelcd% -- escrever $4 no endereco $2 do lcd presente em $3
			                LW  $15,1($13) -- recupera o endereco de retorno da pilha
                      ADD $13,$1 -- adiciona um no apontador da pilha
                      JR  $15 -- retorna para o ponto de chamada da função
-------------------- Escrever "Humano joga" no LCD --------------------------------
escrevehumanojoga:   	SW  $15,0($13) -- salva o endereco de retorno na pilha
                      SUB $13,$1 -- subtrai um do apontador da pilha
                      LIW $4,%ASCIIh%
                      LIW $2,%ASCIICAPS%  --  'H'                      
                      SUB $4,$2
                      LIW $2,22 -- endereco do LCD...
                      JAL %escrevelcd% -- escrever $4 no endereco $2 do lcd presente em $3
                      LIW $4,%ASCIIu%
                      ADD $2,$1 -- endereco do LCD...
                      JAL %escrevelcd% -- escrever $4 no endereco $2 do lcd presente em $3
                      LIW $4,%ASCIIm%
                      ADD $2,$1 -- endereco do LCD...
                      JAL %escrevelcd% -- escrever $4 no endereco $2 do lcd presente em $3
                      LIW $4,%ASCIIa%
                      ADD $2,$1 -- endereco do LCD...
                      JAL %escrevelcd% -- escrever $4 no endereco $2 do lcd presente em $3
                      LIW $4,%ASCIIn%
                      ADD $2,$1 -- endereco do LCD...
                      JAL %escrevelcd% -- escrever $4 no endereco $2 do lcd presente em $3
                      LIW $4,%ASCIIo%
                      ADD $2,$1 -- endereco do LCD...
                      JAL %escrevelcd% -- escrever $4 no endereco $2 do lcd presente em $3
                      LIW $4,%ASCIISPACE%
                      ADD $2,$1 -- endereco do LCD...
                      JAL %escrevelcd% -- escrever $4 no endereco $2 do lcd presente em $3
                      LIW $4,%ASCIIj%
                      ADD $2,$1 -- endereco do LCD...
                      JAL %escrevelcd% -- escrever $4 no endereco $2 do lcd presente em $3
                      LIW $4,%ASCIIo%
                      ADD $2,$1 -- endereco do LCD...
                      JAL %escrevelcd% -- escrever $4 no endereco $2 do lcd presente em $3
                      LIW $4,%ASCIIg%
                      ADD $2,$1 -- endereco do LCD...
                      JAL %escrevelcd% -- escrever $4 no endereco $2 do lcd presente em $3
                      LIW $4,%ASCIIa%
                      ADD $2,$1 -- endereco do LCD...
                      JAL %escrevelcd% -- escrever $4 no endereco $2 do lcd presente em $3
                      LIW $4,%ASCIISPACE%
                      ADD $2,$1 -- endereco do LCD...
                      JAL %escrevelcd% -- escrever $4 no endereco $2 do lcd presente em $3
			                LW  $15,1($13) -- recupera o endereco de retorno da pilha
                      ADD $13,$1 -- adiciona um no apontador da pilha
                      JR  $15 -- retorna para o ponto de chamada da função
-------------------- Escrever "Genius" no LCD --------------------------------
escrevegenius:       	SW  $15,0($13) -- salva o endereco de retorno na pilha
                      SUB $13,$1 -- subtrai um do apontador da pilha
                      LIW $4,%ASCIIg%
                      LIW $2,%ASCIICAPS%  --  'G'                      
                      SUB $4,$2
                      LIW $2,5 -- no endereco 5 do LCD...
                      JAL %escrevelcd% -- escrever $4 no endereco $2 do lcd presente em $3
                      LIW $4,%ASCIIe%
                      ADD $2,$1 -- no endereco 6 do LCD...
                      JAL %escrevelcd% -- escrever $4 no endereco $2 do lcd presente em $3
                      LIW $4,%ASCIIn%
                      ADD $2,$1 -- no endereco 7 do LCD...
                      JAL %escrevelcd% -- escrever $4 no endereco $2 do lcd presente em $3
                      LIW $4,%ASCIIi%
                      ADD $2,$1 -- no endereco 8 do LCD...
                      JAL %escrevelcd% -- escrever $4 no endereco $2 do lcd presente em $3
                      LIW $4,%ASCIIu%
                      ADD $2,$1 -- no endereco 9 do LCD...
                      JAL %escrevelcd% -- escrever $4 no endereco $2 do lcd presente em $3
                      LIW $4,%ASCIIs%
                      ADD $2,$1 -- no endereco 10 do LCD...
                      JAL %escrevelcd% -- escrever $4 no endereco $2 do lcd presente em $3
			                LW  $15,1($13) -- recupera o endereco de retorno da pilha
                      ADD $13,$1 -- adiciona um no apontador da pilha
                      JR  $15 -- retorna para o ponto de chamada da função
-------------------- Escrever "Humano joga" no LCD --------------------------------
escreveGameOver:   	  SW  $15,0($13) -- salva o endereco de retorno na pilha
                      SUB $13,$1 -- subtrai um do apontador da pilha
                      LIW $4,%ASCIIg%
                      LIW $2,%ASCIICAPS%  --  'G'                      
                      SUB $4,$2
                      LIW $2,22 -- endereco do LCD...
                      JAL %escrevelcd% -- escrever $4 no endereco $2 do lcd presente em $3
                      LIW $4,%ASCIIa%
                      ADD $2,$1 -- endereco do LCD...
                      JAL %escrevelcd% -- escrever $4 no endereco $2 do lcd presente em $3
                      LIW $4,%ASCIIm%
                      ADD $2,$1 -- endereco do LCD...
                      JAL %escrevelcd% -- escrever $4 no endereco $2 do lcd presente em $3
                      LIW $4,%ASCIIe%
                      ADD $2,$1 -- endereco do LCD...
                      JAL %escrevelcd% -- escrever $4 no endereco $2 do lcd presente em $3
                      LIW $4,%ASCIISPACE%
                      ADD $2,$1 -- endereco do LCD...
                      JAL %escrevelcd% -- escrever $4 no endereco $2 do lcd presente em $3
                      LIW $4,%ASCIIo%
                      ADD $2,$1 -- endereco do LCD...
                      JAL %escrevelcd% -- escrever $4 no endereco $2 do lcd presente em $3
                      LIW $4,%ASCIIv%
                      ADD $2,$1 -- endereco do LCD...
                      JAL %escrevelcd% -- escrever $4 no endereco $2 do lcd presente em $3
                      LIW $4,%ASCIIe%
                      ADD $2,$1 -- endereco do LCD...
                      JAL %escrevelcd% -- escrever $4 no endereco $2 do lcd presente em $3
                      LIW $4,%ASCIIr%
                      ADD $2,$1 -- endereco do LCD...
                      JAL %escrevelcd% -- escrever $4 no endereco $2 do lcd presente em $3
                      LIW $4,%ASCIISPACE%
                      ADD $2,$1 -- endereco do LCD...
                      JAL %escrevelcd% -- escrever $4 no endereco $2 do lcd presente em $3
                      LIW $4,%ASCIISPACE%
                      ADD $2,$1 -- endereco do LCD...
                      JAL %escrevelcd% -- escrever $4 no endereco $2 do lcd presente em $3
                      LIW $4,%ASCIISPACE%
                      ADD $2,$1 -- endereco do LCD...
                      JAL %escrevelcd% -- escrever $4 no endereco $2 do lcd presente em $3
                      LW  $15,1($13) -- recupera o endereco de retorno da pilha
                      ADD $13,$1 -- adiciona um no apontador da pilha
                      JR  $15 -- retorna para o ponto de chamada da função
--------- INTERRUPCOES -----------
.address 4053 --definição do vetor de int. de carry
            J %inttimer0%
.address 2048 -- valor qualquer. Estou colocando na parte alta da memoria pra nao ter risco do programa sobrescrever essa parte.
inttimer0:  SW  $15,0($13) -- salva o endereco de retorno na pilha
            SUB $13,$1 -- subtrai um do apontador da pilha
            LIW $8,%EndRegConfig%
            SW  $0,0($8)--desabilita os timers
            HAB -- re-habilita interrupções
            LIW $8,%EndPortaD%
            SW $0,0($8)--apaga os LED
            LIW $7,1 -- sair do BEQ
            LW  $15,1($13) -- recupera o endereco de retorno da pilha--
            ADD $13,$1 -- adiciona um no apontador da pilha
	    LIW $15,%retornot%  --- ATENCAO!!!! GAMBIARRA COLOCADA AQUI ATE CONCERTAR O FATO DE NAO ESTAR LINKANDO NA CHAMADA DA INTERRUPCAO <=====
            JR  $15 -- retorna para o ponto de chamada da função
