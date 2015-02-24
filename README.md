# Modbus_Datalogger

Web based data logger.

This device currently communicates with any of the Grundfos E-Products through a ModBus interface. The Parallax Propeller receives the ModBus data and then does the decoding and unit conversion of the pump data. The Electric Imp (SD card shape) polls the Propeller for the new data and then adds its own data. The Electric Imp currently has 3 external thermistors as well as its on board light sensor. This data is packaged on the device and send on to the Electric Imp agent(https://electricimp.com/docs/api/agent/). The Imp agent then breaks up the data and sends the requested data to the Phant(http://phant.io/about/) data server. The server exists currently on a Amazon Web Services EC2 Micro Instance Linux server. In order to view the data a web page interface is used. This web page uses Google Charts to display data from the Phant server. Additional static information is displayed at the bottom of the web page, this information is grabbed from the Electric Imp agent.

Example web page : http://goo.gl/rrLkKA


![alt tag](https://github.com/Alavas/Modbus_Datalogger/blob/master/Photos/PrototypeBoard.jpg)