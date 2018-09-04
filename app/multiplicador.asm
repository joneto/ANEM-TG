-- Multiplica $2 por $3
-- $1 é 1 para subtrair $3 dele
        LIU	$1,0 --desnecessario
        LIL $1,1     --Carrega $1 com 1
        LIU $2,0     
        LIL $2,5     --carrega $2 com 5   
        LIU $3,0
        LIL	$3,15 --carrega $3 com 15
-- loop do multiplicador
loop:   ADD $4,$2
        SUB $3,$1
        BEQ $3,$0,%fim%
        J %loop%
fim:    SW $4,0($0) --salva o resultado
