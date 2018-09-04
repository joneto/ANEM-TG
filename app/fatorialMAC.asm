-- Programa que calcula o fatorial do argumento (n) carregado em $2 a partir de um barramento
-- Valor n! sera gravado num barramento de saida
-- São usados os        
        LIW $5,4 -- habilita apenas excecao para mac result
        LIW $7,65498 -- endereco do primeiro registrador do mac
        LIU $6,255 --FF
        LIL $6,208 --D0      
        SW $5,0($6) -- grava $5 no registrador VetorHabInt (endereco FFD0)
	    LIL $6,209
	    SW $0,4($6) -- configura como saida portab
inicio: LIW $1,1 -- numero 1 eh carregado em $1 para incrementar e decrementar
--	    LIW $2,8
        LW $2,0($6) -- carrega numero da porta a
        AND $3,$0 -- zeramos $3 - n
        ADD $3,$2 --salva n em $3 para ser gravado na saída.
        BEQ $3,$1,%sai% -- se n=1, resposta eh 1 e termina
        BEQ $3,$0,%um% -- se n=0, resposta eh 1 e termina
        J %loop% -- caso contrario, calcula o fatorial
um:     ADD $3,$1
sai:    J %fim%
loop:   SUB $2,$1 -- n <= n-1  
        SW $3,4($7)
        SW $2,0($7)
espera: J %espera% -- espera a resposta ficar pronta no mac
continua: LW $3,5($7)
        HAB              
        BEQ $2,$1,%fim% -- se $2 ja eh 1, entao termina        
        J %loop% -- se $2 ainda nao eh 1, entao repete
fim:    SW $3,3($6) -- Grava a resposta
	    J %inicio%  --loop infinito no fim
------ Quando resultado do MAC esta pronto ------
.address 4050 -- endereco da interrupcao do mac
            J %continua%
