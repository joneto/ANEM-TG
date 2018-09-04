.constant  	EndVetorHabInterrupt	= 65488 -- 16#FFD0#
.constant   EndPortaA		    	= 65489 -- 16#FFD1#
.constant	EndPortaB	      		= 65492 -- 16#FFD4#
.constant	EndPortaC	      		= 65495 -- 16#FFD7# 
.constant   EndPortaD	      		= 65503 -- 16#FFDF# 
.constant	EndPortaE	      		= 65506 -- 16#FFE2#
		LIW $4,0 -- primeiro endereco da memoria
		LIW $1,1
		LIW $2,%EndVetorHabInterrupt%
		SW $0,0($2) -- desabilita as interrupcoes
		LIW $6,%EndPortaD%
		AND $5,$0
loop:	SW $5,0($6)
		LW $3,1($2)
		BEQ $3,$0,%loop%
		SW $3,0($4)
		AND $5,$0
		LW $5,0($4)
		ADD $4,$1
		LIW $2,%EndVetorHabInterrupt%
loop2:	LW $3,1($2)
		BEQ $3,$0,%reset%
		J %loop2%
reset:	J %loop%