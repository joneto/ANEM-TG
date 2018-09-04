--Arquivos de Testes--
.constant  EndVetorHabInterrupt	= 65488 -- 16#FFD0#
		--Portas A, B e C
.constant   EndPortaA		    = 65489 -- 16#FFD1#
.constant 	EndPortaARegZ	  = 65490 -- 16#FFD2#
.constant		EndPortaARegInt	= 65491 -- 16#FFD3#
.constant		EndPortaB	      = 65492 -- 16#FFD4#
.constant		EndPortaBRegZ	  = 65493 -- 16#FFD5#
.constant		EndPortaBRegInt = 65494 -- 16#FFD6#
.constant		EndPortaC	      = 65495 -- 16#FFD7# 
.constant		EndPortaCRegZ	  = 65496 -- 16#FFD8#
.constant		EndPortaCRegInt	= 65497 -- 16#FFD9#
			--USART
.constant   EndRegTXData	  = 65498 -- 16#FFDA#
.constant		EndRegRXData    =	65499 -- 16#FFDB#
.constant		EndRegUARTCfg   =	65500 -- 16#FFDC#
.constant		EndRegUARTBaud  =	65501 -- 16#FFDD#
			--LCD
.constant   EndPortaLCD     =	65502 -- 16#FFDE#
			--Portas D e E
.constant   EndPortaD	      =	65503 -- 16#FFDF# 
.constant		EndPortaDRegZ   =	65504 -- 16#FFE0#
.constant		EndPortaDRegInt =	65505 -- 16#FFE1#
.constant		EndPortaE	      = 65506 -- 16#FFE2#
.constant		EndPortaERegZ	  = 65507 -- 16#FFE3#
.constant		EndPortaERegInt	= 65508 -- 16#FFE4#
		--Timer:
.constant		EndRegConfig	  = 65509 -- 16#FFE5#
.constant		EndRegParada0   = 65510 -- 16#FFE6#
.constant		EndRegParada1   = 65511 -- 16#FFE7#
.constant		EndTimer0	      = 65512 -- 16#FFE8#
.constant		EndTimer1	      = 65513 -- 16#FFE9#
		--Mac
.constant   EndRegMacA0     =	65514 -- 16#FFEA#
.constant		EndRegMacA1     =	65515 -- 16#FFEB#
.constant		EndRegMacBu     =	65516 -- 16#FFEC#
.constant		EndRegMacBs     =	65517 -- 16#FFED#
.constant		EndRegMacC      =	65518 -- 16#FFEE#
    --Contantes de Configuração:
.constant   timer0          = 66 --246 -- habilita o timer0 a contar com o clock mais lento
.constant   timer1          = 256 -- habilita o timer1 para contar sem parar 
.constant   jogada1         = 4 -- MUDAR DEPOIS!!!! 
-----------------------------------------------
	LIW $1,1 -- sera usado para incrementos e decrementos unitarios
	LIW $13,512 -- primeiro endereco da pilha de procedimentos (decresce)
	LIW $14,0 -- primeiro endereco dados usado pelo programa (cresce)
	LIW $7,32 -- habilita as seguintes interrupcoes: timer0
	LIW $8,%EndVetorHabInterrupt% -- FFD0
	SW  $7,0($8) -- grava $7 no registrador VetorHabInt (endereco FFD0)

  LIW $8,%EndRegParada0%
  LIW $6,10
  SW  $6,0($8)
  LIW $8,%EndPortaB%
  SW  $6,0($8)
  AND $7,$0
  LIW $8,%EndRegConfig%
  LIW $6,98 -- 66 --114
  SW  $6,0($8)
--loop:  LIW $8,%EndTimer0%
--      LW  $5,0($8)
--      LIW $8,%EndPortaD%
--      SW  $5,0($8)
--      LIW $8,%EndPortaA%
--      LW  $7,0($8)
--      BEQ $7,$1,1
--      J   %loop%
 --     LIW $8,%EndRegConfig%
 --     SW  $0,0($8)
 --     J   %loop%
 loop: BEQ $7,$1,1
       J   %loop% 
  LIW $8,%EndPortaD%
  SW  $6,0($8)
aqui: J %aqui%
------ Caso ocorra uma interrupcao no timer ------
.address 4053 --definição do vetor de interrupcao
            J %timer0%
.address 2048 -- valor qualquer. Estou colocando na parte alta da memoria pra nao ter risco do programa sobrescrever essa parte.
timer0:     SW  $15,0($13) -- salva o endereco de retorno na pilha
	          SUB $13,$1 -- subtrai um do apontador da pilha
	          LIW $8,%EndRegConfig%
            SW  $0,0($8)--desabilita os timers
            LIW $8,%EndPortaD%
            SW $1,0($8)
            HAB -- re-habilita interrupções
            LIW $7,1 -- sair do BEQ
	          LW  $15,1($13) -- recupera o endereco de retorno da pilha
	          ADD $13,$1 -- adiciona um no apontador da pilha
	          --LIW $15,%loop%
            JR  $15 -- retorna para o ponto de chamada da função
            --J   %loop%
