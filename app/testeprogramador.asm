.constant  	EndVetorHabInterrupt	= 65488 -- 16#FFD0#
.constant   EndPortaA		    	= 65489 -- 16#FFD1#
.constant	  EndPortaB	      		= 65492 -- 16#FFD4#
.constant	  EndPortaC	      		= 65495 -- 16#FFD7# 
.constant   EndPortaD	      		= 65503 -- 16#FFDF# 
.constant	  EndPortaE	      		= 65506 -- 16#FFE2#
inicio: LIW $2,%EndVetorHabInterrupt%
		    SW $0,0($2)
		    LW $3,1($2)
		    LIW $2,%EndPortaD%
		    SW $3,0($2)
		    J %inicio%
