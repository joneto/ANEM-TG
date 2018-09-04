#!/usr/bin/env ruby

require 'rubygems'

entrada = IO.new(0,'r')
contador=0
endereco_num = 0
endereco_comeca = '0000'
codigo_linha = ''
soma = 0

entrada.each do |linha|
  if linha.match(/([01]{8})([01]{8})\s+([01]{8})([01]{8})/)
    addr_m = $1.to_i(2)
    addr_l = $2.to_i(2)
    code_m = $3.to_i(2)
    code_l = $4.to_i(2)
    texto = addr_m.chr << addr_l.chr << code_m.chr << code_l.chr
    print texto
    for i in 1..80000 do
    end

  end
end

