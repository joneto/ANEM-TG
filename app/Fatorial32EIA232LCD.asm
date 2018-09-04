-- Programa que calcula o fatorial do argumento (n) carregado em $2 a partir da porta serial
-- Valor n! sera gravado em dois barramentos de saida, sera tambem mostrado no display LCD e enviado de volta pela porta serial
---------------------------------------------------------
-- Organização dos registradores para este software:
-- $0 -> 0, $1 -> 1
-- $2,$3,$4,$5,$6 -> área de troca de informações com subrotinas (argumentos e retorno): "temporários"
-- $7,$8,$9 -> "temporários", uma função pode escrever neles sem antes salvá-los
-- $10,$11,$12 -> "saved" (devem ser preservados pela chamada de uma função)
-- $13 -> stack pointer, "saved"
-- $14 -> data pointer, "saved"
-- $15 -> return address, "empilhável"
---------------------------------------------------------
.constant   EndVetorHabInterrupt	= 65488 -- 16#FFD0#
		--Portas A, B e C
.constant   	EndPortaA		    = 65489 -- 16#FFD1#
.constant 		EndPortaARegZ	  = 65490 -- 16#FFD2#
.constant		EndPortaARegInt	= 65491 -- 16#FFD3#
.constant		EndPortaB	      = 65492 -- 16#FFD4#
.constant		EndPortaBRegZ	  = 65493 -- 16#FFD5#
.constant		EndPortaBRegInt = 65494 -- 16#FFD6#
.constant		EndPortaC	      = 65495 -- 16#FFD7# 
.constant		EndPortaCRegZ	  = 65496 -- 16#FFD8#
.constant		EndPortaCRegInt	= 65497 -- 16#FFD9#
		--USART
.constant   	EndRegTXData	  = 65498 -- 16#FFDA#
.constant		EndRegRXData    =	65499 -- 16#FFDB#
.constant		EndRegUARTCfg   =	65500 -- 16#FFDC#
.constant		EndRegUARTBaud  =	65501 -- 16#FFDD#
		--LCD
.constant   	EndPortaLCD     =	65502 -- 16#FFDE#
		--Portas D e E
.constant   	EndPortaD	     =	65503 -- 16#FFDF# 
.constant		EndPortaDRegZ    =	65504 -- 16#FFE0#
.constant		EndPortaDRegInt  =	65505 -- 16#FFE1#
.constant		EndPortaE	     = 65506 -- 16#FFE2#
.constant		EndPortaERegZ	 = 65507 -- 16#FFE3#
.constant		EndPortaERegInt	 = 65508 -- 16#FFE4#
		--Timer:
.constant		EndRegConfig	  = 65509 -- 16#FFE5#
.constant		EndRegParada0    = 65510 -- 16#FFE6#
.constant		EndRegParada1    = 65511 -- 16#FFE7#
.constant		EndTimer0	      = 65512 -- 16#FFE8#
.constant		EndTimer1	      = 65513 -- 16#FFE9#
		--Mac
.constant   	EndRegMacA0     =	65514 -- 16#FFEA#
.constant		EndRegMacA1     =	65515 -- 16#FFEB#
.constant		EndRegMacBu     =	65516 -- 16#FFEC#
.constant		EndRegMacBs     =	65517 -- 16#FFED#
.constant		EndRegMacC      =	65518 -- 16#FFEE#
-------------------------------------------------------
	LIW $1,1 -- sera usado para incrementos e decrementos unitarios
	LIW $13,255 -- primeiro endereco da pilha de procedimentos (decresce)
	LIW $14,0 -- primeiro endereco dados usado pelo programa (cresce)
	LIW $7,2 -- habilita as seguintes interrupcoes: carryout -- tava no $5
	LIW $10,%EndVetorHabInterrupt% -- FFD0 -- tava no $6
	SW  $7,0($10) -- grava $5 no registrador VetorHabInt (endereco FFD0)	
	LIW $10,%EndRegTXData% -- FFDA (endereco do registrador RegTXData da UART)
	LIW $11,%EndPortaB% -- FFD4 (endereco do registrador RegPortaB) --> tava no $9
	LIW $12,%EndPortaD% -- FFDF (endereco do registrador RegPortaD) (+3 se torna da PortaE)
	LIW $7,5208 -- valor pelo qual clock sera dividido para gerar um baudrate /= clock do <============== COLOCAR VALOR CORRETO!
	SW  $7,3($10) -- grava valor no RegUARTBaud	
	SW  $1,0($12) -- acende apenas o primeiro LED.
-- Enviar a mensagem anem16 pela UART e para o LCDDriver
	LIW $4,10 -- \n (nova linha)
	SW  $4,0($10) -- manda pela UART
	LIW $4,65  --  'A'
	SW  $4,0($10) -- manda pela UART
	LIW $3,%EndPortaLCD% -- endereco da porta LCD: ['-' 15][Wen 14][RAMAddr 13:8][Data 7:0]	
	AND $2,$0 -- no endereco 0 do LCD...
	JAL %escrevelcd% -- escrever $4 no endereco $2 do lcd presente em $3
	LIW $4,110 --  'n'
	SW  $4,0($10) -- manda pela UART
    ADD $2,$1 -- no endereco 1 do LCD...
	JAL %escrevelcd% -- escrever $4 no endereco $2 do lcd presente em $3
	LIW $4,101 --   'e'
	SW  $4,0($10) -- manda pela UART
	ADD $2,$1 -- no endereco 2 do LCD...
	JAL %escrevelcd% -- escrever $4 no endereco $2 do lcd presente em $3
	LIW $4,109 --   'm'
	SW  $4,0($10) -- manda pela UART
	ADD $2,$1 -- no endereco 3 do LCD...
	JAL %escrevelcd% -- escrever $4 no endereco $2 do lcd presente em $3
	LIW $4,49 --   '1'
	SW  $4,0($10) -- manda pela UART
	ADD $2,$1 -- no endereco 4 do LCD...
	JAL %escrevelcd% -- escrever $4 no endereco $2 do lcd presente em $3
	LIW $4,54 --   '6'
	SW  $4,0($10) -- manda pela USART
	ADD $2,$1 -- no endereco 5 do LCD...
--------- DEBUG:
	LIW $1,2
	SW  $1,0($12) -- acende apenas o segundo LED.
	LIW $1,1
---------------
	JAL %escrevelcd% -- escrever $4 no endereco $2 do lcd presente em $3
--------- DEBUG:
	LIW $1,4	
	SW  $1,0($12) -- acende apenas o terceiro LED.
	LIW $1,1
---------------
-- Receber o numero a ser calculado o fatorial
inicio:		LIW $7,38912 -- RegUARTCfg: 1001100000000000 -> SPEN,TXEN,SREN = configura a uart para receber um unico byte e enviar os bytes do buffer
		SW  $7,2($10) -- grava no registrador RegUARTCfg
--------- DEBUG:
	LIW $1,8	
	SW  $1,0($12) -- acende apenas o terceiro LED.
	LIW $1,1
---------------
espera:		LW  $7,2($10) -- carrega o registrador RegUARTCfg para que possamos monitorar os bits de status
		LIW $8,128 -- mascara para pegar apenas o flag bit 7 no RegUARTCfg (FERR -> framming error)        
		AND $7,$8 -- aplica a mascara
		BEQ $7,$8,%inicio% -- se deu erro de sincronismo (stop bit em nivel logico baixo), tentamos nova recepcao
		LW  $7,2($10) -- carrega o registrador RegUARTCfg para que possamos monitorar os bits de status
		LIW $8,2 -- mascara para pegar apenas o flag bit 1 no RegUARTCfg (RBE -> buffer de recepcao vazio)      
		AND $7,$8 -- aplica a mascara
		BEQ $7,$0,%continua% -- se buffer de recepcao nao esta mais vazio, eh pq recebeu algo
		J   %espera%
continua:	LW  $2,1($10) -- carrega a palavra recebida pela porta serial
--------- DEBUG:
	LIW $1,16	
	SW  $1,0($12) -- acende apenas o terceiro LED.
	LIW $1,1
---------------
--		LIW $2,12 -- COMENTAR ISSO AQUI DEPOIS (SO PARA TESTES)
		LIW $5,255
		AND $2,$5 -- pega apenas o byte menos significativo
		AND $3,$0 -- zeramos $3 - LSW da resposta
		AND $4,$0 -- zeramos $4 - MSW da resposta
		ADD $3,$2 --salva n em $3 para ser gravado na saída.
--------- DEBUG:
	LIW $1,32	
	SW  $1,0($12) -- acende apenas o terceiro LED.
	LIW $1,1
---------------
		BEQ $3,$1,%sai% -- se n=1, resposta eh 1 e termina
		BEQ $3,$0,%sai% -- se n=0, resposta eh 1 e termina
		J %loop% -- caso contrario, calcula o fatorial
sai:	OR $3,$1 -- resposta eh 1...
	J %fim% -- e termina
loop:	SUB $2,$1 -- n <= n-1
	BEQ $2,$1,%fim% -- se $2 ja eh 1, entao termina
	JAL %multiplica% -- chama a subrotina que ira retornar ($4$3)*($2) em $4$3
	J %loop% -- se $2 ainda nao eh 1, entao repete
fim:    SW $3,0($11) -- Grava o LSW na porta B
        SW $4,3($11) -- Grava o MSW na porta C
--------- DEBUG:
	LIW $1,64	
	SW  $1,0($12) -- acende apenas o terceiro LED.
	LIW $1,1
---------------
	AND $5,$0
	OR  $5,$4 -- $5 fica com o MSW da resposta
	AND $6,$0
	OR  $6,$3 -- $6 fica com o LSW da resposta
	LIW $4,20 -- primeiro endereço da segunda linha do LCD
	JAL %PrintNumLCD% -- esta função vai transformar o numero binário em $5$6 num número bcd e escrevê-lo no LCD, além disso o valor bcd é retornado em $2$3$4, o valor é escrito começando pelo endereço $4 do LCD
	J %inicio%  --loop infinito no fim, espera que usuario envie novo numero.
----- SUB ROTINA MULTIPLICA -----
-- Função que multiplica os argumentos $2 e ($4$3) e salva em ($4$3)
multiplica: 	SW  $15,0($13) -- salva o endereco de retorno na pilha
		SUB $13,$1 -- subtrai um do apontador da pilha
		HAB -- re-habilita interrupções
		AND $7,$0 --
		OR  $7,$2 -- cópia de n-1 em $7
		AND $8,$0
		OR  $8,$3 -- cópia de LSW em $8
		AND $9,$0
		OR  $9,$4 -- cópia de MSW em $9
repete:		ADD $3,$8 -- soma no LSW
		ADD $4,$9 -- soma no MSW
		SUB $7,$1 -- subtrai 1 de n-1
		BEQ $7,$1,%retorna% -- repete o procedimento até $7=1 (soma n-1 vezes o valor de $3$4)
		J %repete%
retorna:	LW  $15,1($13) -- recupera o endereco de retorno da pilha		
		ADD $13,$1 -- adiciona um no apontador da pilha
		JR  $15 -- retorna para o ponto de chamada da função
---------------------------------
----- SUB ROTINA ESCREVELCD -----
-- Função que escreve no endereço $2 da ram do LCDDriver, presente na porta $3 a informação em $4
escrevelcd:	SW  $15,0($13) -- salva o endereco de retorno na pilha
		SUB $13,$1 -- subtrai um do apontador da pilha
		HAB -- re-habilita interrupções
		LIW $5,255 -- mascara de 1 byte menos significativo
		AND $6,$0
		OR  $6,$2
		SHL $6,8
		AND $4,$5 -- aplica mascara na info para garantir que nao passa de 1 byte
		OR  $6,$4 -- Data = 'a'
		SW  $6,0($3) -- escreve na portaLCD		
		LIW $5,16384 -- Wen = 1, others = 0
		OR  $6,$5 -- Wen = 1
    		SW  $6,0($3) -- escreve na portaLCD, ordenando escrita na RAM do LCDDriver
		LW  $15,1($13) -- recupera o endereco de retorno da pilha
		ADD $13,$1 -- adiciona um no apontador da pilha
		JR  $15 -- retorna para o ponto de chamada da função
---------------------------------
----- SUB ROTINA PrintNumLCD -----
-- Função que escreve, em decimal, o valor binário presente em  $5$6, começando a escrita no endereço $4 do LCD
PrintNumLCD:	SW  $15,0($13) -- salva o endereco de retorno na pilha
		SUB $13,$1 -- subtrai um do apontador da pilha
		HAB -- re-habilita interrupções
		SW  $10,0($14) -- salva o registrador $10 pois eh do modo "saved"
		ADD $14,$1 -- incrementa o frame pointer
		SW  $11,0($14) -- salva o registrador $11 pois eh do modo "saved"
		ADD $14,$1 -- incrementa o frame pointer
		SW  $12,0($14) -- salva o registrador $12 pois eh do modo "saved"
		ADD $14,$1 -- incrementa o frame pointer
		AND $10,$0
		OR  $10,$4 -- $7 passa a guardar o endereço inicial provisoriamente pois eh do tipo "saved" (isto evitará que bintobcd sobrescreva)
		JAL %bintobcd% -- esta função vai transformar o numero binário em $5$6 num número bcd em $2,$3,$4
		SW  $2,0($14) -- empilha na memória pois precisaremos retornar este valor no final da função
		ADD $14,$1 -- incrementa o frame pointer
		SW  $3,0($14) -- empilha na memória pois precisaremos retornar este valor no final da função
		ADD $14,$1 -- incrementa o frame pointer
		SW  $4,0($14) -- empilha na memória pois precisaremos retornar este valor no final da função
		ADD $14,$1 -- incrementa o frame pointer
		LIW $8,15 -- vai servir de mascara para separar os digitos BCD, começamos pelo menos significativo de todos
		LIW $9,48 -- zero em ASCII
		AND $7,$0
		OR  $7,$10 -- $7 passa a ser o endereço
		AND $10,$0
		OR  $10,$4
		AND $10,$8
		ADD $10,$9
		SW  $10,0($14) -- empilha na memória para uso posterior
		ADD $14,$1 -- incrementa o frame pointer
		ROL $8,4 -- mascara para pegar o próximo dígito	
		AND $10,$0
		OR  $10,$4
		AND $10,$8
		SHR $10,4
		ADD $10,$9
		SW  $10,0($14) -- empilha na memória para uso posterior
		ADD $14,$1 -- incrementa o frame pointer
		ROL $8,4 -- mascara para pegar o próximo dígito	
		AND $10,$0
		OR  $10,$4
		AND $10,$8
		SHR $10,8
		ADD $10,$9
		SW  $10,0($14) -- empilha na memória para uso posterior
		ADD $14,$1 -- incrementa o frame pointer
		ROL $8,4 -- mascara para pegar o próximo dígito	
		AND $10,$0
		OR  $10,$4
		AND $10,$8
		SHR $10,12
		ADD $10,$9
		SW  $10,0($14) -- empilha na memória para uso posterior
		ADD $14,$1 -- incrementa o frame pointer
		ROL $8,4 -- mascara para pegar o próximo dígito	
		AND $10,$0
		OR  $10,$3
		AND $10,$8
		ADD $10,$9
		SW  $10,0($14) -- empilha na memória para uso posterior
		ADD $14,$1 -- incrementa o frame pointer
		ROL $8,4 -- mascara para pegar o próximo dígito	
		AND $10,$0
		OR  $10,$3
		AND $10,$8
		SHR $10,4
		ADD $10,$9
		SW  $10,0($14) -- empilha na memória para uso posterior
		ADD $14,$1 -- incrementa o frame pointer
		ROL $8,4 -- mascara para pegar o próximo dígito	
		AND $10,$0
		OR  $10,$3
		AND $10,$8
		SHR $10,8
		ADD $10,$9
		SW  $10,0($14) -- empilha na memória para uso posterior
		ADD $14,$1 -- incrementa o frame pointer
		ROL $8,4 -- mascara para pegar o próximo dígito	
		AND $10,$0
		OR  $10,$3
		AND $10,$8
		SHR $10,12
		ADD $10,$9
		SW  $10,0($14) -- empilha na memória para uso posterior
		ADD $14,$1 -- incrementa o frame pointer
		ROL $8,4 -- mascara para pegar o próximo dígito	
		AND $10,$0
		OR  $10,$2
		AND $10,$8
		ADD $10,$9
		SW  $10,0($14) -- empilha na memória para uso posterior
		ADD $14,$1 -- incrementa o frame pointer
		ROL $8,4 -- mascara para pegar o próximo dígito	
		AND $10,$0
		OR  $10,$2
		AND $10,$8
		SHR $10,4
		ADD $10,$9
		SW  $10,0($14) -- empilha na memória para uso posterior
		ADD $14,$1 -- incrementa o frame pointer
		AND $2,$0
		OR  $2,$7 -- endereço que foi passado como argumento
		LIW $3,65502 -- endereco da porta LCD: ['-' 15][Wen 14][RAMAddr 13:8][Data 7:0]	
		SUB $14,$1 -- decrementa o frame pointer		
		LW  $4,0($14) -- recupera um digito da memória (pilha LIFO)
		JAL %escrevelcd% -- escrever $4 no endereco $2 do lcd presente em $3
		ADD $2,$1
		SUB $14,$1 -- decrementa o frame pointer		
		LW  $4,0($14) -- recupera um digito da memória (pilha LIFO)
		JAL %escrevelcd% -- escrever $4 no endereco $2 do lcd presente em $3
		ADD $2,$1
		SUB $14,$1 -- decrementa o frame pointer		
		LW  $4,0($14) -- recupera um digito da memória (pilha LIFO)
		JAL %escrevelcd% -- escrever $4 no endereco $2 do lcd presente em $3
		ADD $2,$1
		SUB $14,$1 -- decrementa o frame pointer		
		LW  $4,0($14) -- recupera um digito da memória (pilha LIFO)
		JAL %escrevelcd% -- escrever $4 no endereco $2 do lcd presente em $3
		ADD $2,$1
		SUB $14,$1 -- decrementa o frame pointer		
		LW  $4,0($14) -- recupera um digito da memória (pilha LIFO)
		JAL %escrevelcd% -- escrever $4 no endereco $2 do lcd presente em $3
		ADD $2,$1
		SUB $14,$1 -- decrementa o frame pointer		
		LW  $4,0($14) -- recupera um digito da memória (pilha LIFO)
		JAL %escrevelcd% -- escrever $4 no endereco $2 do lcd presente em $3
		ADD $2,$1
		SUB $14,$1 -- decrementa o frame pointer		
		LW  $4,0($14) -- recupera um digito da memória (pilha LIFO)
		JAL %escrevelcd% -- escrever $4 no endereco $2 do lcd presente em $3
		ADD $2,$1
		SUB $14,$1 -- decrementa o frame pointer		
		LW  $4,0($14) -- recupera um digito da memória (pilha LIFO)
		JAL %escrevelcd% -- escrever $4 no endereco $2 do lcd presente em $3
		ADD $2,$1
		SUB $14,$1 -- decrementa o frame pointer		
		LW  $4,0($14) -- recupera um digito da memória (pilha LIFO)
		JAL %escrevelcd% -- escrever $4 no endereco $2 do lcd presente em $3
		ADD $2,$1
		SUB $14,$1 -- decrementa o frame pointer		
		LW  $4,0($14) -- recupera um digito da memória (pilha LIFO)
		JAL %escrevelcd% -- escrever $4 no endereco $2 do lcd presente em $3
		SUB $14,$1 -- decrementa o frame pointer		
		LW  $4,0($14) -- recupera $4 retornado anteriormente por bintobcd da memória
		SUB $14,$1 -- decrementa o frame pointer		
		LW  $3,0($14) -- recupera $3 retornado anteriormente por bintobcd da memória
		SUB $14,$1 -- decrementa o frame pointer		
		LW  $2,0($14) -- recupera $2 retornado anteriormente por bintobcd da memória
		SUB $14,$1 -- decrementa o frame pointer		
		LW  $12,0($14) -- recupera o registrador $11 pois eh do modo "saved"
		SUB $14,$1 -- decrementa o frame pointer		
		LW  $11,0($14) -- recupera o registrador $10 pois eh do modo "saved"
		SUB $14,$1 -- decrementa o frame pointer		
		LW  $10,0($14) -- recupera o registrador $10 pois eh do modo "saved"		
		LW  $15,1($13) -- recupera o endereco de retorno da pilha
		ADD $13,$1 -- adiciona um no apontador da pilha
		JR  $15 -- retorna para o ponto de chamada da função
-----------------------------------------
----- SUB ROTINA QUE CONVERTE NUMEROS BINÁRIOS PARA BCD -----
-- Função que converte o valor binário de 32 bits em ($5$6) num valor BCD equivalente em ($2$3$4)
bintobcd:	SW  $15,0($13) -- salva o endereco de retorno na pilha
		SUB $13,$1 -- subtrai um do apontador da pilha
		HAB -- re-habilita interrupções
		SW  $10,0($14) -- salva o registrador $10 pois eh do modo "saved"
		ADD $14,$1 -- incrementa o frame pointer
		SW  $11,0($14) -- salva o registrador $11 pois eh do modo "saved"
		ADD $14,$1 -- incrementa o frame pointer
		SW  $12,0($14) -- salva o registrador $12 pois eh do modo "saved"
		ADD $14,$1 -- incrementa o frame pointer
		LIW $12,29 -- laço principal sera executado 30 vezes
		AND $2,$0
		AND $3,$0
		AND $4,$0
		JAL %supershiftleft% -- com certeza não vai precisar corrigir nada ainda...
		JAL %supershiftleft% -- com certeza não vai precisar corrigir nada ainda...
		JAL %supershiftleft%
bintobcdfor:	AND $9,$0
		OR  $9,$4
		JAL %corrigepesos%
		AND $4,$0
		OR  $4,$9
		AND $9,$0
		OR  $9,$3
		JAL %corrigepesos%
		AND $3,$0
		OR  $3,$9
		AND $9,$0
		OR  $9,$2
		JAL %corrigepesos%
		AND $2,$0
		OR  $2,$9
		SUB $12,$1
		JAL %supershiftleft%
		BEQ $12,$0,%retornabcd%
		J   %bintobcdfor%
-- hora de retornar...
retornabcd:	SUB $14,$1 -- decrementa o frame pointer		
		LW  $12,0($14) -- recupera o registrador $11 pois eh do modo "saved"
		SUB $14,$1 -- decrementa o frame pointer		
		LW  $11,0($14) -- recupera o registrador $10 pois eh do modo "saved"
		SUB $14,$1 -- decrementa o frame pointer		
		LW  $10,0($14) -- recupera o registrador $10 pois eh do modo "saved"
		LW  $15,1($13) -- recupera o endereco de retorno da pilha
		ADD $13,$1 -- adiciona um no apontador da pilha
		JR  $15 -- retorna para o ponto de chamada da função
---------------
----- SUB SUB ROTINA DE SHIFT ----
-- Função que desloca 1 bit para a esquerda o "super-registrador" composto por $2,$3,$4,$5,$6
supershiftleft:	SW  $15,0($13) -- salva o endereco de retorno na pilha
		SUB $13,$1 -- subtrai um do apontador da pilha
		HAB -- re-habilita interrupções
		AND $7,$0
		OR  $7,$3
		SHR $7,15
		SHL $2,1
		OR  $2,$7
		AND $7,$0
		OR  $7,$4
		SHR $7,15
		SHL $3,1
		OR  $3,$7
		AND $7,$0
		OR  $7,$5
		SHR $7,15
		SHL $4,1
		OR  $4,$7
		AND $7,$0
		OR  $7,$6
		SHR $7,15
		SHL $5,1
		OR  $5,$7
		SHL $6,1
		LW  $15,1($13) -- recupera o endereco de retorno da pilha
		ADD $13,$1 -- adiciona um no apontador da pilha
		JR  $15 -- retorna para o ponto de chamada da função
--------------- 
----- SUB SUB ROTINA DE CORREÇÃO DOS PESOS ----
-- Função que implementa a correção de pesos sobre o registrador $9. Esta função precisa que se mantenha intacto o conteúdo do registrador $7
corrigepesos:	SW  $15,0($13) -- salva o endereco de retorno na pilha
		SUB $13,$1 -- subtrai um do apontador da pilha
		HAB -- re-habilita interrupções
		LIW $11,3 -- constante a ser adicionada para correções
		LIW $7,5 -- constante de comparação
----		
bcdok0:		LIW $10,15--7 -- mascara para pegar apenas os tres primeiros bits
		AND $8,$0
		OR  $8,$9
		AND $8,$10 -- aplica a mascara
		SLT $8,$7 -- verifica se $8 é menor que 5
		BEQ $8,$0,%corrige1% -- se o $8 não for menor que 5, precisamos corrigir este digito...
		J %bcdok1%
corrige1:	LIW $10,15 -- mascara para pegar apenas os 4 primeiros bits
		AND $8,$0
		OR  $8,$9
		AND $8,$10 -- aplica a mascara
		ADD $8,$11 -- adiciona 3
		NOR $10,$10 -- inverte a mascara
		AND $9,$10 -- aplica a mascara sobre o registrador original
		OR  $9,$8 -- coloca o valor corrigido
--		J %bcdok0% -- se certifica que o erro foi corrigido ou se precisa repetir o processo
----
bcdok1:		LIW $10,240--112 -- mascara para pegar apenas o segundo digito bcd
		AND $8,$0
		OR  $8,$9
		AND $8,$10 -- aplica a mascara
		SHR $8,4 -- desloca para a porcao menos significativa
		SLT $8,$7 -- verifica se $8 é menor que 5
		BEQ $8,$0,%corrige2% -- se o $8 não for menor que 5, precisamos corrigir este digito...
		J %bcdok2%
corrige2:	LIW $10,240 -- mascara para pegar apenas o segundo digito bcd
		AND $8,$0
		OR  $8,$9
		AND $8,$10 -- aplica a mascara
		SHR $8,4
		ADD $8,$11 -- adiciona 3
		SHL $8,4
		NOR $10,$10 -- inverte a mascara
		AND $9,$10 -- aplica a mascara sobre o registrador original
		OR  $9,$8 -- coloca o valor corrigido
--		J %bcdok1% -- se certifica que o erro foi corrigido ou se precisa repetir o processo
----
bcdok2:		LIW $10,3840--1792 -- mascara para pegar apenas o terceiro digito bcd
		AND $8,$0
		OR  $8,$9
		AND $8,$10 -- aplica a mascara
		SHR $8,8 -- desloca para a porcao menos significativa
		SLT $8,$7 -- verifica se $8 é menor que 5
		BEQ $8,$0,%corrige3% -- se o $8 não for menor que 5, precisamos corrigir este digito...
		J %bcdok3%
corrige3:	LIW $10,3840 -- mascara para pegar apenas o terceiro digito bcd
		AND $8,$0
		OR  $8,$9
		AND $8,$10 -- aplica a mascara
		SHR $8,8
		ADD $8,$11 -- adiciona 3
		SHL $8,8
		NOR $10,$10 -- inverte a mascara
		AND $9,$10 -- aplica a mascara sobre o registrador original
		OR  $9,$8 -- coloca o valor corrigido
--		J %bcdok2% -- se certifica que o erro foi corrigido ou se precisa repetir o processo
----
bcdok3:		LIW $10,61440--28672 -- mascara para pegar apenas o quarto digito bcd
		AND $8,$0
		OR  $8,$9
		AND $8,$10 -- aplica a mascara
		SHR $8,12 -- desloca para a porcao menos significativa
		SLT $8,$7 -- verifica se $8 é menor que 5
		BEQ $8,$0,%corrige4% -- se o $8 não for menor que 5, precisamos corrigir este digito...
		J %bcdok4%
corrige4:	LIW $10,61440 -- mascara para pegar apenas o quarto digito bcd
		AND $8,$0
		OR  $8,$9
		AND $8,$10 -- aplica a mascara
		SHR $8,12
		ADD $8,$11 -- adiciona 3
		SHL $8,12
		NOR $10,$10 -- inverte a mascara
		AND $9,$10 -- aplica a mascara sobre o registrador original
		OR  $9,$8 -- coloca o valor corrigido
--		J %bcdok3% -- se certifica que o erro foi corrigido ou se precisa repetir o processo
----		
bcdok4:		LW  $15,1($13) -- recupera o endereco de retorno da pilha
		ADD $13,$1 -- adiciona um no apontador da pilha
		JR  $15 -- retorna para o ponto de chamada da função
-----------------------------------------
------ Caso ocorra carry-out em $3 ------
.address 4049 --definição do vetor de int. de carry
            J %subcarry%
.address 2048 -- valor qualquer. tou colocando na parte alta da memoria pra nao ter risco do programa sobrescrever essa parte.
subcarry:	SW  $15,0($13) -- salva o endereco de retorno na pilha
		SUB $13,$1 -- subtrai um do apontador da pilha
		HAB -- re-habilita interrupções
		ADD $4,$1 --caso haja carry out em $3, adiciona-se 1 a $4.
		LW  $15,1($13) -- recupera o endereco de retorno da pilha
		ADD $13,$1 -- adiciona um no apontador da pilha
		JR  $15 -- retorna para o ponto de chamada da função
