-- Programa que calcula o fatorial do argumento (n) carregado em $2 a partir de um barramento
-- Valor n! sera gravado em dois barramentos de saida
-- São usados os        
        LIW $5,2 -- habilita apenas excecao para carry out
        LIU $6,255 --FF
        LIL $6,208 --D0      
        SW $5,0($6) -- grava $5 no registrador VetorHabInt (endereco FFD1)
	    LIL $6,209
        AND $5,$0 -- zera $5
        NOR $5,$0 -- $5 = 111...111
        SW $5,1($6) -- configura como entrada portaa
    	SW $0,4($6) -- configura como saida portab
	    SW $0,7($6) -- configura como saida portac
inicio: LIW $1,1 -- numero 1 eh carregado em $1 para incrementar e decrementar
       -- LIW $2,10 -- n eh carregado em $2 (depois mudar para ler das chaves)
    	LW $2,0($6) --le a entrada das chaves
        AND $3,$0 -- zeramos $3 - LSW da resposta
        AND $4,$0 -- zeramos $4 - MSW da resposta
        ADD $3,$2 --salva n em $3 para ser gravado na saída.
        BEQ $3,$1,%sai% -- se n=1, resposta eh 1 e termina
        BEQ $3,$0,%sai% -- se n=0, resposta eh 1 e termina
        J %loop% -- caso contrario, calcula o fatorial
sai:    J %fim%
loop:   SUB $2,$1 -- n <= n-1
        BEQ $2,$1,%fim% -- se $2 ja eh 1, entao termina
        JAL %multiplica% -- chama a subrotina que ira retornar $4$3*(n-1) em $4$3
        --SUB $2,$1 -- n <= n-1
        J %loop% -- se $2 ainda nao eh 1, entao repete
fim:    SW $4,3($6) -- Grava o MSW
        SW $3,6($6) -- Grava o LSW
	    J %inicio%  --loop infinito no fim
----- SUB ROTINA MULTIPLICA -----
multiplica: AND $14,$0
	        OR  $14,$15
	        HAB -- habilita as interrupções para pegar um carry-out.
	        AND $7,$0 --
            OR  $7,$2 -- cópia de n-1 em $7
            AND $5,$0
            OR  $5,$3 -- cópia de LSW em $5
            AND $8,$0
            OR  $8,$4 -- cópia de MSW em $8
repete:     ADD $3,$5
	        ADD $4,$8
            SUB $7,$1 -- subtrai 1 de n-1
	        HAB -- habilita as interrupções para pegar um carry-out.
            BEQ $7,$1,1 -- repete o procedimento até zerar $7
            J %repete%
            JR $14 -- terminou a multiplicacao, retorna ao ponto onde a sub-rotina foi chamada.
------ Caso ocorra carry-out em $3 ------
.address 4049 --definição do vetor de int. de carry
            J %subcarry%
.address 100 -- valor qualquer.
subcarry:   ADD $4,$1 --caso haja carry out em $3, adiciona-se 1 a $4.
            JR $15
