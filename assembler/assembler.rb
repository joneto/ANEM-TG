# -*- coding: utf-8 -*-

# Constantes de pseudo instruções
NOP = /NOP/
LIW_cons = /LIW\s+\$(\d{1,2}),\s*(%\w+%)/
LIW_imm = /LIW\s+\$(\d{1,2}),\s*(\d+)/

nomeArquivo = ARGV[0]

entrada = File.new(nomeArquivo+".asm",'r')

arquivoIndexado = []

nLinha = 0
entrada.each do |linha|
  nLinha = nLinha+1
  linha2 =''
  linha.sub!( /--.*$/ , '')
  linha.upcase!
  linha.gsub!(NOP,'ADD $0,$0')
  if linha.match(LIW_imm) then
    linha  = "LIU $#{$1}, #{$2.to_i/256}"
    linha2 = "LIL $#{$1}, #{$2.to_i%256}"
  end
#  linha.gsub!(LIW_imm){"LIU $#{$1}, #{$2.to_i/256}\nLIL $#{$1}, #{$2.to_i%256}"}
  if linha.match(LIW_cons) then
    linha  = "LIU $#{$1}, #{$2}U"
    linha2 = "LIL $#{$1}, #{$2}L"
end
  #  linha.gsub!(LIW_cons){"LIU $#{$1}, #{$2}U\nLIL $#{$1}, #{$2}L"}
  linha.strip!
#  puts linha unless linha.empty?
  arquivoIndexado.push([nLinha, linha]) unless linha.empty?
  arquivoIndexado.push([nLinha, linha2]) unless linha2.empty?
end

entrada.close()
saida =File.new(nomeArquivo+".clean","w")
arquivoIndexado.each do |linha|
  saida.puts "#{linha[0].to_s}\t#{linha[1]}"
end
saida.close()

# limpa ends here
# indexa
$labels = Hash.new('0')
indice = 0
codigo = arquivoIndexado.collect do |linha|
  if linha[1].match(/^\..*/)
    case linha[1]
      when /\.ADDRESS\s+(\d+)/ then
        indice = $1.to_i
      when /\.CONSTANT\s+(\w+)\s*=\s*(\d+)/ then
        $labels[$1] = $2
      else
        puts linha[1] +"- Comando invalido ("+linha[0].to_s+")\n"
#        $stderr.puts "Comando Invalido"
    end
  else
    label = nil
    label,linha[1] = linha[1].split(':') if linha[1].include?(':')
    $labels[label.strip] = indice unless label.nil?
    linha[1].strip!
    unless linha[1].empty?
      saida = [indice,linha[0],linha[1]]
      indice += 1
    end
  end
  saida
end
codigo.compact!

saida = File.new(nomeArquivo+".ind","w")
saida.puts ".LABELS"
$labels.each do |label,valor|
  saida.puts "#{label}\t#{valor}"
end
saida.puts ".CODE"
codigo.each do |indice,nLinha,linha|
  saida.puts "#{indice}\t#{nLinha}\t#{linha}"
end
saida.close()
# indexa ends here

# monta

# RE constantes
tipoR=/^\s*(A[DN]D|S(UB|LT)|[XN]?OR)\s+\$(\d{1,2}),\s*\$(\d{1,2})\s*$/
tipoS=/^\s*((SH|RO)[RL]|SAR)\s+\$(\d{1,2}),\s*(\d+)\s*$/
tipoJ=/^\s*(J(AL)?)\s+(%?\w+%?)\s*$/
tipoHAB = /^\s*HAB\s*$/
tipoL=/^\s*(LI[LU])\s+\$(\d{1,2}),\s*(\d+|(%\w+%[UL]?))\s*$/
tipoW=/^\s*([SL]W)\s+\$(\d{1,2}),([+-]?\d+)\(\$(\d{1,2})\)\s*$/
tipoBEQ=/^\s*(BEQ)\s+\$(\d{1,2}),\s*\$(\d{1,2}),(%?\w+%?)\s*$/
tipoJR = /^\s*(JR)\s+\$(\d{1,2})\s*$/
tipoF=/^\s*(F((ADD|SUBR?|MUL|DIVR?|A?(SIN|COS)|TAN)P?)|AB(S|P))\s*$/
tipoFx=/^\s*(F((M|S)(LD|STP?)|SX))\s+\$(\d{1,3})\s*$/

# Funções de conversão
def inst_R(comando,reg_a,reg_b)
comandos={"ADD"=>"0010",'SUB'=>"0110",'AND'=>"0000",'OR'=>'0001','XOR'=>'1111','NOR'=>'1100','SLT'=>'0111'}
  opcode='0000'
  ra=to_bin(reg_a.to_i,4)
  rb=to_bin(reg_b.to_i,4)
  func=comandos[comando]
  return opcode+ra+rb+func
end

def inst_S(comando,reg_a,quantidade)
comandos={"SHL"=>"0010",'SHR'=>"0001",'SAR'=>"0000",'ROL'=>'1000','ROR'=>'0100'}
  opcode='0001'
  ra=to_bin(reg_a.to_i,4)
  shamt=to_bin(quantidade.to_i,4)
  func=comandos[comando]
  return opcode+ra+shamt+func
end

def inst_L(comando,reg_a,bt)
  comandos={"LIU"=>"1100","LIL"=>"1101"}
  opcode=comandos[comando]
  ra=to_bin(reg_a.to_i,4)
  if bt.match(/%(\w+)%U/)
    byte=to_bin($labels[$1].to_i/256,8)
  elsif bt.match(/%(\w+)%L/)
    byte=to_bin($labels[$1].to_i%256,8)
  elsif bt.match(/%(\w+)%L/)
    byte=to_bin($labels[$1].to_i%256,8)
  elsif bt.match(/%(\w+)%/)
    byte=to_bin($labels[$1].to_i,8)
  elsif bt.match(/(\d+)/)
    byte=to_bin(bt.to_i,8)
  else
    byte= "erro"
    $stderr.puts "#{comando} mal formatado."
  end
  return opcode+ra+byte
end

def inst_J(comando,endereco)
  comandos={"J"=>"1000","JAL"=>"1001"}
  opcode=comandos[comando]
  if endereco.match(/%(\w+)%/)
    ende=to_bin($labels[$1].to_i,12)
    return opcode+ende
  elsif endereco.match(/d+/)
    ende=to_bin(endereco.to_i,12)
    return opcode+ende
  else
    return "#{comando} mal formatado."
  end
end

def inst_W(comando,reg_a,reg_b,offset,indice)
comandos={"SW"=>"0100",'LW'=>"0101",'BEQ'=>"0110",'JR'=>'0111'}
  opcode=comandos[comando]
  ra=to_bin(reg_a.to_i,4)
  rb=to_bin(reg_b.to_i,4)
  off=to_bin(offset.to_i,4)
  if offset.match(/%(\w+)%/)
    off=to_bin($labels[$1].to_i-1-indice.to_i,4)
  elsif offset.match(/\d+/)
    off=to_bin(offset.to_i,4)
  else
    off="Erro"
  end
  return opcode+ra+rb+off
end

def inst_F(comando)
opcodes ={"FADD"   => "0010",
          'FADDP'  => "0010",
          'FSUB'   => "0010",
          'FSUBP'  => '0010',
          'FSUBR'  => '0010',
          'FSUBRP' => '0010',
          'FMUL'   => '0010',
          'FMULP'  => '0010',
          'FDIV'   => '0010',
          'FDIVP'  => '0010',
          'FDIVR'  => '0010',
          'FDIVRP' => '0010',
          'FABS'   => '0010',
          'FCHS'   => '0010',
          'FSIN'   => '0011',
          'FSINP'  => '0011',
          'FCOS'   => '0011',
          'FCOSP'  => '0011',
          'FTAN'   => '0011',
          'FTANP'  => '0011',
          'FASIN'  => '0011',
          'FASINP' => '0011',
          'FACOS'  => '0011',
          'FACOSP' => '0011'}

comandos={"FADD"   => "0000",
          'FADDP'  => "0001",
          'FSUB'   => "0010",
          'FSUBP'  => '0011',
          'FSUBR'  => '0110',
          'FSUBRP' => '0111',
          'FMUL'   => '0100',
          'FMULP'  => '0101',
          'FDIV'   => '1000',
          'FDIVP'  => '1001',
          'FDIVR'  => '1010',
          'FDIVRP' => '1011',
          'FABS'   => '1100',
          'FCHS'   => '1101',
          'FSIN'   => '0000',
          'FSINP'  => '0001',
          'FCOS'   => '0010',
          'FCOSP'  => '0011',
          'FTAN'   => '0100',
          'FTANP'  => '0101',
          'FASIN'  => '0110',
          'FASINP' => '0111',
          'FACOS'  => '1000',
          'FACOSP' => '1001'}

  opcode = opcodes[comando]
  func = comandos[comando]
  return opcode+'00000000'+func
end

def inst_Fx(comando,reg)
opcode = '1110'
comandos={'FMLD' =>'0000',
          'FSLD' =>'0001',
          'FMST' =>'0010',
          'FSST' =>'0011',
          'FMSTP'=>'0101',
          'FSSTP'=>'0100',
          'FSX'  =>'0110'}

  func = comandos[comando]
  register = to_bin(reg.to_i,8)
  return opcode+register+func
end

# Função auxiliar para gerar palavras binárias
def to_bin(valor,n_bits)
  temp=''
  (n_bits-1).downto(0) do |n|
    temp += valor.to_i[n].to_s
  end
  return temp
end


codigoBinario = codigo.collect do |indice, nLinha, linha|
#codigo.each do |indice, nLinha, linha|
  case linha
  when tipoR
    to_bin(indice,16)+"\t"+inst_R($1,$3,$4)
  when tipoS
    to_bin(indice,16)+"\t"+inst_S($1,$3,$4)
  when tipoL
    to_bin(indice,16)+"\t"+inst_L($1,$2,$3)
  when tipoJ
    to_bin(indice,16)+"\t"+inst_J($1,$3)
  when tipoW
    to_bin(indice,16)+"\t"+inst_W($1,$2,$4,$3,indice)
  when tipoBEQ
    to_bin(indice,16)+"\t"+inst_W($1,$2,$3,$4,indice)
  when tipoJR
    to_bin(indice,16)+"\t"+inst_W($1,$2,'0','0',indice)
  when tipoHAB
    to_bin(indice,16)+"\t1111000000000000"
  when tipoF
    to_bin(indice,16)+"\t"+inst_F($1)
  when tipoFx
    to_bin(indice,16)+"\t"+inst_Fx($1,$5)
  else to_bin(indice,16)+"\t"+"Instrução inexistente ou mal-formatada. (#{nLinha})"
#  $stderr.puts "Instrução inexistente ou instrução mal-formatada."
  end
end

saida = File.new(nomeArquivo+".bin","w")
codigoBinario.each do |linha|
  saida.puts linha
end
saida.close()

# monta ends here
# converte para .hex

saida = File.new(nomeArquivo+".hex","w")

contador=0
endereco_num = 0
endereco_comeca = '0000'
codigo_linha = ''
soma = 0

codigoBinario.each do |linha|
  endereco,codigo = linha.split("\t")
  if (contador == 16) || (endereco_num + contador/2 != endereco.to_i(2))
    checksum = (256 - (soma + contador))%256
    saida.puts(":#{format("%02X",contador)}#{endereco_comeca}00#{codigo_linha}#{format("%02X",checksum)}")
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
  saida.puts( ":#{format("%02X",contador)}#{endereco_comeca}00#{codigo_linha}#{format("%02X",checksum)}")
end
saida.puts(":00000001FF")
saida.close()
# converte ends here
