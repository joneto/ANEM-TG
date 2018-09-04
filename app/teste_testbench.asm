---------------------------------------------------------
-- Organização dos registradores para este software:
-- $0 -> 0 (hard), $1 -> 1 (soft)
-- $2,$3,$4,$5 -> área de troca de informações com subrotinas (argumentos e retorno): "temporários"
-- $6,$7, -> "temporários", uma função pode escrever neles sem antes salvá-los
-- $8 -> endereços contantes
-- $9,$10,$11,$12 -> "saved"
-- $13 -> stack pointer, "saved"
-- $14 -> data pointer, "saved"
-- $15 -> return address, "empilhável"
-- variaveis
.constant	FLOAT_1	=	0
---------------------------------------------------------
	LIW $1,1
	LIW $2,16368 -- x"3FF0"
	LIW $8,%FLOAT_1%
	SW $2,0($8)
	SW $0,1($8)
	SW $0,2($8)
	SW $0,3($8) -- numero 1 em ponto flutuante eh salvo na memoria
	FMLD $8 -- carrega o numero 1 em ponto flutuante no banco de registradores da FPU
	FSLD $0 -- duplica o TOS
	FADD	-- 1.0 + 1.0 = 2.0 -> TOS

