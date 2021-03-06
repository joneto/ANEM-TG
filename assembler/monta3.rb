#!/usr/bin/env ruby
# -*- coding: iso-8859-1 -*-
# generated by org-babel-tangle
# [[file:~/Documentos/anem/anem16/assembler/assembler.org::*Montagem][monta]]
$labels = Hash.new('-')
codigo = []
mode = nil
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
def to_bin(valor,n_bits)
  temp=''
  (n_bits-1).downto(0) do |n|
    temp += valor.to_i[n].to_s
  end
  return temp
end
entrada = IO.new(0,'r')
entrada.each do |linha|
  if linha.match(/^\.([A-Z]+)/)
    mode = $1
  else
    ent1,ent2 = linha.split("\t")
    case mode
     when 'LABELS'
      $labels[ent1] = ent2
    when 'CODE'
      codigo << [ent1,ent2]
    end
  end
end
saida = codigo.collect do |indice, linha|
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
  else to_bin(indice,16)+"\t"+"Não corresponde a nenhuma instrução ou instrução mal-formatada."
  $stderr.puts "Instrução inexistente ou instrução mal-formatada."
  end
end

puts saida
# monta ends here
