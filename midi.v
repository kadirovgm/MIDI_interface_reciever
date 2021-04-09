module midiReceive(
clck,
LED_out,
rst_n,
midi_data,
bitcount,
state_next,
MIDIbit,
displaytoggle_nxt
);
//необходимые входы и выходы
input clck;// вход таймер, счетчик
input rst_n;// пин reset НА ПЛАТЕ
input midi_data;// midi данные
output reg [7:0] LED_out; // LED светодиоды на плате

/// Все остальные переменные, помеченные выходными данными. Используются только для просмотра результата моделирования формы сигнала
wire EdgeDetected; // wire для приема выходного сигнала модуля Edge детектора 
wire [8:0]counterVal; // wire для считывания текущего значения счетчика
reg manual_reset;// Reg используется для сброса таймера независимо от кнопки сброса
reg [9:0] frame;// 10-битный регистр для хранения 1 байта, 1 стартового и 1 стоп - бита MIDI-кадра
reg [1:0] state;// 2-битный регистр для представления всех 3 состояний.: Edge detet(0), начальный бит recived (1),получение всех 3 midi-байтов(2) и выборка MIDI-бита каждые 32us(3)
output reg [5:0]bitcount;// подсчитывает, сколько битов мы уже отобрали 
reg displaytoggle=1'b0;// напоминание, когда мы должны показать заметку
output reg MIDIbit; // регистр для хранения значения, взятого из midi_data

// следующие регистры передадут обновленное значение в исходные регистры на следующем такте
reg [7:0] LED_out_nxt; 
output reg [1:0] state_next; 
output reg displaytoggle_nxt=1'b0;
reg [5:0]bitcount_nxt=6'b000000;
reg [9:0]frame_next;
reg manual_reset_next=1'b0;

up_counter count(counterVal,clck,rst_n,manual_reset);//создание экземпляров модулей
edge_detect fallingedge(midi_data,clck,EdgeDetected,rst_n);

always@(posedge clck)begin 

if (!rst_n) begin //установка всех регов на 0 вкл при нажатии кнопки resest
state<=2'b00;
bitcount<=6'b0;
manual_reset<=1'b1;
frame<=10'b000000000;
displaytoggle=1'b0;
LED_out<=8'b00000000;

end
else begin // обновление регистров с новыми значениями
state<=state_next;
bitcount<=bitcount_nxt;
manual_reset<=manual_reset_next;
frame[9:1]<=frame_next[8:0];
frame[0]<=MIDIbit;
displaytoggle<=displaytoggle_nxt;
LED_out<=displaytoggle_nxt? LED_out_nxt:8'b00000000;// Отображает текущее значение LED_out_nxt, если display имеет значение true

end  
end 

always@(*) begin 

case(state)

2'b00: begin // здесь детектируем edge
	if (EdgeDetected)begin // если детектируем edge, переходим в следующий такт
		state_next=2'b01;// переход в следующий такст (состояние)
		manual_reset_next=1'b1;// держим состояния для счетчика
		bitcount_nxt=6'b000000;// сохранение bitcount = 0
		MIDIbit=frame[0];// установка MIDIbit на последний бит в кадре
		end
	else begin
		state_next=2'b00;// поиск edge 
		manual_reset_next=1'b1; /// Продолжим удерживать сброс таймера
		bitcount_nxt=6'b000000;// сохранение bitcount = 0
		MIDIbit=frame[0];// установка MIDIbit на последний бит в кадре
		end
		end
2'b01: begin // начальное состояние бита. Будем ждать 16us для стартового бита, чтобы прибавитьь, а затем перейти к следующему состоянию
	if (counterVal==64) begin // если таймер отсчитывает до 16us перейдите в состояние выборки
		manual_reset_next=1'b1;// стоп таймер 
		state_next=2'b10;// переход в следующий такт (состояние)
		bitcount_nxt[5:0]=0;// сохранение bitcount = 0
		MIDIbit=midi_data;// начальный бит
	end
	else begin 
		manual_reset_next=1'b0; // таймер ++
		state_next=2'b01;// оставаться в текущем состоянии до тех пор, пока не пройдет 16us
		bitcount_nxt[5:0]=0;// сохранение bitcount = 0
		MIDIbit=frame[0];// установка MIDIbit на последний бит в кадре
	end
	
end		
2'b10: begin // Это состояние, в котором мы проверяем, были ли отобраны все 30 битов
	if (bitcount==6'b11110)begin //как только все биты будут отобраны, вернуться в состояние 0
	state_next=2'b00; // возвращение в состояние edge detect
	manual_reset_next=1;// стоп таймер
	bitcount_nxt[5:0]=0;// очистка таймера 
	MIDIbit=frame[0];// установка MIDIbit на последний бит в кадре
	
	end 
	else begin// если нам все еще нужны биты, 
	manual_reset_next=1'b0;// старт таймер
	state_next=2'b11;// переход в состояние выборки
	bitcount_nxt=bitcount;// сохраните текущее значение bitcount
	MIDIbit=frame[0];// установка MIDIbit на последний бит в кадре
	end
	end 		

2'b11: begin// Состояние выборки
	
if (counterVal==128)begin// Когда счетчик отсчитал 32us
	manual_reset_next=1'b1;// Reset таймер
	state_next=2'b10;// переход в предыдущее состояние
	bitcount_nxt=bitcount+1'b1; // инкремент количества битов 
	MIDIbit=midi_data;// sample бит из midi_data
	end
	else begin// иначе продолжить считать
	state_next=2'b11;// оставайться в текущем состоянии
	manual_reset_next=1'b0;// продолжить считать
	bitcount_nxt=bitcount;// сохраните текущее значение bitcount
	MIDIbit=frame[0];//  установка MIDIbit на последний бит в кадре
	end 
end 

default: begin 
state_next=2'b00; // переход в состояние 0
manual_reset_next=1'b1;// reset таймера 
MIDIbit=frame[0];//установка MIDIbit на последний бит в кадре
bitcount_nxt=6'b0; // установите bitcount равным 0
end
endcase
end

always @(*) begin 
if (counterVal==128)begin // когда мы выберем второй midi бит
frame_next<=frame;// установить на след кадр
end 
else begin// сдвиг по всем значениям
frame_next[0]<=frame[1];
frame_next[1]<=frame[2];
frame_next[2]<=frame[3];
frame_next[3]<=frame[4];
frame_next[4]<=frame[5];
frame_next[5]<=frame[6];
frame_next[6]<=frame[7];
frame_next[7]<=frame[8];
frame_next[8]<=frame[9];
frame_next[9]<=frame[9];
end 
end


always @(*) begin 
if (frame[8:1]==8'h90)begin// когда кадр равен 0x90
displaytoggle_nxt=1;// установить дисплей в положение 1
end 
else if (frame[8:1]==8'h80) begin // когда кадр равен 0x80
displaytoggle_nxt=0;// установить дисплей в положение 0
end 
else begin
displaytoggle_nxt=displaytoggle;// установить следующее значение на текущее
end
end

always @(*) begin 
if (bitcount==19)begin// если у нас есть законченная выборка второго MIDI байт
LED_out_nxt=frame[8:1];// соотв светодиод горит
end 
else begin
LED_out_nxt=LED_out; //  установить следующее значение на текущее
end
end

endmodule

// Саб модули 
module up_counter    (
  counter_out     ,  // Выходное значение счетчика
  clck     ,  // clock Input
  reset_bttn, // reset кнопка
  manual_reset // Сброс, не зависящий от таймера
  );

//----------Выходные порты--------------
     output reg [8:0] counter_out;
      reg [8:0] counter_nxt = 8'b0;
     //reg [8:0]out_next;
 //------------Входные порты--------------
      input reset_bttn,clck,manual_reset;
always @(*)begin 
	if (manual_reset)begin // если reset
counter_nxt=0;// установить таймер 0
end else begin 
counter_nxt=counter_out+1'b1;// инкремент тай
end 
end
 
 always @(posedge clck) begin 
 if (!reset_bttn) begin
     counter_out <= 8'b00000000 ;// сброс счетчика до 8 битного нулевого значения
 end else begin
    counter_out <= counter_nxt; //обновить счетчик к текущему значению
  end
  end
 
     
endmodule

module edge_detect	(// этот модуль определит, имеет ли линия MIDI-данных падающий край, указывая на то, что набор байтов является несогласованным
	input data,// Линия передачи данных midi
	input clk,// таймер input
	output reg Edge_detected,// вывод, который позволяет нам узнать, было ли обнаружено ребро (edge) 
	input rst_n// говорит о том, когда был установлен pin-код сброса
	);
	reg r1=0; 
	reg r2=0;
	reg Edge=0;
	
	always @(*) begin 
	if (r1==0 && r2==1)begin// если r1 и r2 имееют разные значенрия 
     Edge = 1; //Edge обнаружен
     end
     else begin 
		 Edge = 0;// Edge не обнаружен
		end
		end
		
	always @(posedge clk) begin
	if (!rst_n)begin // если нажать кнопку reset, регистры сброса будут равны 0
	r1 <= 0;
	r2 <= 0;
	Edge_detected<=0;
	end
	else begin // сдвиг 1 бита MIDI данных в r1 и r2
	  r1 <= data;
		r2 <= r1;
		Edge_detected<= Edge; 
	end
	end
	
endmodule
