#!/usr/bin/env ruby
# generated by org-babel-tangle
# [[file:~/Documentos/anem/anem16/assembler/assembler.org::*Convers%20o][converte]]
entrada = IO.new(0,'r')
contador=0
endereco_num = 0
endereco_comeca = '0000'
codigo_linha = ''
soma = 0

entrada.each do |linha|
  endereco,codigo = linha.split("\t")
  if (contador == 16) || (endereco_num + contador/2 != endereco.to_i(2))
    checksum = (256 - (soma + contador))%256
    puts ":#{format("%02X",contador)}#{endereco_comeca}00#{codigo_linha}#{format("%02X",checksum)}"
    endereco_num = endereco.to_i(2)
    endereco_comeca=format("%04X",endereco_num)
    soma = (endereco_num/256 + endereco_num%256)%256
    contador = 0
    #soma = 0
    codigo_linha = ''
  end

  codigo_num = codigo.to_i(2)
  codigo_linha = codigo_linha + format("%04X",codigo_num)
  soma = (soma + codigo_num/256 + codigo_num%256)%256
  contador +=2
end

unless contador == 0
  checksum = (256 - (soma + contador))%256
  puts ":#{format("%02X",contador)}#{endereco_comeca}00#{codigo_linha}#{format("%02X",checksum)}"
end
puts ":00000001FF"
# converte ends here
