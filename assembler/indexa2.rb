#!/usr/bin/env ruby
# generated by org-babel-tangle
# [[file:~/Documentos/anem/anem16/assembler/assembler.org::*Indexa%20o][indexa]]
entrada = IO.new(0,'r')
labels = Hash.new('0')
indice = 0
linhas = entrada.collect do |linha|
  if linha.match(/^\..*/)
    case linha
      when /\.ADDRESS\s+(\d+)/ then
        indice = $1.to_i
      when /\.CONSTANT\s+(\w+)\s*=\s*(\d+)/ then
        labels[$1] = $2
      else
        print linha +"- Comando invalido\n"
        $stderr.puts "Comando Invalido"
    end
  else
    label = nil
    label,linha = linha.split(':') if linha.include?(':')
    labels[label.strip] = indice unless label.nil?
    linha.strip!
    unless linha.empty?
      saida = [indice,linha]
      indice += 1
    end
  end
  saida
end
linhas.compact!
puts ".LABELS"
labels.each do |label,valor|
  puts "#{label}\t#{valor}"
end
puts ".CODE"
linhas.each do |indice,linha|
  puts "#{indice}\t#{linha}"
end
# indexa ends here