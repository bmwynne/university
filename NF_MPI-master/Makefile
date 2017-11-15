simulate: stream.v
	python stream_cosim.py 
	/usr/local/bin/gtkwave -f testbench.vcd

stream.v: stream.py 
	python stream.py

clean:
	rm -f stream.v testbench.vcd* stream stream.pyc tb_stream.v