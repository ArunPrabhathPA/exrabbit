# ExRabbit

## DONT USE IT (WIP)

Usage of Exrabbit is very easy. 

* ####Add it as a dependency in mix.exs 

    { :rabbit, github: "atulpundhir/exrabbit" }

* ####Start application with server start. Update mix.exs

    def application do
      [ applications: [:rabbit],
      mod: { Coco, [] } ]
    end
    
* ####Start publisher or consumer using

    Rabbit.Server.start_publisher(:pub)  # :pub is an atom 
    Rabbit.Server.start_consumer(:con) # :con is an atom
    
  Rabbitmq connection information can be provided when starting publisher or consumer.
  
   Rabbit.Server.start_publisher(name, host, port, username, password, exchange, queue)
   Rabbit.Server.start_consumer(name, host, port, username, password, exchange, queue)
   
* ####Publish message to RabbitMq from your application 

    Rabbit.Server.publish(:pub, "hello") #:pub is the atom which we used to start publisher, hello is message

* ####Subscribe to receive message from RabbitMq in your gen_server

    Rabbit.Server.subscribe(self()) # self() will return the pid of gen_server

* ####Capture message received in your gen_server info function

    def websocket_info({:mq_msg, msg}, req, state) do
        :io.format("MESSAGE is ~p~n", [msg])
         {:ok, req, state}
    end
    
   
    

