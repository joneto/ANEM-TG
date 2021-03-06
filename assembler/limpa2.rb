#!/usr/bin/env ruby
# generated by org-babel-tangle
# [[file:~/Documentos/anem/anem16/assembler/assembler.org::*Limpeza][limpa]]
entrada = IO.new(0,'r')
NOP = /NOP/
LIW_cons = /LIW\s+\$(\d{1,2}),\s*(%\w+%)/
LIW_imm = /LIW\s+\$(\d{1,2}),\s*(\d+)/
indice = 0
entrada.each do |linha|
  linha.sub!( /--.*$/ , '')
  linha.upcase!
  linha.gsub!(NOP,'ADD $0,$0')
  linha.gsub!(LIW_imm){"LIU $#{$1}, #{$2.to_i/256}\nLIL $#{$1}, #{$2.to_i%256}"}
  linha.gsub!(LIW_cons){"LIU $#{$1}, #{$2}U\nLIL $#{$1}, #{$2}L"}
  linha.strip!
  puts linha unless linha.empty?
end
# limpa ends here
