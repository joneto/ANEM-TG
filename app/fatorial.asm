-- Programa que calcula o fatorial do argumento (n) carregado em $2
-- Valor n! sera gravado no endereco zero da memoria RAM
            LIU $5,0
            LIL $5,1 -- habilita apenas excecao para overflow
            LIU $6,255
            LIL $6,208        
            SW $5,0($6) -- grava $5 no registrador VetorHabInt (endereco FFD1)
            LIU $1,0
            LIL $1,1 -- numero 1 eh carregado em $1
            LIU $2,0 
            LIL $2,8 -- n eh carregado em $2
            AND $3,$0 -- zeramos $3
            AND $4,$0 -- zeramos $4
            ADD $4,$2 -- n eh copiado em $4
            BEQ $4,$1,2 -- se $4=1, resposta eh 1 e termina
            BEQ $4,$0,1 -- se $4=0, resposta eh 1 e termina
            J %inicio% -- caso contrario, calcula o fatorial
            ADD $3,$1
            J %fim%
inicio:     AND $14,$0 -- zeramos $14 (onde sub-rotina retorna)
            ADD $14,$2 -- carregamos n em $14
loop:       AND $13,$0 -- zeramos $13 (argumento da sub-rotina)
            ADD $13,$14 -- carregamos n em $13
            SUB $2,$1 -- n <= n-1
            AND $12,$0 -- zeramos $12 (argumento da sub-rotina)
            ADD $12,$2 -- $12 <= n-1
            JAL %multiplica% -- chama a subrotina que ira retornar (n)*(n-1) em $14
            BEQ $2,$1,1 -- se $2 ja eh 1, entao termina
            J %loop% -- se $2 ainda nao eh 1, entao repete
            ADD $3,$14 -- resposta eh valor em $14 (retornado pelo ultimo chamado a sub-rotina)
            J %fim%
multiplica: AND $14,$0 -- zeramos $14
repete:     ADD $14,$13 -- soma argumento 2 em $14
            SUB $12,$1 -- subtrai 1 do argumento 1
            BEQ $12,$0,1 -- repete o procedimento enquanto argumento 1 ainda eh nao nulo.
            J %repete%
            JR $15 -- terminou a multiplicacao, retorna ao ponto onde a sub-rotina foi chamada.
fim:        SW $3,0($0)
%4049%:
            JR $15
