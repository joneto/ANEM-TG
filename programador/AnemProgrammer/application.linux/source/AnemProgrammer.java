import processing.core.*; 
import processing.xml.*; 

import processing.serial.*; 
import javax.swing.*; 
import javax.swing.SwingUtilities; 
import javax.swing.filechooser.*; 

import java.applet.*; 
import java.awt.Dimension; 
import java.awt.Frame; 
import java.awt.event.MouseEvent; 
import java.awt.event.KeyEvent; 
import java.awt.event.FocusEvent; 
import java.awt.Image; 
import java.io.*; 
import java.net.*; 
import java.text.*; 
import java.util.*; 
import java.util.zip.*; 
import java.util.regex.*; 

public class AnemProgrammer extends PApplet {






String[] lines;
int index = 0;
PFont fontA;
int tecla = -1;
int modoautomatico = 0;
int progress;
Serial serPorta;
int COMPort;
boolean portChosen = false;
boolean enviarinst = false;
int [] keyIn = new int[3];
int i, keyIndex=0;

int safetycounter=0;
int valorlimite=999999999;
boolean abortrun=false;

boolean B1Over,B2Over,B3Over,B4Over,B5Over,B6Over,B7Over,B8Over;


int topofpage=20;
int linecomp =16;

int tempodeespera=0; // espera, em ms, depois de cada envia

boolean CommandisOk=false;


  //try { 
  //  UIManager.setLookAndFeel(UIManager.getSystemLookAndFeelClassName()); 
  //} catch (Exception e) { 
  //  e.printStackTrace();  
  //}
  final JFileChooser fc = new JFileChooser("~/");


public void setup() {
  size(500, 280+34);
  smooth();
  background(135,165,133);
  noStroke();


  chooseandloadFile();
  
  fontA = loadFont("Ziggurat-HTF-Black-32.vlw");
  
  //noLoop();
}

public void draw() {
  if((portChosen == true) && (abortrun==false)){
    update(mouseX,mouseY);  
    if ((index < lines.length) && (index > -1)) {
      String[] pieces = split(lines[index], '\t');
      if (pieces.length == 2) {
        background(135,165,133);
        fill(255);
        
        textFont(fontA, 20);        
        textAlign(CENTER);
        fill(34,72,12);
        text("Programador serial para o Anem16",width/2,topofpage+0*linecomp);
        fill(255);
        textFont(fontA, 16);
        
        text("Index = " + index,width/2,topofpage+2*linecomp);      
        if(modoautomatico==0)text("(modo manual)",width/2,topofpage+3*linecomp);
        textAlign(LEFT);
        
        text("Progresso:",10,topofpage+5*linecomp);
        progress = (index*370);
        progress /= lines.length-1;
        rectMode(CORNER);
        fill(34,72,12);
        rect(115,topofpage+4*linecomp+3,370,16);
        fill(255-index*255/lines.length,255,255-index*255/lines.length);
        rect(115,topofpage+4*linecomp+3,progress,16);
        fill(255);
        textFont(fontA, 14);
        if((modoautomatico==1)&&(progress<370))text("Taxa: "+nf(frameRate,2,0)+" inst/s",150,topofpage+5*linecomp);
        else if (progress==370)text("Completado!",180,topofpage+5*linecomp);
        textFont(fontA, 16);
        
        int word;
        byte subword,fromanem;
        int fromanemi;
        int k=0;
  
        text("Endere\u00e7o:",10,topofpage+7*linecomp);
        text(pieces[0],10,topofpage+9*linecomp);
        
        word = unbinary(pieces[0]);
        text("Hex: "+hex(word,4),10,topofpage+10*linecomp);
        
        subword = PApplet.parseByte((word & 65280) >> 8); // msb do endereco
        text("MSB: "+nf(subword,3),10,topofpage+11*linecomp);

        CommandisOk=false;
        if((modoautomatico==1) || ((modoautomatico==0) && (enviarinst==true)))while((CommandisOk==false)&&(abortrun==false)){
          serPorta.write(subword); // envia para a serial
          delay(tempodeespera);
          
          safetycounter=0;
          while((serPorta.available() < 1)&&(safetycounter<valorlimite))safetycounter++;
          if (safetycounter==valorlimite)abortrun=true;
          fromanemi = serPorta.read();
          fromanem = PApplet.parseByte(fromanemi & 255);
                              
          if(fromanem==subword){
             serPorta.write(255); // envia "11111111" para a serial, indicando ok
             serPorta.write(255); // envia "11111111" para a serial, indicando ok
             serPorta.write(255); // envia "11111111" para a serial, indicando ok
             CommandisOk=true;
          }
          else{
            serPorta.write(0); // envia "00000000" para a serial, indicando erro, repete a transmissao
            serPorta.write(0); // envia "00000000" para a serial, indicando erro, repete a transmissao
            serPorta.write(0); // envia "00000000" para a serial, indicando erro, repete a transmissao
          }
          delay(tempodeespera);
          
        }
        
        subword = PApplet.parseByte(word & 255); // lsb do endereco
        text("LSB: "+nf(subword,3),10,topofpage+12*linecomp);      

        CommandisOk=false;
        if((modoautomatico==1) || ((modoautomatico==0) && (enviarinst==true)))while((CommandisOk==false)&&(abortrun==false)){
          serPorta.write(subword); // envia para a serial
          delay(tempodeespera);
          
          safetycounter=0;
          while((serPorta.available() < 1)&&(safetycounter<valorlimite))safetycounter++;
          if (safetycounter==valorlimite)abortrun=true;
          fromanemi = serPorta.read();
          fromanem = PApplet.parseByte(fromanemi & 255);
                              
          if(fromanem==subword){
             serPorta.write(255); // envia "11111111" para a serial, indicando ok
             serPorta.write(255); // envia "11111111" para a serial, indicando ok
             serPorta.write(255); // envia "11111111" para a serial, indicando ok
             CommandisOk=true;
          }
          else{
            serPorta.write(0); // envia "00000000" para a serial, indicando erro, repete a transmissao
            serPorta.write(0); // envia "00000000" para a serial, indicando erro, repete a transmissao
            serPorta.write(0); // envia "00000000" para a serial, indicando erro, repete a transmissao
          }
          delay(tempodeespera);  
        }
       
        text("Instru\u00e7\u00e3o:",width/2+20,topofpage+7*linecomp);
        text(pieces[1],width/2+20,topofpage+9*linecomp);
       
        word = unbinary(pieces[1]);
        text("Hex: "+hex(word,4),width/2+20,topofpage+10*linecomp);
        
        subword = PApplet.parseByte((word & 65280) >> 8); // msb da instrucao
        text("MSB: "+nf(subword,3),width/2+20,topofpage+11*linecomp);
        
        CommandisOk=false;
        if((modoautomatico==1) || ((modoautomatico==0) && (enviarinst==true)))while((CommandisOk==false)&&(abortrun==false)){
          serPorta.write(subword); // envia para a serial
          delay(tempodeespera);
          
          safetycounter=0;
          while((serPorta.available() < 1)&&(safetycounter<valorlimite))safetycounter++;
          if (safetycounter==valorlimite)abortrun=true;
          fromanemi = serPorta.read();
          fromanem = PApplet.parseByte(fromanemi & 255);
                              
          if(fromanem==subword){
             serPorta.write(255); // envia "11111111" para a serial, indicando ok
             serPorta.write(255); // envia "11111111" para a serial, indicando ok
             serPorta.write(255); // envia "11111111" para a serial, indicando ok
             CommandisOk=true;
          }
          else{
            serPorta.write(0); // envia "00000000" para a serial, indicando erro, repete a transmissao
            serPorta.write(0); // envia "00000000" para a serial, indicando erro, repete a transmissao
            serPorta.write(0); // envia "00000000" para a serial, indicando erro, repete a transmissao
          }
          delay(tempodeespera);  
        }
        
        subword = PApplet.parseByte(word & 255); // lsb da instrucao
        text("LSB: "+nf(subword,3),width/2+20,topofpage+12*linecomp);
        
        CommandisOk=false;
        if((modoautomatico==1) || ((modoautomatico==0) && (enviarinst==true)))while((CommandisOk==false)&&(abortrun==false)){
          serPorta.write(subword); // envia para a serial
          delay(tempodeespera);
          
          safetycounter=0;
          while((serPorta.available() < 1)&&(safetycounter<valorlimite))safetycounter++;
          if (safetycounter==valorlimite)abortrun=true;
          fromanemi = serPorta.read();
          fromanem = PApplet.parseByte(fromanemi & 255);
                              
          if(fromanem==subword){
             serPorta.write(255); // envia "11111111" para a serial, indicando ok
             serPorta.write(255); // envia "11111111" para a serial, indicando ok
             serPorta.write(255); // envia "11111111" para a serial, indicando ok
             CommandisOk=true;
          }
          else{
            serPorta.write(0); // envia "00000000" para a serial, indicando erro, repete a transmissao
            serPorta.write(0); // envia "00000000" para a serial, indicando erro, repete a transmissao
            serPorta.write(0); // envia "00000000" para a serial, indicando erro, repete a transmissao
          }
          delay(tempodeespera);  
        }
        
        enviarinst = false;
      }
    }
    
    if(B1Over==true)fill(34,130,12);
    else fill(34,72,12);
    rect(10,topofpage+14*linecomp,90,24);
    if(B2Over==true)fill(34,130,12);
    else fill(34,72,12);
    rect(150,topofpage+14*linecomp,80,24);
    if(B3Over==true)fill(34,130,12);
    else fill(34,72,12);
    rect(270,topofpage+14*linecomp,90,24);
    if(B4Over==true || B8Over==true)fill(34,130,12);
    else fill(34,72,12);
    rect(395,topofpage+14*linecomp,90,56);
    if(B6Over==true)fill(34,130,12);
    else fill(34,72,12);
    rect(150,topofpage+16*linecomp,80,24);
    if(B7Over==true)fill(34,130,12);
    else fill(34,72,12);
    rect(270,topofpage+16*linecomp,90,24);
    fill(255);
    text("Avan\u00e7a",20,topofpage+15*linecomp+2);
    text("Volta",165,topofpage+15*linecomp+2);
    text("Envia",290,topofpage+15*linecomp+2);
    text("Enviar",410,topofpage+15*linecomp+2);
    text("Sair",170,topofpage+17*linecomp+2);
    text("Abrir...",282,topofpage+17*linecomp+2);
    text("Tudo",415,topofpage+17*linecomp+2);
    
    if(modoautomatico==1){
      if(index<lines.length)index++;
      else modoautomatico=0;
    }
    //
  }
  else if((portChosen == true) && (abortrun == true)){
    MsgdeErro();
  }
  else{
    background(135,165,133);
    textFont(fontA, 16);
    text("Selecione a porta em que o Anem16 esta conectado:", 10, topofpage+0*linecomp);
    text("(digite o numero e tecle enter)",10,topofpage+1*linecomp);
    textAlign(LEFT);
    for(i=0; i<Serial.list().length; i++){
      text("[" + i + "] " + Serial.list()[i], 10, topofpage+(3+i*1.5f)*linecomp);
    }
  }
}

public void update(int x, int y)
{
  if(( y > topofpage+14*linecomp) && (y < topofpage+14*linecomp+24)){
    if((x>10)&&(x<100))B1Over=true;
    else B1Over=false;
    if((x>150)&&(x<230))B2Over=true;
    else B2Over=false;
    if((x>270)&&(x<360))B3Over=true;
    else B3Over=false;
    if((x>410)&&(x<480))B4Over=true;
    else B4Over=false;
  }
  else if(( y >= topofpage+14*linecomp+24) && (y <= topofpage+16*linecomp)){
    if((x>410)&&(x<480))B4Over=true;
    else B4Over=false;
    if((x>410)&&(x<480))B8Over=true;
    else B8Over=false;
    B1Over = false;
    B2Over = false;
    B3Over = false;
    B5Over = false;
    B6Over = false;
    B7Over = false;
  } 
  else if(( y > topofpage+16*linecomp) && (y < topofpage+16*linecomp+24)){
    if((x>10)&&(x<100))B5Over=true;
    else B5Over=false;
    if((x>150)&&(x<230))B6Over=true;
    else B6Over=false;
    if((x>270)&&(x<360))B7Over=true;
    else B7Over=false;
    if((x>410)&&(x<480))B8Over=true;
    else B8Over=false;
  } 
  else {
    B1Over = false;
    B2Over = false;
    B3Over = false;
    B4Over = false;
    B5Over = false;
    B6Over = false;
    B7Over = false;
    B8Over = false;
  }
}


public void keyPressed(){ //se uma tecla \u00e9 pressionada
  tecla = key;
  
  if(portChosen == false){
    
    if (key != 10) //Enter
      keyIn[keyIndex++] = key-48;
    else
    {
      COMPort = 0;
      for (i = 0; i < keyIndex; i++)
        COMPort = COMPort * 10 + keyIn[i];      
      println(COMPort);
      serPorta = new Serial(this, Serial.list()[COMPort], 9600, 'N', 8, 1.0f);
      portChosen = true;
      abortrun=false;
    }
  }
  else{
    switch(tecla){
      case 'R':
      case 'r':
        index=0;
        portChosen=false;
        enviarinst=false;
        abortrun=false;
        // Clear the buffer, or available() will still be > 0
        serPorta.clear();
        // Close the port
        serPorta.stop();
      break;
      case 'Q':
      case 'q':
        exit();
      break;
    }
  }
}

public void mousePressed()
{
  if(portChosen == true){
    if(B1Over == true){
        if(index<lines.length)index++;
    }
    if(B2Over == true){
        if(index>0)index--;
    }
    if(B3Over == true){
        enviarinst = true;
    }
    if(B4Over == true || B8Over==true){
        if(modoautomatico==1){
          modoautomatico=0;
          textAlign(CENTER);
          text("(modo manual)",width/2,topofpage+3*linecomp);
          textAlign(LEFT);
        }
        else {
          modoautomatico=1;
          index=0;
        }
     }
     if(B6Over == true){
        exit();
     }
     if(B7Over == true){
        chooseandloadFile();
        index=0;
        enviarinst = false;
     }
   }
}

public void chooseandloadFile(){
  // o codigo a seguir permite que o usuario escolha o arquivo que contem o codigo

  int returnVal = fc.showOpenDialog(this);
  if (returnVal == JFileChooser.APPROVE_OPTION) { 
    File file = fc.getSelectedFile();
    // see if it's an image 
    // (better to write a function and check for all supported extensions) 
    if (file.getName().endsWith(".anem16")) { // pensar numa extensao legal depois
      lines = loadStrings(file); 
    } else { 
      lines = loadStrings(file); // por enquanto vou deixar aceitando qualquer extensao de arquivo
    } 
  } else { 
    println("Open command cancelled by user."); 
  }
  // fim do abridor de arquivo
}

public void MsgdeErro(){
  background(135,165,133);
  textFont(fontA, 20);        
  textAlign(CENTER);
  fill(34,72,12);
  text("ERRO GRAVE!",width/2,topofpage+4*linecomp);
  fill(255);
  textFont(fontA, 12);
  text("Falha de comunica\u00e7\u00e3o com o Anem16, verifique o seguinte:",width/2,topofpage+6*linecomp);
  textFont(fontA, 14);
  text("1. Anem16 est\u00e1 no modo PROG?",width/2,topofpage+8.5f*linecomp);
  text("2. Cabo est\u00e1 bem conectado?",width/2,topofpage+10*linecomp);
  text("3. Porta serial foi escolhida corretamente?",width/2,topofpage+11.5f*linecomp);
  textFont(fontA, 12);
  text("Ap\u00f3s corrigido o problema, reinicie este programador teclando 'r'.",width/2,topofpage+14*linecomp);
  text("\u00c9 aconselh\u00e1vel tamb\u00e9m reiniciar o Anem16.",width/2,topofpage+15.5f*linecomp);
  textFont(fontA, 16);
  textAlign(LEFT);
  abortrun=true;
}
  static public void main(String args[]) {
    PApplet.main(new String[] { "--bgcolor=#F0F0F0", "AnemProgrammer" });
  }
}
