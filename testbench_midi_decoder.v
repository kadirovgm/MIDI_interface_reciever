module testbench_midi;

reg Midi_in;
reg Clock;
reg Reset_n;
wire [7:0] LED_output;

always begin
    #1 Clock = ~Clock;
    #10 Reset_n = 2b'00;
    #20 Midi_in = 2b'01;
    #30 Midi_in = 2b'01;
    #40 Midi_in = 2b'00;
    #50 Midi_in = 2b'00; 
    #60 Midi_in = 2b'01; 
    #70 Midi_in = 2b'01; 
    #80 Reset_n = 2b'00;
end

Midi_Decoder Midi_Decoder(Midi_in, Clock, Reset_n, LED_output);

endmodule
